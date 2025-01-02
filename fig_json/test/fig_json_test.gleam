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

  let assert Ok("b") = fig.get_string(root_config, "a")
  let assert Error("b") = fig.get_string(root_config, "a")
}
