defmodule TableApp do
  @behaviour Ratatouille.App

  import Ratatouille.View

  def init(_context) do
    # Initialize some data
    %{
      rows: [
        ["Alice", "Engineer", "San Francisco"],
        ["Bob", "Designer", "New York"],
        ["Charlie", "Manager", "Chicago"]
      ]
    }
  end

  def update(model, _message) do
    # No updates for now
    model
  end

  def render(model) do
    view do
      panel title: "Employee Directory" do
        table do
          table_row do
            table_cell(content: "Name", attributes: [:bold])
            table_cell(content: "Position", attributes: [:bold])
            table_cell(content: "Location", attributes: [:bold])
            # table_cell(content: "Highlighted Text", color: :yellow, background: :blue)

          end

          Enum.map(model.rows, fn [name, position, location] ->
            table_row do
              table_cell(content: name)
              table_cell(content: position, color: :white, background: :red)
              table_cell(content: location, color: :yellow, background: :blue)
            end
          end)
        end
      end
    end
  end
end

Ratatouille.run(TableApp)

