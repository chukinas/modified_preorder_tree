locals_without_parens = [
  statechart: 1,
  statechart: 2,
  state: 1,
  state: 2,
  on: 1,
  subchart: 2
]

[
  import_deps: [:typed_struct, :stream_data],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
