# StateChart

## Installation

This package can be installed by adding `modified_preorder_tree` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:modified_preorder_tree, "~> 0.1.1"}
  ]
end
```

<!--- StateChart moduledoc start -->

## What is MPTT (Modified Preorder Tree Traversal?)

- https://imrannazar.com/Modified-Preorder-Tree-Traversal
- https://www.atlantis-press.com/article/125938811.pdf
- https://gist.github.com/tmilos/f2f999b5839e2d42d751


## `MPTree` API

- Constructors
  - `from_node/1`
- Reducers
  - `insert/3`
  - `insert!/3`
  - `update_nodes/2`
  - `update_nodes/3`
- Converters
  - `fetch_children/2`
  - `fetch_children!/2`
  - `fetch_descendents/2`
  - `fetch_descendents!/2`
  - `fetch_parent/2`
  - `fetch_parent!/2`
  - `nodes/1`

<!--- StateChart moduledoc end -->

