# fig
Configuration library for Gleam

## Usage

```gleam
import fig
import fig_json
import fig_env

pub fn main() {
  let config =
    fig.new()
    |> fig_json.add_json("settings.json")
    |> fig_env.add_env_vars()
    |> fig.build()
}
```