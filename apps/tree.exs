defmodule TreeDemo do
  @behaviour Ratatouille.App

  import Ratatouille.View

  def init(_context) do
    %{}
  end

  def update(model, _message) do
    model
  end

  def render(_model) do
    view do
      panel title: "Tree Example" do
        tree do
          tree_node content: "Kingdom" do
            tree_node content: "Animalia" do
              tree_node content: "Chordata" do
                tree_node content: "Mammalia" do
                  tree_node(content: "Primates")
                  tree_node(content: "Carnivora")
                end

                tree_node content: "Reptilia" do
                  tree_node(content: "Squamata")
                  tree_node(content: "Testudines")
                end
              end
            end

            tree_node content: "Plantae" do
              tree_node content: "Angiosperms" do
                tree_node(content: "Monocots")
                tree_node(content: "Eudicots")
              end
            end
          end
        end
      end
    end
  end
end

Ratatouille.run(TreeDemo)

