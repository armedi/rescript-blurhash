type blurhash = string
type pixels = Js.TypedArray2.Uint8ClampedArray.t
type dataURL = string
type error = ValidationError(string)

let decode: (
  ~hash: blurhash,
  ~width: int,
  ~height: int,
  ~punch: int,
) => Belt.Result.t<pixels, error>

let toDataURL: (~hash: blurhash, ~width: int, ~height: int) => option<dataURL>
