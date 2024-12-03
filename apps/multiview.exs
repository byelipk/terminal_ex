defmodule MultiViewApp do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  # Define keys for tabs
  @page_keys [key(:f1), key(:f2), key(:f3)]
  @page_vals [:tab1, :tab2, :tab3]
  @pages Enum.zip(@page_keys, @page_vals) |> Enum.into(%{})

  @space_key key(:space)
  @tab_key key(:tab)
  @backspace_keys [key(:backspace), key(:backspace2)]
  @up_key key(:arrow_up)
  @down_key key(:arrow_down)
  @enter_key key(:enter)
  @esc_key key(:esc)
  @quit_key key(:esc)

  # Vim navigation keys
  @j_key ?j
  @k_key ?k
  @h_key ?h
  @l_key ?l
  @vim_nav_keys [@j_key, @k_key, @h_key, @l_key]

  def init(_context) do
    # Initial state with the default view
    %{
      selected_tab: :tab1,
      show_overlay: false,
      focus_index: %{
        tab1: 0,
        tab2: 0,
        tab3: 0
      },
      overlay_fields: %{
        tab1: [:city, :tags]
      },
      # Add selection to the focusable fields
      focusable_fields: %{
        tab1: [:fname, :lname, :city, :tags],
        tab2: [:email],
        tab3: [:phone]
      },
      inputs: %{
        tab1: %{
          fname: %{
            value: ""
          },
          lname: %{
            value: ""
          },
          city: %{
            value: ""
          },
          tags: %{
            value: []
          }
        },
        tab2: %{
          email: %{
            value: ""
          }
        },
        tab3: %{
          phone: %{
            value: ""
          }
        }
      },
      overlays: %{
        tab1: %{
          city: %{
            show: false,
            filter: "",
            items: ["San Francisco", "New York", "Chicago"],
            filtered_items: [],
            cursor_index: 0
          },
          tags: %{
            show: false,
            filter: "",
            items: ["Large", "Medium", "Small"],
            filtered_items: [],
            cursor_index: 0
          }
        }
      }
    }
  end

  def update(model, {:event, %{key: key}}) when key in @page_keys do
    selected_tab = Map.get(@pages, key)

    # Update the selected tab based on the key pressed
    %{model | selected_tab: selected_tab}
  end

  # Pressing tab should cycle through the focusable fields
  def update(model, {:event, %{key: key}}) when key == @tab_key do
    selected_tab = model.selected_tab
    focused_field = Enum.at(model.focusable_fields[selected_tab], model.focus_index[selected_tab])

    # Need to check if selected tab has open overlay and handle accordingly
    case model.show_overlay do
      true ->
        model

      false ->
        next_index =
          rem(model.focus_index[selected_tab] + 1, length(model.focusable_fields[selected_tab]))

        %{model | focus_index: Map.put(model.focus_index, selected_tab, next_index)}
    end
  end

  # Pressing arrow keys when overlay is on should navigate the overlay
  def update(model, {:event, %{ch: ch, key: key}})
      when (key in [@up_key, @down_key] and model.show_overlay) or
             (ch in [@j_key, @k_key] and model.show_overlay) do
    selected_tab = model.selected_tab
    focused_field = Enum.at(model.focusable_fields[selected_tab], model.focus_index[selected_tab])

    items = get_in(model, [:overlays, selected_tab, focused_field, :items])
    current_index = get_in(model, [:overlays, selected_tab, focused_field, :cursor_index])

    # Navigate the selection list in the overlay
    new_index =
      case {key, ch} do
        {@up_key, 0} ->
          max(0, current_index - 1)

        {0, @k_key} ->
          max(0, current_index - 1)

        {@down_key, 0} ->
          min(length(items) - 1, current_index + 1)

        {0, @j_key} ->
          min(length(items) - 1, current_index + 1)
      end

    updated_overlays =
      update_in(model.overlays, [selected_tab, focused_field, :cursor_index], fn _ ->
        new_index
      end)

    %{
      model
      | overlays: updated_overlays
    }
  end

  # Pressing a backspace key should remove the last character from the focused field
  def update(model, {:event, %{ch: ch, key: key}}) when key in @backspace_keys do
    selected_tab = model.selected_tab
    focused_field = Enum.at(model.focusable_fields[selected_tab], model.focus_index[selected_tab])

    overlay_field =
      Map.has_key?(model.overlay_fields, selected_tab) and
        Enum.member?(model.overlay_fields[selected_tab], focused_field)

    remove_char(ch, model, {selected_tab, focused_field, overlay_field})
  end

  # Overlay aware enter / esc key handling
  def update(model, {:event, %{key: key}}) when key in [@enter_key, @esc_key] do
    selected_tab = model.selected_tab
    focused_field = Enum.at(model.focusable_fields[selected_tab], model.focus_index[selected_tab])

    overlay_field =
      Map.has_key?(model.overlay_fields, selected_tab) and
        Enum.member?(model.overlay_fields[selected_tab], focused_field)

    handle_key(key, model, {selected_tab, focused_field, overlay_field})
  end

  # Pressing a character key should append the character to the focused field
  def update(model, {:event, %{ch: ch, key: key}}) when ch > 0 or key == @space_key do
    # Handle regular typing
    selected_tab = model.selected_tab
    focused_field = Enum.at(model.focusable_fields[selected_tab], model.focus_index[selected_tab])

    overlay_field =
      Map.has_key?(model.overlay_fields, selected_tab) and
        Enum.member?(model.overlay_fields[selected_tab], focused_field)

    insert_char(ch, model, {selected_tab, focused_field, overlay_field})
  end

  def update(model, _message), do: model

  # Show the overlay when pressing enter on the overlay field
  def handle_key(@enter_key, %{show_overlay: false} = model, {tab, field, true}) do
    updated_overlays =
      update_in(model.overlays, [tab, field, :show], fn _ -> true end)

    %{
      model
      | show_overlay: true,
        overlays: updated_overlays
    }
  end

  # Handle selecting an item from the list
  def handle_key(@enter_key, %{show_overlay: true} = model, {tab, field, true}) do
    selected_index = model.overlays[tab][field].cursor_index
    selected_item = Enum.at(model.overlays[tab][field].items, selected_index)

    new_value =
      case get_in(model, [:inputs, tab, field]) do
        %{value: v} when is_binary(v) ->
          selected_item

        %{value: v} when is_list(v) ->
          # If selected value is in the list, we remove it
          if Enum.member?(v, selected_item) do
            Enum.reject(v, fn item -> item == selected_item end)
          else
            [selected_item | v]
          end
      end

    updated_inputs = update_in(model.inputs, [tab, field, :value], fn _ -> new_value end)

    %{
      model
      | inputs: updated_inputs
    }
  end

  def handle_key(@enter_key, %{show_overlay: false} = model, {tab, field, false}) do
    # TODO: Handle submission
    model
  end

  # Hide the overlay when pressing escape on the overlay
  def handle_key(@esc_key, %{show_overlay: true} = model, {tab, field, true}) do
    updated_overlays =
      update_in(model.overlays, [tab, field, :show], fn _ -> false end)

    %{
      model
      | show_overlay: false,
        overlays: updated_overlays
    }
  end

  def handle_key(_, model, _) do
    model
  end

  def insert_char(ch, %{show_overlay: true} = model, {tab, field, true}) do
    # Need to update the filter for the overlay
    items = get_in(model, [:overlays, tab, field, :items])

    updated_overlays =
      update_in(model.overlays, [tab, field, :filter], fn filter ->
        filter <> <<ch::utf8>>
      end)

    updated_overlays = apply_filter(updated_overlays, tab, field, items)

    %{
      model
      | overlays: updated_overlays
    }
  end

  def insert_char(ch, model, {tab, field, false}) do
    updated_inputs =
      update_in(model.inputs, [tab, field, :value], fn value ->
        value <> <<ch::utf8>>
      end)

    %{model | inputs: updated_inputs}
  end

  def insert_char(_, model, _) do
    model
  end

  def remove_char(_, %{show_overlay: true} = model, {tab, field, true}) do
    items = get_in(model, [:overlays, tab, field, :items])

    # Need to update the filter for the overlay
    updated_overlays =
      update_in(model.overlays, [tab, field, :filter], fn filter ->
        String.slice(filter, 0..-2//1)
      end)

    updated_overlays = apply_filter(updated_overlays, tab, field, items)

    %{
      model
      | overlays: updated_overlays
    }
  end

  def remove_char(_, model, {tab, field, _}) do
    updated_inputs =
      update_in(model.inputs, [tab, field, :value], fn value ->
        String.slice(value, 0..-2//1)
      end)

    %{
      model
      | inputs: updated_inputs
    }
  end

  def remove_char(_, model, _) do
    model
  end

  def apply_filter(initial, tab, field, items) do
    current_filter = get_in(initial, [tab, field, :filter])

    case current_filter do
      "" ->
        items = get_in(initial, [tab, field, :items])
        update_in(initial, [tab, field, :filtered_items], fn _ -> items end)

      _ ->
        update_in(initial, [tab, field, :filtered_items], fn _ ->
          Enum.filter(items, fn item ->
            String.contains?(
              String.downcase(item),
              String.downcase(current_filter)
            )
          end)
        end)
    end
  end

  def get_filtered_items(%{filter: ""} = overlay) do
    overlay.items
  end

  def get_filtered_items(overlay) do
    overlay.filtered_items
  end

  def render(model) do
    # Use `view/1` with `top_bar` and `bottom_bar`
    view(top_bar: title_bar(), bottom_bar: status_bar(model.selected_tab)) do
      # Render the main content based on the selected tab
      case model.selected_tab do
        :tab1 ->
          render_tab_one(model)

        :tab2 ->
          render_tab_two(model)

        :tab3 ->
          render_tab_three(model)
      end

      render_selected_tab_overlays(model)
    end
  end

  defp title_bar do
    # Title bar with instructions
    bar do
      label(content: "Tabbed App Example (Press F1, F2, F3, ESC to Quit)")
    end
  end

  defp status_bar(selected_tab) do
    # Bottom bar with navigation highlights
    bar do
      label do
        for key <- @page_keys do
          tab = Map.get(@pages, key)

          if tab == selected_tab do
            text(background: :green, color: :black, content: " #{tab} ")
          else
            text(content: " #{tab} ")
          end
        end
      end
    end
  end

  defp render_tab_one(model) do
    # Panel for the selected tab
    panel title: "Tab 1" do
      label(
        content: "First Name: #{model.inputs.tab1.fname.value}",
        color: focused?(model, :tab1, :fname)
      )

      label(
        content: "Last Name: #{model.inputs.tab1.lname.value}",
        color: focused?(model, :tab1, :lname)
      )

      label(
        content: "City: #{model.inputs.tab1.city.value}",
        color: focused?(model, :tab1, :city)
      )

      label(
        content: "Tags: #{model.inputs.tab1.tags.value |> Enum.join(", ")}",
        color: focused?(model, :tab1, :tags)
      )
    end
  end

  defp render_selected_tab_overlays(%{
         selected_tab: selected_tab,
         overlays: overlays,
         inputs: inputs
       }) do
    case overlays[selected_tab] do
      nil ->
        nil

      _ ->
        visible =
          overlays[selected_tab]
          |> Enum.map(fn {field, overlay} -> {field, overlay} end)
          |> Enum.filter(fn {field, overlay} -> overlay.show end)

        Enum.map(visible, fn {field, overlay} ->
          render_overlay(field, overlay, get_in(inputs, [selected_tab, field]))
        end)
    end
  end

  def render_overlay(field, overlay, input) do
    filtered_items = get_filtered_items(overlay)

    overlay do
      panel title: "Select Items (Press ESC to Close)", background: :red do
        label(content: "Filter by Name: #{overlay.filter}")

        Enum.map(filtered_items, fn item ->
          label(
            content: item,
            color:
              assign_color(
                filtered_items,
                overlay,
                item,
                input
              )
          )
        end)
      end
    end
  end

  defp render_tab_two(model) do
    # Panel for the selected tab
    panel title: "Tab 2" do
      label(
        content: "Email: #{model.inputs.tab2.email.value}",
        color: focused?(model, :tab2, :email)
      )
    end
  end

  defp render_tab_three(model) do
    # Panel for the selected tab
    panel title: "Tab 3" do
      row do
        column(size: 6) do
          label(
            content: "Phone: #{model.inputs.tab3.phone.value}",
            color: focused?(model, :tab3, :phone)
          )
        end

        column(size: 6) do
          label(
            content: "Phone: #{model.inputs.tab3.phone.value}",
            color: focused?(model, :tab3, :phone)
          )
        end
      end
    end
  end

  defp focused?(model, tab, field) do
    # Check if the field is focused
    if model.selected_tab == tab &&
         Enum.at(model.focusable_fields[tab], model.focus_index[tab]) == field do
      :green
    else
      :white
    end
  end

  defp assign_color(visible_items, overlay, item, input) do
    cursor_index = overlay.cursor_index
    item_index = Enum.find_index(visible_items, fn i -> i == item end)

    case {item, input} do
      {item, %{value: [_h | _t] = v}} ->
        cond do
          item_index == cursor_index -> :yellow
          Enum.member?(v, item) -> :green
          true -> :white
        end

      {item, %{value: []}} ->
        if item_index == cursor_index, do: :yellow, else: :white

      {item, %{value: v}} when is_binary(v) ->
        cond do
          item_index == cursor_index -> :yellow
          v == item -> :green
          true -> :white
        end
    end
  end
end

Ratatouille.run(MultiViewApp)
