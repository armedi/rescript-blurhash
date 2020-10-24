// for Javascript bundle
// open lib/js/browser.js

open Belt
open BlurHash_Common

let encode = (
  ~pixels: pixels,
  ~width: int,
  ~height: int,
  ~componentX: int,
  ~componentY: int,
): blurhash => {
  switch BlurHash_Encode.encode(~pixels, ~width, ~height, ~componentX, ~componentY) {
  | Result.Ok(data) => data
  | Result.Error(ValidationError(message)) => Js.Exn.raiseError(message)
  }
}

let decode = (~hash: blurhash, ~width: int, ~height: int): pixels => {
  switch BlurHash_Decode.decode(~hash, ~width, ~height, ~punch=1.) {
  | Result.Ok(data) => data
  | Result.Error(ValidationError(message)) => Js.Exn.raiseError(message)
  }
}

let toDataURL = (~hash: blurhash, ~width: int, ~height: int): dataURL => {
  switch BlurHash_Decode.toDataURL(~hash, ~width, ~height) {
  | Result.Ok(data) => data
  | Result.Error(ValidationError(message)) => Js.Exn.raiseError(message)
  }
}
