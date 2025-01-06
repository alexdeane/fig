import envoy
import fig
import gleam/dict
import gleam/dynamic
import gleam/list

pub fn add(builder: fig.ConfigBuilder) {
  let vars = envoy.all()
  fig.add_loader(builder, fn() { loader(vars) })
}

fn loader(vars: dict.Dict(String, String)) -> fig.LoaderResult {
  vars
  |> dict.keys
  |> list.map(fn(key) {
    let assert Ok(value) = dict.get(vars, key)
    #(dynamic.from(key), dynamic.from(value))
  })
  |> dict.from_list
  |> fig.from_dict
  |> Ok
}
