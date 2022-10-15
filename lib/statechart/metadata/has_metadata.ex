defprotocol Statechart.Metadata.HasMetadata do
  @moduledoc false

  alias Statechart.Metadata

  @spec fetch(t) :: {:ok, Metadata.t()} | {:error, :missing_metadata}
  def fetch(has_metadata)
end
