import fig
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic, dynamic}
import gleam/json
import gleam/list
import gleam/string
import simplifile.{Enoent}

pub fn add_json_file(
  builder: fig.ConfigBuilder,
  path: String,
  required: Bool,
) -> fig.ConfigBuilder {
  let json_loader = fn() { json_loader(path, required) }
  fig.add_loader(builder, json_loader)
}

pub fn json_loader(path: String, required: Bool) -> fig.LoaderResult {
  let file_result = simplifile.read(path)
  case file_result {
    Ok(text) -> {
      case decode_to_dict(text) {
        Ok(x) -> Ok(config_from_json(x))
        Error(e) ->
          Error(fig.ParseError(
            "Error parsing JSON file: " <> path <> " " <> string.inspect(e),
          ))
      }
    }
    Error(Enoent) -> {
      case required {
        True -> Error(fig.NotFoundError("File not found: " <> path))
        False -> Ok(fig.Empty)
      }
    }
    Error(file_error) ->
      Error(fig.UnknownError(
        "Error reading file: " <> path <> " " <> string.inspect(file_error),
      ))
  }
}

@external(erlang, "fig_json_ffi", "decode")
fn decode_to_dict(
  json: String,
) -> Result(Dict(Dynamic, Dynamic), json.DecodeError)

fn config_from_json(data: Dict(Dynamic, Dynamic)) -> fig.RootConfig {
  data |> do_config_from_json |> dict.from_list |> fig.RootConfig
}

fn do_config_from_json(
  data: Dict(Dynamic, Dynamic),
) -> List(#(String, fig.Config)) {
  data
  |> dict.to_list
  |> list.filter_map(fn(kvp) {
    let #(key, value) = kvp

    // Non-string keys are not supported 
    case dynamic.string(key) {
      Ok(key) -> {
        case value |> dynamic.dict(dynamic, dynamic) {
          Ok(dict) -> {
            let value =
              dict |> do_config_from_json |> dict.from_list |> fig.Section
            Ok(#(key, value))
          }
          Error(_) ->
            case dynamic.string(value) {
              Ok(value) -> {
                let value = value |> dynamic.from |> fig.Value
                Ok(#(key, value))
              }
              Error(_) -> Error(Nil)
            }
        }
      }
      Error(_) -> Error(Nil)
    }
  })
}
