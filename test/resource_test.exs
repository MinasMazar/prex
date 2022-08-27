defmodule ResourceTest do
  use ExUnit.Case
  import PrexTest.Helpers
  doctest Prex.Resource
  setup [:site_fixture]

  test "compile resource with markdown", %{site: site} do
    resource = %Prex.Resource{
      original_content: "## Prex!",
      procs: [Prex.Compilers.Markdown],
    }

    {:ok, resource} = Prex.Resource.compile(site, resource)

    assert resource.content == "<h2>Prex!</h2>\n"
  end

  test "compile resource with eex", %{site: site} do
    resource = %Prex.Resource{
      original_content: """
      This is <%= @resource.data.title %>!
      """,
      procs: [Prex.Compilers.EEx],
      data: %{title: "My post"}
    }

    {:ok, resource} = Prex.Resource.compile(site, resource)

    assert resource.content == "This is My post!\n"
  end

  test "compile resource with layout", %{site: site} do
    resource = %Prex.Resource{
      original_content: """
      This is My post!
      """,
      procs: [Prex.Compilers.WrapLayout],
      data: %{title: "My post"}
    }

    {:ok, resource} = Prex.Resource.compile(site, resource)

    assert resource.content =~ "This is My post!\n"
    assert resource.content =~ "<html>"
    assert resource.content =~ "<head>"
    assert resource.content =~ "<body>"
  end
end
