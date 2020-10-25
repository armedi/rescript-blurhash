open Belt

type t = string
type pixels = Js.TypedArray2.Uint8ClampedArray.t
type dataURL = string
type error = ValidationError(string)
type floatTriplet = (float, float, float)

module Encode = {
  let bytesPerPixel = 4

  let multiplyBasisFunction = (
    ~pixels: pixels,
    ~width: int,
    ~height: int,
    basisFunction: (int, int) => float,
  ): floatTriplet => {
    let r = ref(0.)
    let g = ref(0.)
    let b = ref(0.)

    let bytesPerRow = width * bytesPerPixel

    for x in 0 to width - 1 {
      for y in 0 to height - 1 {
        let linearValue = xIndex =>
          basisFunction(x, y) *.
          pixels
          ->Js.TypedArray2.Uint8ClampedArray.unsafe_get(
            bytesPerPixel * x + xIndex + y * bytesPerRow,
          )
          ->BlurHash_Utils.sRGBToLinear

        r := r.contents +. linearValue(0)
        g := g.contents +. linearValue(1)
        b := b.contents +. linearValue(2)
      }
    }

    let scale = 1. /. (width * height)->Int.toFloat

    (r.contents *. scale, g.contents *. scale, b.contents *. scale)
  }

  let validateComponent = (pixels: pixels, component: int): Result.t<pixels, error> => {
    component >= 1 && component <= 9
      ? Result.Ok(pixels)
      : Result.Error(ValidationError("BlurHash must have between 1 and 9 components"))
  }

  let validateSize = (pixels: pixels, ~width: int, ~height: int): Result.t<pixels, error> => {
    width * height * 4 === Js.TypedArray2.Uint8ClampedArray.length(pixels)
      ? Result.Ok(pixels)
      : Result.Error(ValidationError("Width and height must match the pixels array"))
  }

  let encodeDC = ((r, g, b): floatTriplet): int => {
    open BlurHash_Utils
    linearTosRGB(r)->lsl(16) + linearTosRGB(g)->lsl(8) + linearTosRGB(b)
  }

  let encodeAC = ((r, g, b): floatTriplet, maximumValue: float): int => {
    let quantize = value => {
      (BlurHash_Utils.signPow(~value=value /. maximumValue, ~exp=0.5) *. 9. +. 9.5)
      ->Js.Math.floor_float
      ->Js.Math.min_float(18.)
      ->Js.Math.max_float(0.)
      ->Js.Math.floor_int
    }

    quantize(r) * 19 * 19 + quantize(g) * 19 + quantize(b)
  }

  let encode = (
    ~pixels: pixels,
    ~width: int,
    ~height: int,
    ~componentX: int,
    ~componentY: int,
  ): Result.t<t, error> => {
    pixels
    ->validateComponent(componentX)
    ->Result.flatMap(validateComponent(_, componentY))
    ->Result.flatMap(validateSize(_, ~width, ~height))
    ->Result.map(pixels => {
      let factors = []

      for y in 0 to componentY - 1 {
        for x in 0 to componentX - 1 {
          let normalisation = x == 0 && y == 0 ? 1. : 2.

          multiplyBasisFunction(~pixels, ~width, ~height, (i, j) =>
            normalisation *.
            Js.Math.cos(Js.Math._PI *. x->Int.toFloat *. i->Int.toFloat /. width->Int.toFloat) *.
            Js.Math.cos(Js.Math._PI *. y->Int.toFloat *. j->Int.toFloat /. height->Int.toFloat)
          )
          ->Js.Array.push(factors)
          ->ignore
        }
      }

      let dc = Array.getUnsafe(factors, 0)
      let ac = Array.sliceToEnd(factors, 1)

      let quantisedMaximumValue =
        ac
        ->Array.map(((r, g, b)) => Js.Math.maxMany_float([r, g, b]))
        ->Js.Math.maxMany_float
        ->(v => v *. 166. -. 0.5)
        ->Js.Math.floor_float
        ->Js.Math.min_float(82.)
        ->Js.Math.max_float(0.)

      let maximumValue = Array.length(ac) > 0 ? (quantisedMaximumValue +. 1.) /. 166. : 1.

      let numberOfComponentsHash =
        Int.toFloat(componentX - 1 + (componentY - 1) * 9)->BlurHash_Base83.encode(1)

      let maximumAcComponentValueHash =
        Array.length(ac) > 0
          ? BlurHash_Base83.encode(quantisedMaximumValue, 1)
          : BlurHash_Base83.encode(0., 1)

      let averageColorHash = dc->encodeDC->Int.toFloat->BlurHash_Base83.encode(4)

      Array.reduce(
        ac,
        numberOfComponentsHash ++ maximumAcComponentValueHash ++ averageColorHash,
        (finalHash, factor) => {
          finalHash ++ factor->encodeAC(maximumValue)->Int.toFloat->BlurHash_Base83.encode(2)
        },
      )
    })
  }
}

