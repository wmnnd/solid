defmodule Solid.Tag.Counter do
  import NimbleParsec
  alias Solid.Parser.{Tag, Literal, Variable}
  alias Solid.Argument

  @behaviour Solid.Tag

  @impl true
  def render([counter_exp: [{operation, default}, field]], context, _options) do
    value = Argument.get([field], context, scopes: [:counter_vars]) || default
    {:field, [field_name]} = field

    context = %{
      context
      | counter_vars: Map.put(context.counter_vars, field_name, value + operation)
    }

    {[text: to_string(value)], context}
  end

  @impl true
  def spec() do
    space = Literal.whitespace(min: 0)

    increment =
      string("increment")
      |> replace({1, 0})

    decrement =
      string("decrement")
      |> replace({-1, -1})

    ignore(Tag.opening_tag())
    |> concat(choice([increment, decrement]))
    |> ignore(space)
    |> concat(Variable.field())
    |> ignore(Tag.closing_tag())
    |> tag(:counter_exp)
  end
end