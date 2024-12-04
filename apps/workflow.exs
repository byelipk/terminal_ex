defmodule WorkflowDemo do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  @enter_key key(:enter)
  @esc_key key(:esc)
  @up_key key(:arrow_up)
  @down_key key(:arrow_down)
  @left_key key(:arrow_left)
  @right_key key(:arrow_right)

  def init(_context) do
    %{
      stage: :topic_selection,
      topic_view: %{
        options: ["Topic 1", "Topic 2", "Topic 3"],
        # Indicates navigation focus
        focus_index: 0,
        # Indicates selection made
        selected_index: nil
      },
      main_view: %{
        focus: %{
          # Focused stream index
          stream: nil,
          # Focused schema index
          schema: nil,
          # Focused item index
          item: nil
        },
        selection: %{
          # Selected stream
          stream: nil,
          # Selected schema
          schema: nil,
          # Selected item
          item: nil
        },
        streams: ["Stream 1", "Stream 2", "Stream 3"],
        schemas: %{
          "Stream 1" => ["Schema 1.1", "Schema 1.2"],
          "Stream 2" => ["Schema 2.1", "Schema 2.2"],
          "Stream 3" => ["Schema 3.1", "Schema 3.2"]
        },
        items: %{
          "Schema 1.1" => ["Item 1.1.1", "Item 1.1.2"],
          "Schema 1.2" => ["Item 1.2.1", "Item 1.2.2"],
          "Schema 2.1" => ["Item 2.1.1", "Item 2.1.2"],
          "Schema 2.2" => ["Item 2.2.1", "Item 2.2.2"]
        }
      }
    }
  end

  def update(model, {:event, %{key: key}}) when model.stage == :topic_selection do
    topic_view = model.topic_view

    case key do
      @up_key ->
        put_in(model.topic_view.focus_index, max(0, topic_view.focus_index - 1))

      @down_key ->
        put_in(
          model.topic_view.focus_index,
          min(length(topic_view.options) - 1, topic_view.focus_index + 1)
        )

      @enter_key ->
        selected = Enum.at(topic_view.options, topic_view.focus_index)

        put_in(model, [:stage], :main_view)
        |> put_in([:topic_view], %{
          topic_view
          | selected_index: topic_view.focus_index
        })

      _ ->
        model
    end
  end

  def update(model, {:event, %{key: key}}) when model.stage == :main_view do
    case key do
      @up_key ->
        navigate_main_view(model, :up)

      @down_key ->
        navigate_main_view(model, :down)

      @enter_key ->
        select_main_menu(model)

      @right_key ->
        select_main_menu(model)

      @left_key ->
        deselect_main_menu(model)

      @esc_key ->
        # Return to the topic selection topic_view
        %{model | stage: :topic_selection}

      _ ->
        model
    end
  end

  def update(model, _message), do: model

  def render(%{stage: :topic_selection, topic_view: topic_view}) do
    view do
      overlay(padding: 10) do
        panel title: "Select a Topic" do
          Enum.map(topic_view.options, fn option ->
            label(
              content: option,
              color: assign_color(topic_view.options, option, topic_view.focus_index)
            )
          end)
        end
      end
    end
  end

  def render(%{stage: :main_view, main_view: main_view} = model) do
    view do
      row do
        # Column 1: Streams
        column(size: assign_column_size(model, :streams)) do
          panel title: "Streams" do
            Enum.map(main_view.streams, fn stream ->
              label(
                content: stream,
                color: assign_color(main_view.streams, stream, main_view.focus.stream)
              )
            end)
          end
        end

        # Column 2: Schemas
        if main_view.selection.stream != nil do
          selected_stream = Enum.at(main_view.streams, main_view.selection.stream)
          schemas = Map.get(main_view.schemas, selected_stream, [])

          column(size: assign_column_size(model, :schemas)) do
            panel title: "Schemas" do
              Enum.map(schemas, fn schema ->
                label(
                  content: schema,
                  color: assign_color(schemas, schema, main_view.focus.schema)
                )
              end)
            end
          end
        else
          column(size: assign_column_size(model, :schemas)) do
            panel title: "Schemas" do
              label(content: "Select a stream to view schemas")
            end
          end
        end

        # Column 3: Items
        if main_view.selection.schema != nil do
          selected_stream = Enum.at(main_view.streams, main_view.selection.stream)

          selected_schema =
            Enum.at(main_view.schemas[selected_stream], main_view.selection.schema)

          items = Map.get(main_view.items, selected_schema, [])

          column(size: assign_column_size(model, :items)) do
            panel title: "Items" do
              Enum.map(items, fn item ->
                label(
                  content: item,
                  color: assign_color(items, item, main_view.focus.item)
                )
              end)
            end
          end
        else
          column(size: assign_column_size(model, :items)) do
            panel title: "Items" do
              label(content: "Select a schema to view items")
            end
          end
        end
      end
    end
  end

  defp deselect_main_menu(%{stage: :main_view} = model) do
    # Here we want to deselect the current selection
    current =
      {model.main_view.selection.stream, model.main_view.selection.schema,
       model.main_view.selection.item}

    case current do
      {nil, nil, nil} ->
        put_in(model, [:stage], :topic_selection)

      {_, nil, nil} ->
        put_in(model, [:main_view, :selection, :stream], nil)

      {_, _, nil} ->
        put_in(model, [:main_view, :selection, :schema], nil)

      _ ->
        put_in(model, [:main_view, :selection, :item], nil)
    end
  end

  defp select_main_menu(%{stage: :main_view} = model) do
    # Here the challenge is to know which list to select from
    case {model.main_view.selection.stream, model.main_view.selection.schema} do
      {nil, _} ->
        select_focused_in_list(model, :streams, :stream)

      {_, nil} ->
        select_focused_in_list(model, :schemas, :schema)

      _ ->
        select_focused_in_list(model, :items, :item)
    end
  end

  defp navigate_main_view(model, direction) do
    case {model.main_view.selection.stream, model.main_view.selection.schema} do
      {nil, _} ->
        move_focus_in_list(model, :streams, direction)

      {_, nil} ->
        move_focus_in_list(model, :schemas, direction)

      _ ->
        move_focus_in_list(model, :items, direction)
    end
  end

  defp select_focused_in_list(model, field, selection_key) do
    field_data = get_field_data(model, field)

    # Default to -1 if result is nil so the math to get the new index works out correctly
    {current_index, _} = get_current_main_view_focus_index(model, field)

    selected_index = max(0, current_index)

    put_in(model, [:main_view, :selection, selection_key], selected_index)
  end

  defp move_focus_in_list(model, field, direction) do
    field_data = get_field_data(model, field)

    # Default to -1 if result is nil so the math to get the new index works out correctly
    {current_index, focused_field_index} = get_current_main_view_focus_index(model, field)

    new_index =
      case direction do
        :up ->
          max(0, current_index - 1)

        :down ->
          min(length(field_data) - 1, current_index + 1)
      end

    put_in(model, [:main_view] ++ focused_field_index, new_index)
  end

  defp get_current_main_view_focus_index(model, field) do
    focused_field_index =
      case field do
        :streams -> [:focus, :stream]
        :schemas -> [:focus, :schema]
        :items -> [:focus, :item]
      end

    # Default to -1 if result is nil so the math to get the new index works out correctly
    current_index = get_in(model.main_view, focused_field_index) || -1

    {current_index, focused_field_index}
  end

  defp get_field_data(model, :streams) do
    model.main_view.streams
  end

  defp get_field_data(model, :schemas) do
    selected_stream =
      Enum.at(model.main_view.streams, model.main_view.selection.stream)

    Map.get(model.main_view.schemas, selected_stream, [])
  end

  defp get_field_data(model, :items) do
    selected_stream =
      Enum.at(model.main_view.streams, model.main_view.selection.stream)

    selected_schema =
      Enum.at(
        model.main_view.schemas[selected_stream],
        model.main_view.selection.schema
      )

    Map.get(model.main_view.items, selected_schema, [])
  end

  defp assign_color(_, nil, nil), do: :white

  defp assign_color(_, _, nil), do: :white

  defp assign_color(_, nil, _), do: :white

  defp assign_color([], _, _), do: :white

  defp assign_color(options, option, selected_index) do
    case option == Enum.at(options, selected_index) do
      true -> :green
      false -> :white
    end
  end

  defp assign_column_size(model, :streams) do
    4
  end

  defp assign_column_size(model, :schemas) do
    4
  end

  defp assign_column_size(model, :items) do
    4
  end
end

Ratatouille.run(WorkflowDemo)
