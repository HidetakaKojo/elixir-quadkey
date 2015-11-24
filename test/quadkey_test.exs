defmodule QuadkeyTest do
  use ExUnit.Case

  test "from_geo" do
    # at Shibuya station
    {latitude, longitude} = {35.658182, 139.702043}
    assert Quadkey.from_geo(latitude, longitude, 1) == "1"
    assert Quadkey.from_geo(latitude, longitude, 2) == "13"
    assert Quadkey.from_geo(latitude, longitude, 3) == "133"
    assert Quadkey.from_geo(latitude, longitude, 5) == "13300"
    assert Quadkey.from_geo(latitude, longitude, 10) == "1330021123"
    assert Quadkey.from_geo(latitude, longitude, 15) == "133002112303013"
    assert Quadkey.from_geo(latitude, longitude, 20) == "13300211230301333311"
    assert Quadkey.from_geo(latitude, longitude, 23) == "13300211230301333311321"
  end

  test "from_quadkey" do
    assert Quadkey.from_quadkey("1") == {85.05112877980659, 0.0}
    assert Quadkey.from_quadkey("13") == {66.51326044311186, 90.0}
    assert Quadkey.from_quadkey("13300") == {40.97989806962013, 135.0}
    assert Quadkey.from_quadkey("1330021123") == {35.7465122599185, 139.5703125}
    assert Quadkey.from_quadkey("133002112303013") == {35.66622234103478, 139.691162109375}
  end

  test "children" do
    assert Enum.sort(Quadkey.children("133002112303013")) ==
      ["1330021123030130", "1330021123030131", "1330021123030132", "1330021123030133"]
    assert Enum.sort(Quadkey.children("133002112303010")) ==
      ["1330021123030100", "1330021123030101", "1330021123030102", "1330021123030103"]
  end

  test "parent" do
    assert Quadkey.parent("133002112303013") == "13300211230301"
    assert Quadkey.parent("133002112303010") == "13300211230301"
    assert Quadkey.parent("133002112303020") == "13300211230302"
  end
  
  test "around" do
    assert Enum.sort(Quadkey.around("1330021123")) ==
      ["1330021120", "1330021121", "1330021122", "1330021130", "1330021132", "1330021300", "1330021301", "1330021310"]
    assert Enum.sort(Quadkey.around("10")) ==
      ["01", "03", "11", "12", "13", "23", "32", "33"]
    assert Enum.sort(Quadkey.around("1")) == ["0", "2", "3"]
    assert Enum.sort(Quadkey.around("00000")) ==
      ["00001", "00002", "00003", "11111", "11113", "22222", "22223", "33333"]
  end
end
