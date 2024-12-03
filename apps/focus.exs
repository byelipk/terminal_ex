defmodule FocusRingApp do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  # Define key constants for pattern matching
  @tab_key key(:tab)
  @backspace_keys [key(:backspace), key(:backspace2)]

  def init(_context) do
    %{
      focus_index: 0,
      # Define the order
      focusable_fields: [:name, :email, :phone],
      inputs: %{
        name: "",
        email: "",
        phone: ""
      }
    }
  end

  def update(model, {:event, %{key: key}}) when key == @tab_key do
    # Move focus to the next field
    next_index = rem(model.focus_index + 1, length(model.focusable_fields))
    %{model | focus_index: next_index}
  end

  def update(model, {:event, %{key: key}}) when key in @backspace_keys do
    # Remove the last character from the currently focused field
    current_field = Enum.at(model.focusable_fields, model.focus_index)

    updated_inputs =
      Map.update!(model.inputs, current_field, fn value ->
        String.slice(value, 0..-2//1)
      end)

    %{model | inputs: updated_inputs}
  end

  def update(model, {:event, %{ch: ch}}) when ch > 0 do
    # Append typed character to the currently focused field
    current_field = Enum.at(model.focusable_fields, model.focus_index)

    updated_inputs =
      Map.update!(model.inputs, current_field, fn value ->
        value <> <<ch::utf8>>
      end)

    %{model | inputs: updated_inputs}
  end

  def update(model, _message), do: model

  def render(model) do
    focusable_fields = model.focusable_fields

    view do
      panel title: "Focus Ring Form" do
        label(content: "Press Tab to cycle focus. Backspace to delete.")

        Enum.map(focusable_fields, fn field ->
          label(
            content: "#{String.capitalize(to_string(field))}: #{model.inputs[field]}",
            color:
              if(Enum.at(focusable_fields, model.focus_index) == field, do: :green, else: :white)
          )
        end)
      end
    end
  end
end

Ratatouille.run(FocusRingApp)
