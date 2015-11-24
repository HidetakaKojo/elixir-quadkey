defmodule Quadkey do

  def from_geo(latitude, longitude, precision) do
    Quadkey.TileSystem.lat_long_to_pixel_xy({latitude, longitude}, precision)
      |> Quadkey.TileSystem.pixel_xy_to_tile_xy
      |> Quadkey.TileSystem.tile_xy_to_quadkey(precision)
  end

  def from_quadkey(quadkey) do
    precision = String.length(quadkey)
    Quadkey.TileSystem.quadkey_to_tile_xy(quadkey)
      |> Quadkey.TileSystem.tile_xy_to_pixel_xy
      |> Quadkey.TileSystem.pixel_xy_to_lat_long(precision)
  end

  def around(quadkey) do
    precision = String.length(quadkey)
    Quadkey.TileSystem.quadkey_to_tile_xy(quadkey)
      |> Quadkey.TileSystem.around_tile(precision)
      |> Enum.map(fn(tile_xy) ->
        Quadkey.TileSystem.tile_xy_to_quadkey(tile_xy, precision)
      end)
  end

  def parent(quadkey) do
    String.slice(quadkey, 0..-2)
  end

  def children(quadkey) do
    [0, 1, 2, 3]
      |> Enum.map(fn(digit) ->
        quadkey <> Integer.to_string(digit)
      end)
  end
end
