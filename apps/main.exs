defmodule Main do
  @behaviour Ratatouille.App

  import Ratatouille.View

  def start(_type, _args) do
    { :ok, _ } = Application.ensure_all_started(:terminal_ex)

    Ratatouille.run(__MODULE__)
  end

  def init(_context), do: %{message: "Hello, World!"}
  def update(model, _message), do: model
  def render(model) do
    view do
      label(content: model.message)
    end
  end
end

Ratatouille.run(Main)
