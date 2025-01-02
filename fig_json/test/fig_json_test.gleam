import fig
import fig_json
import gleam/io
import gleam/string
import gleeunit
import simplifile

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  // {
  //    "a": "b",
  //    "c": {
  //        "d": "e",
  //        "f": false
  //    }
  // }
  let assert Ok(_) =
    simplifile.write(
      "foo.json",
      "{     \"a\": \"b\",     \"c\": {         \"d\": \"e\",         \"f\": false     } }",
    )

  let assert Ok(root_config) = fig_json.json_loader("foo.json", True)

  // Direct child
  let assert Ok("b") = fig.get_string(root_config, "a")

  // Section
  let assert Error(Nil) = fig.get_string(root_config, "b")

  // DNE
  let assert Error(Nil) = fig.get_string(root_config, "asdadas")

  // Nested
  let assert Ok("e") = fig.select_string(root_config, "c:d")
}
