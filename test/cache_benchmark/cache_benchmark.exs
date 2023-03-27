defmodule CacheBenchmark do
  use ExUnit.Case, async: true
  import Solid.Helpers
  require Logger

  @count 10_000
  @path ("test/cache_benchmark/templates" |> Path.absname()) <> "/"
  @template File.read!("test/cache_benchmark/templates/index.liquid") |> Solid.parse!()
  @content %{
    "blocks" => [
      %{"type" => "a", "content" => "1"},
      %{"type" => "b", "content" => "2"},
      %{"type" => "c", "content" => "3"},
      %{"type" => "c", "content" => "4"},
      %{"type" => "d", "content" => "5"}
    ]
  }

  test "Render with no cache" do
    file_system = Solid.LocalFileSystem.new(@path)

    {time, _} =
      :timer.tc(fn ->
        for _i <- 1..@count do
          Solid.render!(@template, @content, file_system: {Solid.LocalFileSystem, file_system})
        end
      end)

    assert IO.puts("No Cache: #{time / 1000}ms")
  end

  test "Render with file cache" do
    file_system = Solid.LocalFileSystemWithFileCache.new(@path)

    {time, _} =
      :timer.tc(fn ->
        for _i <- 1..@count do
          Solid.render!(@template, @content,
            file_system: {Solid.LocalFileSystemWithFileCache, file_system}
          )
        end
      end)

    assert IO.puts("File Cache: #{time / 1000}ms")
  end

  test "Render with template cache" do
    file_system = Solid.LocalFileSystemWithTemplateCache.new(@path)

    {time, _} =
      :timer.tc(fn ->
        for _i <- 1..@count do
          Solid.render!(@template, @content,
            file_system: {Solid.LocalFileSystemWithTemplateCache, file_system}
          )
        end
      end)

    assert IO.puts("Template Cache: #{time / 1000}ms")
  end
end
