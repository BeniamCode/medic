defmodule Medic.Notifications.TemplateRenderer do
  @moduledoc """
  Service for rendering email templates with variable substitution.
  """

  @doc """
  Renders a string template with the given variables.
  
  Supported syntax:
  - {{ variable }} for simple substitution
  
  Ideally, we'd use a more robust engine like Liquid, but for now we can use a simple regex replacement
  or EEx if we want to support logic (though EEx is risky for user-edited templates).
  
  Let's stick to simple {{ variable }} replacement for safety and simplicity initially.
  """
  def render(template_string, variables) when is_binary(template_string) do
    Regex.replace(~r/\{\{\s*(\w+)\s*\}\}/, template_string, fn _, key ->
      case Map.get(variables, key) do
        nil -> ""
        val -> to_string(val)
      end
    end)
  end

  def render(nil, _), do: ""

  @doc """
  Prepends the base URL to relative paths in the rendered content if needed,
  though usually variables should contain full URLs.
  """
  def post_process(content) do
    content
  end
end
