defmodule ThreeColumns do
  @behaviour Ratatouille.App

  import Ratatouille.View

  def start(_type, _args) do
    Ratatouille.run(__MODULE__)
  end

  def init(_context),
    do: %{
      left_column: "Left",
      middle_column: "Middle",
      right_column: "Right"
    }

  def update(model, _msg) do
    model
  end

  def render(model) do
    view do
      row do
        column(size: 2) do
          panel title: "Left Column" do
            label(content: model.left_column)
          end
        end

        column(size: 4) do
          panel title: "Middle Column" do
            label(content: model.middle_column)
          end
        end

        column(size: 2) do
          panel title: "Right Column" do
            label(content: model.right_column)
          end
        end
      end
    end
  end
end

Ratatouille.run(ThreeColumns)

