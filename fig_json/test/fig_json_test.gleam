import fig
import fig_json
import gleam/io
import gleam/string
import gleeunit
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn e2e_json_test() {
  let assert Ok(root_config) =
    fig.new()
    |> fig_json.add("foo.json", True)
    |> fig.build()

  // Direct child
  let assert Ok("b") = fig.get_string(root_config, "a")

  // Section
  let assert Error(Nil) = fig.get_string(root_config, "b")

  // DNE
  let assert Error(Nil) = fig.get_string(root_config, "asdadas")

  // Nested
  let assert Ok("e") = fig.select_string(root_config, "c:d")
}

pub fn file_dne_test() {
  let assert Error(fig.NotFoundError(_)) =
    fig.new()
    |> fig_json.add("dne.json", True)
    |> fig.build()
}
