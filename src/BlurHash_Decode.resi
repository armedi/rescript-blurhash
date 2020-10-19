type pixels = Js.TypedArray2.Uint8ClampedArray.t
let decode: (~blurhash: string, ~width: int, ~height: int, ~punch: int) => pixels