module Decode = {
  let validateMinLength = (hash: t, min: int): Result.t<t, error> => {
    Js.String2.length(hash) >= min
      ? Result.Ok(hash)
      : Result.Error(
          ValidationError(`The blurhash string must be at least ${min->Int.toString} characters`),
        )
  }

  let validateLength = (hash: t, n: int): Result.t<t, error> => {
    let length = Js.String2.length(hash)
    length == n
      ? Result.Ok(hash)
      : Result.Error(
          ValidationError(
            `Blurhash length mismatch: length is ${length->Int.toString} but it should be ${n->Int.toString}`,
          ),
        )
  }

  let decodeDC = (value: int): floatTriplet => (
    value->asr(16)->BlurHash_Utils.sRGBToLinear, // R
    value->asr(8)->land(255)->BlurHash_Utils.sRGBToLinear, // G
    value->land(255)->BlurHash_Utils.sRGBToLinear, // B
  )

  let decodeAC = (value: int, maximumValue: float): floatTriplet => {
    let decodeComponent = quant =>
      BlurHash_Utils.signPow(~value=(quant->Int.toFloat -. 9.) /. 9., ~exp=2.) *. maximumValue

    (
      (value / (19 * 19))->decodeComponent, // R
      (value / 19)->mod(19)->decodeComponent, // G
      value->mod(19)->decodeComponent, // B
    )
  }

  let decode = (~hash: t, ~width: int, ~height: int, ~punch: float): Result.t<pixels, error> => {
    let sizeFlag = hash->Js.String2.charAt(0)->BlurHash_Base83.decode
    let numY = (sizeFlag->Int.toFloat /. 9.)->Js.Math.floor + 1
    let numX = mod(sizeFlag, 9) + 1

    hash
    ->validateMinLength(6)
    ->Result.flatMap(validateLength(_, 4 + 2 * numX * numY))
    ->Result.map(validHash => {
      let quantisedMaximumValue = validHash->Js.String2.charAt(1)->BlurHash_Base83.decode
      let maximumValue = (quantisedMaximumValue + 1)->Int.toFloat /. 166.

      let colorsLength = numX * numY
      let colors = Array.make(colorsLength, (0., 0., 0.))

      for i in 0 to colorsLength - 1 {
        switch i {
        | 0 =>
          Array.setUnsafe(
            colors,
            0,
            validHash->Js.String2.substring(~from=2, ~to_=6)->BlurHash_Base83.decode->decodeDC,
          )
        | i =>
          Array.setUnsafe(
            colors,
            i,
            validHash
            ->Js.String2.substring(~from=4 + i * 2, ~to_=6 + i * 2)
            ->BlurHash_Base83.decode
            ->decodeAC(maximumValue *. punch),
          )
        }
      }

      let bytesPerRow = width * 4
      let pixels = Js.TypedArray2.Uint8ClampedArray.fromLength(bytesPerRow * height)

      for y in 0 to height - 1 {
        for x in 0 to width - 1 {
          let r = ref(0.)
          let g = ref(0.)
          let b = ref(0.)

          for j in 0 to numY - 1 {
            for i in 0 to numX - 1 {
              let basis =
                Js.Math.cos(
                  Js.Math._PI *. x->Int.toFloat *. i->Int.toFloat /. width->Int.toFloat,
                ) *.
                Js.Math.cos(Js.Math._PI *. y->Int.toFloat *. j->Int.toFloat /. height->Int.toFloat)

              switch colors[i + j * numX] {
              | Some((r', g', b')) =>
                r := r.contents +. r' *. basis
                g := g.contents +. g' *. basis
                b := b.contents +. b' *. basis
              | None => ()
              }
            }
          }

          let intR = BlurHash_Utils.linearTosRGB(r.contents)
          let intG = BlurHash_Utils.linearTosRGB(g.contents)
          let intB = BlurHash_Utils.linearTosRGB(b.contents)

          Array.forEach(
            [
              (4 * x + 0 + y * bytesPerRow, intR),
              (4 * x + 1 + y * bytesPerRow, intG),
              (4 * x + 2 + y * bytesPerRow, intB),
              (4 * x + 3 + y * bytesPerRow, 255),
            ],
            ((index, value)) => {
              Js.TypedArray2.Uint8ClampedArray.unsafe_set(pixels, index, value)
            },
          )
        }
      }

      pixels
    })
  }

  @bs.module("./js/externals")
  external pixelsToDataURL: (~pixels: pixels, ~width: int, ~height: int) => dataURL =
    "pixelsToDataURL"

  let toDataURL = (~hash: t, ~width: int, ~height: int): Result.t<dataURL, error> => {
    decode(~hash, ~width, ~height, ~punch=1.)->Result.map(pixels =>
      pixelsToDataURL(~pixels, ~width, ~height)
    )
  }
}

let decode = Decode.decode
let toDataURL = Decode.toDataURL
let encode = Encode.encode
