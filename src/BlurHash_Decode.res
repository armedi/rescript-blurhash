open Belt
open BlurHash_Common

type floatTriplet = (float, float, float)

let validateMinLength = (hash: blurhash, min: int): Result.t<blurhash, error> => {
  Js.String2.length(hash) >= min
    ? Result.Ok(hash)
    : Result.Error(
        ValidationError(`The blurhash string must be at least ${min->Int.toString} characters`),
      )
}

let validateLength = (hash: blurhash, n: int): Result.t<blurhash, error> => {
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

let decode = (~hash: blurhash, ~width: int, ~height: int, ~punch: float): Result.t<
  pixels,
  error,
> => {
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
              Js.Math.cos(Js.Math._PI *. x->Int.toFloat *. i->Int.toFloat /. width->Int.toFloat) *.
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

@bs.module("./externals")
external pixelsToDataURL: (~pixels: pixels, ~width: int, ~height: int) => dataURL =
  "pixelsToDataURL"

let toDataURL = (~hash: blurhash, ~width: int, ~height: int): Result.t<dataURL, error> => {
  decode(~hash, ~width, ~height, ~punch=1.)->Result.map(pixels =>
    pixelsToDataURL(~pixels, ~width, ~height)
  )
}
