import gleam/otp/task

pub type ConfigLoader =
  fn() -> LoaderResult

pub type LoaderResult =
  Result(Config, LoaderError)

// TODO: hold info about the config so we can make fns to pull it out
pub type Config {
  Empty
}

pub type LoaderError {
  NotFoundError(message: String)
  ParseError(message: String)
  UnknownError(message: String)
  AggregateError(errors: List(LoaderError))
}

pub opaque type ConfigBuilder {
  Empty
  ConfigBuilder(loaders: ConfigLoader)
}

/// Start a new, empty config 
pub fn new() -> ConfigBuilder {
  Empty
}

/// Build the config
pub fn build(builder: ConfigBuilder) -> Result(Config, AggregateError) {
  case builder {
    Empty -> Empty
    ConfigBuilder(loaders) -> {
      let tasks =
        loaders
        |> list.map(fn(loader) { task.async(loader) })

      let results = task.try_await_all(tasks, 30)
      // todo: configure
    }
  }
}
