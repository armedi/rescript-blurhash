let encode: (
  ~pixels: BlurHash_Common.pixels,
  ~width: int,
  ~height: int,
  ~componentX: int,
  ~componentY: int,
) => Belt.Result.t<BlurHash_Common.blurhash, BlurHash_Common.error>
