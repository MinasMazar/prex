defmodule Prex.Compilers.WrapLayout do
  import EEx, only: [eval_string: 2]

  def compile(site, resource, context) do
    layout_file = Path.join(site.root, site.layout)
    {:ok, layout_content} = File.read(layout_file)
    context = Map.merge(context, %{site: site, content: resource.content})
    content = eval_string(layout_content, Map.to_list(context))
    %{resource | content: content}
  end
end
