@react.component
let make = () => {
  let dataURL = switch BlurHash.toDataURL(
    ~hash="LEHV6nWB2yk8pyo0adR*.7kCMdnj",
    ~width=32,
    ~height=32,
  ) {
  | Belt.Result.Ok(data) => data
  | Belt.Result.Error(_) => ""
  }

  <img src=dataURL style={ReactDOM.Style.make(~width="269px", ~height="173px", ())} />
}
