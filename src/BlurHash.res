type t = BlurHash_Common.blurhash
type pixels = BlurHash_Common.pixels
type dataURL = BlurHash_Common.dataURL
type error = BlurHash_Common.error

let encode = BlurHash_Encode.encode
let decode = BlurHash_Decode.decode
let toDataURL = BlurHash_Decode.toDataURL
