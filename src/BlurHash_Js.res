// for Javascript bundle
// open src/js/browser.js

open Belt

let encode = (
  ~pixels: BlurHash.pixels,
  ~width: int,
  ~height: int,
  ~componentX: int,
  ~componentY: int,
): BlurHash.t => {
  switch BlurHash.encode(~pixels, ~width, ~height, ~componentX, ~componentY) {
  | Result.Ok(data) => data
  | Result.Error(ValidationError(message)) => Js.Exn.raiseError(message)
  }
}

let decode = (~hash: BlurHash.t, ~width: int, ~height: int): BlurHash.pixels => {
  switch BlurHash.decode(~hash, ~width, ~height, ~punch=1.) {
  | Result.Ok(data) => data
  | Result.Error(ValidationError(message)) => Js.Exn.raiseError(message)
  }
}

let toDataURL = (~hash: BlurHash.t, ~width: int, ~height: int): BlurHash.dataURL => {
  switch BlurHash.toDataURL(~hash, ~width, ~height) {
  | Result.Ok(data) => data
  | Result.Error(ValidationError(message)) => Js.Exn.raiseError(message)
  }
}
