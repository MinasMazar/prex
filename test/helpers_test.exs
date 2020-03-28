defmodule HelpersTest do
  use ExUnit.Case

  import PrexTest.Helpers

  setup :site_fixture

  test "Helpers.find", %{site: site} do
    res = Prex.Helpers.find(site, "posts/2020-11-11-first-post.html")
    assert res.path == "posts/2020-11-11-first-post.html"

    res = Prex.Helpers.find(site, "first-post")
    assert res == nil

    res = Prex.Helpers.find(site, pattern: "first-post")
    assert res.path == "posts/2020-11-11-first-post.html"
  end
end
