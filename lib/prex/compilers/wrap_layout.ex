defmodule Prex.Compilers.WrapLayout do
  import EEx, only: [eval_string: 2]

  @fallback_layout ~s"""
  <html>
    <head></head>
    <body>
      <%= content %>"
    </body
  <html>
  """

  def compile(site, resource, context) do
    layout_file = Path.join(site.root, site.layout)
    {site, layout_content} = read_layout(site, layout_file)
    context = Map.merge(context, %{site: site, content: resource.content})
    content = eval_string(layout_content, Map.to_list(context))
    %{resource | content: content}
  end

  defp read_layout(site, file) do
    case File.read(file) do
      {:ok, layout_content} -> {site, layout_content}
      {:error, reason} -> {Map.put(site, :errors, [reason]), @fallback_layout}
    end
  end
end
