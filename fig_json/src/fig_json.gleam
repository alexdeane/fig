import fig

pub fn add_json_file(
  builder: fig.ConfigBuilder,
  path: String,
  required: Bool,
) -> fig.ConfigBuilder {
  let json_loader = json_loader(path, required)
  ConfigBuilder([])
}

fn json_loader(path: String, required: Bool) -> fig.LoaderResult {
  todo
}
