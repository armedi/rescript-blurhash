open Belt
open BlurHash_Common

type floatTriplet = (float, float, float)

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
        ->Js.TypedArray2.Uint8ClampedArray.unsafe_get(bytesPerPixel * x + xIndex + y * bytesPerRow)
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
): Result.t<blurhash, error> => {
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
