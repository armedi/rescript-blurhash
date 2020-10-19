open Belt

let sRGBToLinear = (value: int): float => {
  let v = Int.toFloat(value) /. 255.
  v <= 0.04045 ? v /. 12.92 : Js.Math.pow_float(~base=(v +. 0.055) /. 1.055, ~exp=2.4)
}

let linearTosRGB = (value: float): int => {
  let v = value->Js.Math.min_float(1.)->Js.Math.max_float(0.)
  v <= 0.0031308
    ? (v *. 12.92 *. 255. +. 0.5)->Js.Math.round->Float.toInt
    : ((1.055 *. Js.Math.pow_float(~base=v, ~exp=1. /. 2.4) -. 0.055) *. 255. +. 0.5)
      ->Js.Math.round
      ->Float.toInt
}

let signPow = (~value: float, ~exp: float): float => {
  Js.Math.sign_float(value) *. Js.Math.pow_float(~base=Js.Math.abs_float(value), ~exp)
}
