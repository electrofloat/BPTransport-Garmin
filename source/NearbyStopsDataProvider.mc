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

class NearbyStopsDataProvider
{
  //Blaha Lujza tér
  public const LON=19.070510;
  public const LAT=47.497099;

  private var callback = null;
  public var nearby_stops_array = [];

  enum {
    STOP_ID,
    STOP,
    DIRECTION,
    LINES,
    DISTANCE,
    COLOR
  }

  public function initialize()
  {
  }

  public function get_data(location, param_callback)
  {
    callback = param_callback;
    var radius = Application.getApp().getProperty("PROP_RADIUS");
    var url = Lang.format(
      "http://futar.bkk.hu/bkk-utvonaltervezo-api/ws/otp/api/where/stops-for-location.json?lon=$1$&lat=$2$&radius=$3$",
      [location[1].format("%f"), location[0].format("%f"), radius]
    );
    $.DEBUGGER.println(url);

    var options = {                                             // set the options
           :method => Communications.HTTP_REQUEST_METHOD_GET      // set HTTP method
       };
    Comm.makeWebRequest(url,
    null,
    options,
    method(:response_callback));
  }

  private function response_callback(response_code, data)
  {
    $.DEBUGGER.println(response_code);
    $.DEBUGGER.println(data);
    if (response_code != 200)
      {
        callback.invoke(response_code);
        callback = null;
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
            var color = get_color(color_text);
            nearby_stops_array.add({
              STOP_ID => stop_id,
                  STOP => stop,
                  DIRECTION => direction,
                  LINES => lines,
                  DISTANCE => distance,
                  COLOR => color
                });
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
        callback.invoke(-9999);
        callback = null;
        return;
      }

    sort_array();

    callback.invoke(response_code);
    callback = null;
  }

  private function get_color(color_text)
  {
    if (color_text.equals("TRAM"))
      {
        return Gfx.COLOR_YELLOW;
      }
    else if (color_text.equals("BUS"))
      {
        return Gfx.COLOR_BLUE;
      }
    else if (color_text.equals("NIGHTBUS"))
      {
        return Gfx.COLOR_DK_BLUE;
      }
    else if (color_text.equals("TROLLEYBUS"))
      {
        return Gfx.COLOR_RED;
      }

    return Gfx.COLOR_BLACK;
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