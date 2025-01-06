import envoy
import fig
import fig_env
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn vars_test() {
  envoy.set("FOO", "foo")
  envoy.set("bar", "bar")

  let assert Ok(config) =
    fig.new()
    |> fig_env.add()
    |> fig.build()

  let assert Ok("foo") = fig.get_string(config, "FOO")
  let assert Ok("bar") = fig.get_string(config, "bar")
}
