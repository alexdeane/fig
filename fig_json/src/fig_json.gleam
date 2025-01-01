import fig
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
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

fn json_loader(path: String, required: Bool) -> fig.LoaderResult {
  let file_result = simplifile.read(path)
  case file_result {
    Ok(file) -> {
      let json_result = json.parse(file, decode.dynamic)
      case json_result {
        Error(decode_error) ->
          Error(fig.ParseError(
            "Error parsing JSON file "
            <> path
            <> ": "
            <> string.inspect(decode_error),
          ))
        Ok(data) -> Ok(config_from_dynamic(data))
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

fn config_from_dynamic(data: dynamic.Dynamic) -> fig.RootConfig {
  todo
}
