%{
  exs_config: "exs",
  merged_config: "exs",
  after: fn context ->
    send(self(), :executed_after_callback)
    {:ok, context}
  end
}
