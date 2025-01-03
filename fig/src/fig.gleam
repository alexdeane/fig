import gleam/dict
import gleam/dynamic.{type Dynamic, dynamic}
import gleam/list
import gleam/otp/task
import gleam/result
import gleam/string

pub type ConfigLoader =
  fn() -> LoaderResult

pub type LoaderResult =
  Result(RootConfig, LoaderError)

pub type RootConfig {
  Empty
  RootConfig(config: dict.Dict(String, Config))
}

pub type Config {
  Value(Dynamic)
  Section(data: dict.Dict(String, Config))
}

pub type LoaderError {
  NotFoundError(message: String)
  ParseError(message: String)
  UnknownError(message: String)
  AggregateError(errors: List(LoaderError))
}

pub opaque type ConfigBuilder {
  ConfigBuilder(loaders: List(ConfigLoader))
}

/// Start a new, empty config 
pub fn new() -> ConfigBuilder {
  ConfigBuilder([])
}

/// Build the config
pub fn build(builder: ConfigBuilder) -> LoaderResult {
  let tasks =
    builder.loaders
    |> list.map(task.async)

  let results =
    task.try_await_all(tasks, 30)
    |> flatten_map(fn(error) {
      UnknownError("Error loading configuration:" <> string.inspect(error))
    })

  // todo: configure timeout
  let #(successes, errors) = result.partition(results)

  case errors {
    [] -> successes |> fold |> Ok
    _ -> errors |> AggregateError |> Error
  }
}

fn flatten_map(
  results: List(Result(Result(a, b), c)),
  map: fn(c) -> b,
) -> List(Result(a, b)) {
  results
  |> list.map(fn(r) {
    case r {
      Ok(r) -> Ok(r)
      Error(e) -> Error(map(e))
    }
    |> result.flatten
  })
}

pub fn fold(configs: List(RootConfig)) -> RootConfig {
  case list.reduce(configs, merge) {
    Ok(config) -> config
    Error(Nil) -> Empty
  }
}

pub fn merge(a: RootConfig, b: RootConfig) -> RootConfig {
  case a, b {
    RootConfig(a), RootConfig(b) -> RootConfig(dict.merge(a, b))
    RootConfig(a), Empty -> RootConfig(a)
    Empty, RootConfig(b) -> RootConfig(b)
    Empty, Empty -> Empty
  }
}

pub fn add_loader(builder: ConfigBuilder, loader: ConfigLoader) -> ConfigBuilder {
  ConfigBuilder([loader, ..builder.loaders])
}

/// Get a top-level string cfg from a RootConfig
/// 
pub fn get_string(config: RootConfig, key: String) -> Result(String, Nil) {
  case config {
    RootConfig(data) -> {
      case dict.get(data, key) {
        Ok(Value(value)) ->
          case dynamic.string(value) {
            Ok(string) -> Ok(string)
            Error(_) -> Error(Nil)
          }
        _ -> Error(Nil)
      }
    }
    Empty -> Error(Nil)
  }
}

/// Get a top-level string cfg from a Config section
/// 
pub fn get_section_string(config: Config, key: String) -> Result(String, Nil) {
  case config {
    Section(data) -> {
      case dict.get(data, key) {
        Ok(Value(value)) ->
          case dynamic.string(value) {
            Ok(string) -> Ok(string)
            _ -> Error(Nil)
          }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Select a nested string value from a nested Config section,
/// using a path expression (e.g. "a:b:c")
/// 
pub fn select_string(config: RootConfig, path: String) -> Result(String, Nil) {
  case config {
    RootConfig(data) -> {
      let keys = string.split(path, ":")
      select_string_r(Section(data), keys)
    }
    Empty -> Error(Nil)
  }
}

/// Select a nested string value from a nested Config section,
/// using a path expression (e.g. "a:b:c")
/// 
pub fn select_section_string(
  config: Config,
  path: String,
) -> Result(String, Nil) {
  let keys = string.split(path, ":")
  select_string_r(config, keys)
}

fn select_string_r(config: Config, keys: List(String)) -> Result(String, Nil) {
  case config {
    Section(data) -> {
      case keys {
        [] -> Error(Nil)
        [key] -> {
          case dict.get(data, key) {
            Ok(Value(value)) ->
              case dynamic.string(value) {
                Ok(string) -> Ok(string)
                _ -> Error(Nil)
              }
            _ -> Error(Nil)
          }
        }
        [key, ..rest] -> {
          case dict.get(data, key) {
            Ok(Section(data)) -> select_string_r(Section(data), rest)
            _ -> Error(Nil)
          }
        }
      }
    }
    Value(value) ->
      case dynamic.string(value) {
        Ok(string) -> Ok(string)
        _ -> Error(Nil)
      }
  }
}

pub fn from_dict(data: dict.Dict(Dynamic, Dynamic)) -> RootConfig {
  data |> do_from_dict |> dict.from_list |> RootConfig
}

fn do_from_dict(data: dict.Dict(Dynamic, Dynamic)) -> List(#(String, Config)) {
  data
  |> dict.to_list
  |> list.filter_map(fn(kvp) {
    let #(key, value) = kvp

    // Non-string keys are not supported 
    case dynamic.string(key) {
      Ok(key) -> {
        case value |> dynamic.dict(dynamic, dynamic) {
          Ok(dict) -> {
            let value = dict |> do_from_dict |> dict.from_list |> Section
            Ok(#(key, value))
          }
          Error(_) ->
            case dynamic.string(value) {
              Ok(value) -> {
                let value = value |> dynamic.from |> Value
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
