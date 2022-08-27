%{
  merged_conf_exs: "site.exs",
  after: fn ctx ->
    send(self(), :executed_after_callback)
    {:ok, ctx}
  end
}
