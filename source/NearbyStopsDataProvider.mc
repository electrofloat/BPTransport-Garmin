/*
    BPTransport - Budapest Public Transport
    Copyright (C) 2017  DEXTER

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

using Toybox.Communications as Comm;
using Toybox.Graphics as Gfx;
using Toybox.Position;
using Toybox.System;

class NearbyStopsDataProvider
{
  //Blaha Lujza tér
  public const LON=19.070510;
  public const LAT=47.497099;

  private var callback = null;
  public var nearby_stops_array = [];
  hidden var screen_shape;

  enum {
    STOP_ID,
    STOP,
    DIRECTION,
    LINES,
    DISTANCE,
    COLOR,
    RESOURCE
  }

  public function initialize()
  {
    var settings = System.getDeviceSettings();
    screen_shape = settings.screenShape;
  }

  public function get_data(location, param_callback)
  {
    callback = param_callback;
    var radius = Application.getApp().getProperty("radius");
    var url = Lang.format(
      "https://futar.bkk.hu/api/query/v1/ws/otp/api/where/stops-for-location.json?lon=$1$&lat=$2$&radius=$3$",
      [location[1].format("%f"), location[0].format("%f"), radius]
    );
    $.DEBUGGER.println(url);

    var options = {                                             // set the options
           :method => Comm.HTTP_REQUEST_METHOD_GET      // set HTTP method
       };
    Comm.makeWebRequest(url,
    null,
    options,
    method(:response_callback));
  }

  public function response_callback(response_code, data)
  {
    $.DEBUGGER.println(response_code);
    $.DEBUGGER.println(data);
    if (response_code != 200)
      {
        if (callback != null)
          {
            callback.invoke(response_code);
          }
        return;
      }
    try
      {
        var json_data = data.get("data");
        if (json_data == null)
          {
            throw new JsonParseException();
          }
        var list = json_data.get("list");
        if (list == null ||
            !(list instanceof Array))
          {
            throw new JsonParseException();
          }
        var references = json_data.get("references");
        if (references == null)
          {
            throw new JsonParseException();
          }
        var routes = references.get("routes");
        if (routes == null)
          {
            throw new JsonParseException();
          }
        var stop = null;
        var direction = null;
        var lines = "";
        var distance = null;
        var stop_id = null;

        var location = new Position.Location(
          {
            :latitude => LAT,
            :longitude => LON,
            :format => :degrees
          }
        );

        nearby_stops_array = [];
        for (var i = 0; i < list.size(); i++)
          {
            stop = list[i].get("name");
            if (stop == null)
              {
                continue;
              }
            stop_id = list[i].get("id");
            if (stop_id == null)
              {
                continue;
              }
            var lat = list[i].get("lat");
            if (lat == null)
              {
                continue;
              }
            var lon = list[i].get("lon");
            if (lon == null)
              {
                continue;
              }

            var stop_location = new Position.Location(
              {
                :latitude => lat.toFloat(),
                :longitude => lon.toFloat(),
                :format => :degrees
              }
            );

            distance = Utils.get_simple_distance(location, stop_location);
            var route_ids = list[i].get("routeIds");
            if (route_ids == null ||
                !(route_ids instanceof Array) ||
                route_ids.size() == 0)
              {
                continue;
              }
            var color_text = list[i].get("stopColorType");

            var j = 0;
            for (; j < route_ids.size(); j++)
              {
                var route = routes.get(route_ids[j]);
                if (route == null)
                  {
                    break;
                  }
                if (lines.length() == 0)
                  {
                    lines = route.get("shortName");
                  }
                else
                  {
                    lines = Lang.format("$1$, $2$", [lines, route.get("shortName")]);
                  }
                if (direction == null)
                  {
                    direction = Lang.format("->$1$", [route.get("description")]);
                  }
              }
            if (j != route_ids.size())
              {
                continue;
              }
            fill_nearby_stops_array(color_text, stop_id, stop, direction, lines, distance);

            if (nearby_stops_array.size() == 10)
              {
                break;
              }
              direction = null;
              lines = "";
            }
      }
    catch (ex instanceof JsonParseException)
      {
        if (callback != null)
          {
            callback.invoke(-9999);
          }
        return;
      }

    sort_array();
    if (callback != null)
      {
        callback.invoke(response_code);
      }
  }

  public function clear_callback()
  {
    callback = null;
  }
  
  public function populate_array_from_online_data(data)
  {
    nearby_stops_array = [];
    for (var i = 0; i < data.size(); i++)
      {
        var dict = data[i];
        fill_nearby_stops_array(dict["stop_color_type"], dict["stop_id"], dict["stop_name"], dict["direction_name"], dict["line_numbers"], dict["distance"]);
      }
  }

  private function fill_nearby_stops_array(color_text, stop_id, stop, direction, lines, distance)
  {
    var color = get_color(color_text);
    nearby_stops_array.add({
              STOP_ID => stop_id,
              STOP => stop,
              DIRECTION => direction,
              LINES => lines,
              DISTANCE => distance,
              COLOR => color[0],
              RESOURCE => color[1]
            });
  }

  private function get_color(color_text)
  {
    var tram_color = Gfx.COLOR_YELLOW;
    var bus_color = Gfx.COLOR_BLUE;
    var nightbus_color = Gfx.COLOR_DK_BLUE;
    var trolleybus_color = Gfx.COLOR_RED;

    if (Toybox.System has :SCREEN_SHAPE_SEMI_OCTAGON && screen_shape == System.SCREEN_SHAPE_SEMI_OCTAGON)
      {
        tram_color = Gfx.COLOR_BLACK;
        bus_color = Gfx.COLOR_BLACK;
        nightbus_color = Gfx.COLOR_BLACK;
        trolleybus_color = Gfx.COLOR_BLACK;
      }

    if (color_text.equals("TRAM"))
      {
        return [tram_color, Rez.Drawables.tram];
      }
    else if (color_text.equals("BUS"))
      {
        return [bus_color, Rez.Drawables.bus];
      }
    else if (color_text.equals("NIGHTBUS"))
      {
        return [nightbus_color, Rez.Drawables.nightbus];
      }
    else if (color_text.equals("TROLLEYBUS"))
      {
        return [trolleybus_color, Rez.Drawables.trolley];
      }
    else if (color_text.equals("M1") || color_text.equals("M2") || color_text.equals("M3") || color_text.equals("M4"))
      {
        return [Gfx.COLOR_BLACK, Rez.Drawables.metro];
      }

    return [Gfx.COLOR_BLACK, null];
  }

  private function sort_array()
  {
    for (var i = 1; i < nearby_stops_array.size(); i++)
      {
        var j = i;
        while ((j > 0) && (nearby_stops_array[j - 1].get(DISTANCE) > nearby_stops_array[j].get(DISTANCE)))
        {
          var temp = nearby_stops_array[j];
          nearby_stops_array[j] = nearby_stops_array[j - 1];
          nearby_stops_array[j - 1] = temp;
          j = j - 1;
        }
      }
  }

}