import gleam/dynamic
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/string
import gleeunit

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let json_result = json.parse("foo.json", decode.dynamic)

  case json_result {
    Error(decode_error) -> decode_error |> string.inspect |> io.debug
    Ok(data) -> data |> dynamic.classify |> io.debug
  }
}
