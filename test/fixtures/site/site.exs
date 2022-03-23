%{
  merged_conf_exs: "site.exs",
  after: fn _ctx ->
    send(self(), :executed_after_callback)
  end
}
