let decode: (
  ~hash: BlurHash_Common.blurhash,
  ~width: int,
  ~height: int,
  ~punch: int,
) => Belt.Result.t<BlurHash_Common.pixels, BlurHash_Common.error>

let toDataURL: (
  ~hash: BlurHash_Common.blurhash,
  ~width: int,
  ~height: int,
) => Belt.Result.t<BlurHash_Common.dataURL, BlurHash_Common.error>
