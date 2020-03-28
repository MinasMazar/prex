defmodule Prex.Compilers.EEx do
  def compile(_site, resource, context) do
    with context <- Map.to_list(context),
         content <- EEx.eval_string(resource.content, context) do
      %{resource | content: content}
    end
  end
end
