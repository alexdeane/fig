import fig
import gleam/string
import jelly
import simplifile.{Enoent}

pub fn add(
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
    Ok(text) -> {
      case jelly.parse_dict(text) {
        Ok(x) -> Ok(fig.from_dict(x))
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
