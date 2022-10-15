defmodule MPTree.Seeker do
  @moduledoc false
  # We ask many questions of the tree, such as:
  # - give me all a node's children
  # - give me all a node's ancestors
  # - give me all the nodes after a certain one
  #
  # The implementation of the answer always starts the same way:
  # 1. iterate through the list til we find the desired node
  # 2. keep some of the data
  # 3. filter some of the data
  # 4. return a list
  #
  # This modules provides a standard way of doing that.
  # It exposes a single `filter/3`
  # - nodes
  # - match_fn
  # - opts, which supports a single key for now: :keep, which must be a list of:
  #   - :ancestors
  #   - :matched (the node where match_fn succeeds)
  #   - :descendents
  #   - :tail (which overrides :descendents)

  use TypedStruct
  alias MPTree.Node

  typedstruct opaque: true, enforce: true do
    field :rev_non_matches, [Node.t()] | :drop
    field :matched, Node.t() | nil | :drop
    field :tail, [Node.t()]
    field :keep_matched?, boolean()
    field :keep_descendents?, boolean()
  end

  def filter(nodes, match_fn, opts \\ []) do
    keep = Keyword.get(opts, :keep, [:ancestors, :matched, :descendents])

    token = %__MODULE__{
      rev_non_matches: if(:ancestors in keep, do: [], else: :drop),
      matched: if(:matched in keep, do: nil, else: :drop),
      tail: nodes,
      keep_matched?: :matched in keep,
      keep_descendents?: :descendents in keep
    }

    case _seek_match(nodes, match_fn, token) do
      %__MODULE__{matched: nil} -> :error
      seeker -> {:ok, _to_list(seeker)}
    end
  end

  defp _seek_match([], _, token) do
    token
  end

  defp _seek_match([node | rest], match_fn, %__MODULE__{} = token) do
    case {match_fn.(node), token.rev_non_matches} do
      {true, _} ->
        %__MODULE__{token | matched: node, tail: rest}

      {false, :drop} ->
        _seek_match(rest, match_fn, token)

      {false, rev_non_matches} ->
        token = %__MODULE__{token | rev_non_matches: [node | rev_non_matches]}
        _seek_match(rest, match_fn, token)
    end
  end

  defp _to_list(%__MODULE__{rev_non_matches: ancestors, matched: matched, tail: tail} = token)
       when not is_nil(matched) do
    nodes =
      if token.keep_descendents? do
        descendent_count = Node.__count_descendents__(matched)
        Enum.take(tail, descendent_count)
      else
        []
      end

    nodes =
      if token.keep_matched? do
        [matched | nodes]
      else
        nodes
      end

    nodes =
      case ancestors do
        :drop ->
          nodes

        maybe_ancestors ->
          Enum.reduce(maybe_ancestors, nodes, fn maybe_ancestor, nodes ->
            if Node.__ancestor_and_descendent__?(maybe_ancestor, matched) do
              [maybe_ancestor | nodes]
            else
              nodes
            end
          end)
      end

    nodes
  end
end
