defmodule Solid.LocalFileSystemWithTemplateCache do
  @moduledoc """
  This module is a copy of Solid.LocalFileSystem modified to cache parsed
  templates.
  """
  defstruct [:root, :pattern, :cache]
  @behaviour Solid.FileSystem

  @ets_cache_table :solid_template_cache
  def new(root, pattern \\ "_%s.liquid") do
    if :ets.whereis(@ets_cache_table) == :undefined do
      :ets.new(@ets_cache_table, [:set, :public, :named_table])
    end

    %__MODULE__{
      root: root,
      pattern: pattern,
      cache: :ets.whereis(@ets_cache_table)
    }
  end

  def read_template_file(template_path, file_system) do
    case :ets.lookup(file_system.cache, {template_path, file_system.root}) do
      [] ->
        full_path = full_path(template_path, file_system)

        if File.exists?(full_path) do
          template =
            full_path
            |> File.read!()
            |> Solid.parse!()

          :ets.insert(file_system.cache, {{template_path, file_system.root}, template})

          template
        else
          raise File.Error, reason: "No such template '#{template_path}'"
        end

      [{_, template}] ->
        template
    end
  end

  def full_path(template_path, file_system) do
    if String.match?(template_path, Regex.compile!("^[^./][a-zA-Z0-9_/-]+$")) do
      template_name = String.replace(file_system.pattern, "%s", Path.basename(template_path))

      full_path =
        if String.contains?(template_path, "/") do
          file_system.root
          |> Path.join(Path.dirname(template_path))
          |> Path.join(template_name)
          |> Path.expand()
        else
          file_system.root
          |> Path.join(template_name)
          |> Path.expand()
        end

      if String.starts_with?(full_path, Path.expand(file_system.root)) do
        full_path
      else
        raise File.Error, reason: "Illegal template path '#{Path.expand(full_path)}'"
      end
    else
      raise File.Error, reason: "Illegal template name '#{template_path}'"
    end
  end
end
