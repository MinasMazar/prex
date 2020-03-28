defmodule Prex.Compilers.Markdown do
  def compile(_site, resource, _context) do
    case Earmark.as_html(resource.content) do
      {:ok, html, _errors} -> %{resource | content: html}
      {:error, _html, _errors} -> resource
    end
  end
end
