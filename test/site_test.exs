defmodule SiteTest do
  use ExUnit.Case

  import PrexTest.Helpers

  doctest Prex.Site

  setup [:site_fixture]

  test "init site", %{test_site_path: path} do
    {:ok, site} = Prex.Site.init(path)
    assert length(site.resources) == 3

    index = Prex.Site.find(site, "index.html")

    assert index.procs == [Prex.Compilers.EEx, Prex.Compilers.Markdown, Prex.Compilers.WrapLayout]
    assert index.original_content =~ ~r[## This is Prex!]
    refute File.exists?(index.dest)
  end

  test "compile site", %{site: site} do
    index = Prex.Site.find(site, "index.html")

    assert index.original_content =~ ~r[## This is Prex!]

    {:ok, site} = Prex.Site.compile(site)

    index = Prex.Site.find(site, "index.html")

    assert index.procs == [Prex.Compilers.EEx, Prex.Compilers.Markdown, Prex.Compilers.WrapLayout]
    assert index.content =~ ~r[<h2>This is Prex!</h2>]
    assert index.content =~ ~r[<html>]
    assert index.content =~ ~r[<body>]
    refute File.exists?(index.dest)
  end

  test "generate resource", %{site: site} do
    index = Prex.Site.find(site, "index.html")
    dockerfile = Prex.Site.find(site, "resources/Dockerfile")

    assert index.procs == [Prex.Compilers.EEx, Prex.Compilers.Markdown, Prex.Compilers.WrapLayout]
    assert index.original_content =~ ~r[## This is Prex!]
    refute File.exists?(index.dest)

    assert dockerfile.procs == []
    assert dockerfile.original_content =~ ~r[# This is a Dockerfile]
    refute File.exists?(dockerfile.dest)

    {:ok, site} = Prex.Site.build(site)

    index = Prex.Site.find(site, "index.html")
    dockerfile = Prex.Site.find(site, "resources/Dockerfile")

    assert index.procs == [Prex.Compilers.EEx, Prex.Compilers.Markdown, Prex.Compilers.WrapLayout]
    assert index.original_content =~ ~r[## This is Prex!]
    assert File.exists?(index.dest)

    assert dockerfile.path == "resources/Dockerfile"
    assert dockerfile.procs == []
    assert dockerfile.content =~ ~r[# This is a Dockerfile]
    assert File.exists?(dockerfile.dest)
  end
end
