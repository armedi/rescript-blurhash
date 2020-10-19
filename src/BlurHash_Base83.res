open Belt

let characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~"

let decode = (str: string): int => {
  Js.String2.split(str, "")->Array.reduce(0, (value, char) => {
    value * 83 + Js.String2.indexOf(characters, char)
  })
}

let encode = (n: float, length: int): string => {
  Array.range(1, length)->Array.reduce("", (str, i) => {
    let index =
      (Js.Math.floor_float(n) /. Js.Math.pow_float(~base=83., ~exp=(length - i)->Int.toFloat))
      ->mod_float(83.)
      ->Js.Math.floor_int

    str ++ Js.String2.charAt(characters, index)
  })
}
