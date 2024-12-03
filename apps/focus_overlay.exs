defmodule EnhancedFocusRingWithOverlayApp do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  # Key constants for pattern matching
  @space_key key(:space)
  @tab_key key(:tab)
  @backspace_keys [key(:backspace), key(:backspace2)]
  @up_key key(:arrow_up)
  @down_key key(:arrow_down)
  @enter_key key(:enter)
  @esc_key key(:esc)

  def init(_context) do
    %{
      focus_index: 0,
      # Add selection to the focusable fields
      focusable_fields: [:name, :email, :selection],
      inputs: %{
        name: "",
        email: "",
        selection: []
      },
      # Options for the selection field
      list_items: ["Option 1", "Option 2", "Option 3", "Option 4"],
      # Tracks the currently highlighted item in the list
      selected_index: 0,
      # Controls whether the overlay is visible
      show_overlay: false
    }
  end

  def update(model, {:event, %{key: key}}) when key == @tab_key do
    # Move focus to the next field
    next_index = rem(model.focus_index + 1, length(model.focusable_fields))
    %{model | focus_index: next_index, show_overlay: false}
  end

  def update(model, {:event, %{key: key}}) when key == @enter_key do
    current_field = Enum.at(model.focusable_fields, model.focus_index)

    cond do
      current_field == :selection and not model.show_overlay ->
        # Open the overlay when entering the selection field
        %{model | show_overlay: true}

      current_field == :selection and model.show_overlay ->
        # Toggle selection for the highlighted item in the overlay
        current_item = Enum.at(model.list_items, model.selected_index)
        current_selection = model.inputs.selection

        new_selection =
          if current_item in current_selection do
            List.delete(current_selection, current_item)
          else
            [current_item | current_selection]
          end

        updated_inputs = Map.put(model.inputs, :selection, new_selection)
        %{model | inputs: updated_inputs}

      true ->
        model
    end
  end

  def update(model, {:event, %{key: key}})
      when key in [@up_key, @down_key] and model.show_overlay do
    # Navigate the selection list in the overlay
    new_index =
      case key do
        @up_key -> max(0, model.selected_index - 1)
        @down_key -> min(length(model.list_items) - 1, model.selected_index + 1)
      end

    %{model | selected_index: new_index}
  end

  def update(model, {:event, %{key: key}}) when key == @esc_key do
    # Close the overlay when pressing ESC
    %{model | show_overlay: false}
  end

  def update(model, {:event, %{key: key}}) when key in @backspace_keys do
    # Handle backspace for regular text fields
    current_field = Enum.at(model.focusable_fields, model.focus_index)

    if current_field != :selection do
      updated_inputs =
        Map.update!(model.inputs, current_field, fn value ->
          String.slice(value, 0..-2//1)
        end)

      %{model | inputs: updated_inputs}
    else
      model
    end
  end

  def update(model, {:event, %{ch: ch, key: key}}) when ch > 0 or key == @space_key do
    # Handle typing for regular text fields
    current_field = Enum.at(model.focusable_fields, model.focus_index)

    if current_field != :selection do
      updated_inputs =
        Map.update!(model.inputs, current_field, fn value ->
          value <> <<ch::utf8>>
        end)

      %{model | inputs: updated_inputs}
    else
      model
    end
  end

  def update(model, _message), do: model

  def render(model) do
    focusable_fields = model.focusable_fields

    view do
      panel title: "Enhanced Focus Ring Form with Overlay" do
        label(content: "Press Tab to cycle focus. Enter to open selection. ESC to close overlay.")

        # Render regular text fields
        Enum.map(focusable_fields, fn
          :selection ->
            label(
              content: "Selection: #{Enum.join(model.inputs.selection, ", ")}",
              color:
                if(Enum.at(focusable_fields, model.focus_index) == :selection,
                  do: :green,
                  else: :white
                )
            )

          field ->
            label(
              content: "#{String.capitalize(to_string(field))}: #{model.inputs[field]}",
              color:
                if(Enum.at(focusable_fields, model.focus_index) == field,
                  do: :green,
                  else: :white
                )
            )
        end)
      end

      # Render overlay when visible
      if model.show_overlay do
        overlay do
          panel title: "Select Items (Press ESC to Close)", background: :red do
            Enum.map(model.list_items, fn item ->
              label(
                content: item,
                color:
                  cond do
                    item in model.inputs.selection -> :green
                    Enum.at(model.list_items, model.selected_index) == item -> :yellow
                    true -> :white
                  end
              )
            end)
          end
        end
      end
    end
  end
end

Ratatouille.run(EnhancedFocusRingWithOverlayApp)
