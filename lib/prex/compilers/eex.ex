defmodule Prex.Compilers.EEx do
  require Logger

  def compile(_site, resource, context) do
    context = Map.to_list(context)

    content =
      resource.content
      |> inject_helpers()
      |> eval_eex(context)
    %{resource | content: content}
  end

  defp inject_helpers(content) do
    "<% import Prex.Helpers %>" <> content
  end

  defp eval_eex(content, context) do
    EEx.eval_string(content, assigns: context)
  end
end
