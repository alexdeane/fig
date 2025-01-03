import envoy
import fig
import gleam/dict
import gleam/dynamic
import gleam/io

pub fn add(builder: fig.ConfigBuilder) {
  let vars = envoy.all()
  fig.add_loader(builder, loader(vars))
}

fn loader(vars: dict.Dict(String, String)) -> fn() -> fig.LoaderResult {
  vars
  |> dict.map_values(fn(x) {
    let #(key, value) = x
    dynamic.from(value)
  })
  |> fig.from_dict
  |> Ok
}
