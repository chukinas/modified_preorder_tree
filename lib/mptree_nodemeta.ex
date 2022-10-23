defmodule MPTree.NodeMeta do
  @moduledoc false

  use TypedStruct

  @type id :: pos_integer()
  @type lft :: non_neg_integer()
  @type rgt :: pos_integer()

  @starting_node_id 1
  @starting_lft 0

  typedstruct enforce: true do
    field :id, id(), default: @starting_node_id
    field :lft, lft(), default: @starting_lft
    field :rgt, rgt(), default: 1 + @starting_lft
  end

  @spec new :: t()
  def new, do: %__MODULE__{}

  #####################################
  # HELPERS

  def __starting_node_id__, do: @starting_node_id
  def __starting_lft__, do: @starting_lft

  defimpl Inspect do
    def inspect(m, _opts) do
      "#NodeMeta<#{m.id}, {#{m.lft}, #{m.rgt}}>"
    end
  end
end
