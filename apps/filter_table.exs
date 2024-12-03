defmodule FilterTableApp do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  def init(_context) do
    %{
      rows: [
        ["Alice", "Engineer", "San Francisco"],
        ["Bob", "Designer", "New York"],
        ["Charlie", "Manager", "Chicago"]
      ],
      filter: "",
      filtered_rows: []
    }
    |> update_filtered_rows()
  end

  def update(model, {:event, %{key: key}}) when key in @delete_keys do
    # Handle delete/backspace for filtering
    new_filter = String.slice(model.filter, 0..-2//1)
    %{model | filter: new_filter} |> update_filtered_rows()
  end

  def update(model, {:event, %{ch: ch}}) when ch > 0 do
    # Append typed character to the filter
    new_filter = model.filter <> <<ch::utf8>>
    %{model | filter: new_filter} |> update_filtered_rows()
  end

  def update(model, _message), do: model

  def render(model) do
    view do
      panel title: "Employee Directory" do
        label(content: "Filter by Name: #{model.filter}")

        table do
          table_row do
            table_cell(content: "Name", attributes: [:bold])
            table_cell(content: "Position", attributes: [:bold])
            table_cell(content: "Location", attributes: [:bold])
          end

          Enum.map(model.filtered_rows, fn [name, position, location] ->
            table_row do
              table_cell(content: name)
              table_cell(content: position)
              table_cell(content: location)
            end
          end)
        end
      end
    end
  end

  defp update_filtered_rows(model) do
    filtered_rows =
      Enum.filter(model.rows, fn [name, _, _] ->
        String.contains?(String.downcase(name), String.downcase(model.filter))
      end)

    %{model | filtered_rows: filtered_rows}
  end
end

Ratatouille.run(FilterTableApp)

