let decode: (
  ~hash: BlurHash_Common.blurhash,
  ~width: int,
  ~height: int,
  ~punch: int,
) => Belt.Result.t<BlurHash_Common.pixels, BlurHash_Common.error>

// for usage in JS bundle
let decode__JS: (
  ~hash: BlurHash_Common.blurhash,
  ~width: int,
  ~height: int,
  ~punch: int,
) => BlurHash_Common.pixels

let toDataURL: (
  ~hash: BlurHash_Common.blurhash,
  ~width: int,
  ~height: int,
) => Belt.Result.t<BlurHash_Common.dataURL, BlurHash_Common.error>

// for usage in JS bundle
let toDataURL__JS: (
  ~hash: BlurHash_Common.blurhash,
  ~width: int,
  ~height: int,
) => BlurHash_Common.dataURL
