defmodule Quadkey.TileSystem do

  use Bitwise

  @earth_radius 6378137
  @min_latitude -85.05112878
  @max_latitude 85.05112878
  @min_longitude -180
  @max_longitude 180

  defp clip(number, min_value, max_value) do
    :erlang.max(number, min_value) |> :erlang.min(max_value)
  end

  def size_of_map(precision_level) do
    256 <<< precision_level
  end

  def ground_resolution(latitude, precision_level) do
    latitude = clip(latitude, @min_latitude, @max_latitude)
    :math.cos(latitude * :math.pi() / 180) * 2 * :math.pi() * @earth_radius / size_of_map(precision_level)
  end

  def map_scale(latitude, precision_level, screen_dpi) do
    ground_resolution(latitude, precision_level) * screen_dpi / 0.0254
  end

  def lat_long_to_pixel_xy({latitude, longitude}, precision_level) do
    latitude = clip(latitude, @min_latitude, @max_latitude)
    longitude = clip(longitude, @min_longitude, @max_longitude)

    x = (longitude + 180) / 360.0
    sin_latitude = :math.sin(latitude * :math.pi() / 180.0)
    y = 0.5 - :math.log((1 + sin_latitude) / (1 - sin_latitude)) / (4 * :math.pi())

    size_of_map = size_of_map(precision_level)
    pixel_x = clip(x * size_of_map + 0.5, 0, size_of_map - 1)
    pixel_y = clip(y * size_of_map + 0.5, 0, size_of_map - 1)
    {pixel_x, pixel_y}
  end

  def pixel_xy_to_lat_long({pixel_x, pixel_y}, precision_level) do
    size_of_map = size_of_map(precision_level)
    x = (clip(pixel_x, 0, size_of_map - 1) / size_of_map) - 0.5
    y = 0.5 - (clip(pixel_y, 0, size_of_map - 1) / size_of_map)

    latitude = 90 - 360 * :math.atan(:math.exp(-y * 2 * :math.pi())) / :math.pi()
    longitude = 360 * x
    {latitude, longitude}
  end

  def pixel_xy_to_tile_xy({pixel_x, pixel_y}) do
    {trunc(pixel_x / 256), trunc(pixel_y / 256)}
  end

  def tile_xy_to_pixel_xy({tile_x, tile_y}) do
    {tile_x * 256, tile_y * 256}
  end

  defp put_in_size(n, size) do
    case n do
      x when x < 0 -> n + size
      x when x >= size -> x - size
      _ -> n
    end
  end
  def around_tile({tile_x, tile_y}, precision) do
    size_of_map = size_of_map(precision)
    tiles = Enum.map([tile_x-1, tile_x, tile_x+1], fn(x) ->
      Enum.map([tile_y-1, tile_y, tile_y+1], fn(y) ->
        {put_in_size(x, size_of_map), put_in_size(y, size_of_map)}
      end)
    end) |> List.flatten
      |> Enum.uniq
      |> Enum.reject(fn(x) -> x == {tile_x, tile_y} end)
  end

  def tile_xy_to_quadkey({tile_x, tile_y}, precision_level) do
    tile_xy_to_quadkey_loop({tile_x, tile_y}, precision_level)
  end
  defp tile_xy_to_quadkey_loop(_tile_xy, 0) do
    ""
  end
  defp tile_xy_to_quadkey_loop({tile_x, tile_y}, num) do
    digit = 0
    mask = 1 <<< (num - 1)
    digit = if ((tile_x &&& mask) != 0) do
      digit + 1
    else
      digit
    end
    digit = if ((tile_y &&& mask) != 0) do
      digit + 2
    else
      digit
    end
    Integer.to_string(digit) <> tile_xy_to_quadkey_loop({tile_x, tile_y}, num-1)
  end

  def quadkey_to_tile_xy(quadkey) do
    precision_level = String.length(quadkey)
    quadkey_to_tile_xy_loop(quadkey, precision_level, {0, 0})
  end
  def quadkey_to_tile_xy_loop(_quadkey, 0, tile_xy) do
    tile_xy
  end
  def quadkey_to_tile_xy_loop(quadkey, num, {tile_x, tile_y}) do
    mask = 1 <<< num - 1
    precision_level = String.length(quadkey)
    {new_tile_x, new_tile_y} = case String.at(quadkey, precision_level - num) do
      "0" ->
        {tile_x, tile_y}
      "1" ->
        {tile_x ||| mask, tile_y}
      "2" ->
        {tile_x, tile_y ||| mask}
      "3" ->
        {tile_x ||| mask, tile_y ||| mask}
      _ ->
        raise("Invalid QuadKey digit sequence.")
    end
    quadkey_to_tile_xy_loop(quadkey, num - 1, {new_tile_x, new_tile_y})
  end
end
