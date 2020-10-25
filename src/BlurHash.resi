type t = string
type pixels = Js.TypedArray2.Uint8ClampedArray.t
type dataURL = string
type error = ValidationError(string)

let decode: (~hash: t, ~width: int, ~height: int, ~punch: float) => Belt.Result.t<pixels, error>

// This function can only run on browser environment
let toDataURL: (~hash: t, ~width: int, ~height: int) => Belt.Result.t<dataURL, error>

let encode: (
  ~pixels: pixels,
  ~width: int,
  ~height: int,
  ~componentX: int,
  ~componentY: int,
) => Belt.Result.t<t, error>
