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

class NearbyStopsDetailsDataProvider
{
  private var callback;
  public var nearby_stops_details_array = [];
  enum {
    LINE_NUMBER,
    START_TIME,
    PREDICTED_START_TIME,
    DIRECTION
  }

  public function initialize()
  {
  }

  public function get_data(stop_id, _callback)
  {
    callback = _callback;
    var url = Lang.format(
      "http://futar.bkk.hu/bkk-utvonaltervezo-api/ws/otp/api/where/arrivals-and-departures-for-stop.json?includeReferences=routes,trips&stopId=$1$",
      [stop_id]
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
        var trips = references.get("trips");
        if (trips == null)
          {
            throw new JsonParseException();
          }
        var entry = json_data.get("entry");
        if (entry == null)
          {
            throw new JsonParseException();
          }
        var stop_times = entry.get("stopTimes");
        if (stop_times == null ||
            !(stop_times instanceof Array))
          {
            throw new JsonParseException();
          }

        var line_number = null;
        var start_time = null;
        var predicted_start_time = null;
        var direction = null;
        $.DEBUGGER.println(stop_times);

        nearby_stops_details_array = [];
        for (var i = 0; i < stop_times.size(); i++)
          {
            start_time = stop_times[i].get("departureTime");
            if (start_time == null)
              {
                continue;
              }
            predicted_start_time = stop_times[i].get("predictedDepartureTime");
            if (predicted_start_time == null)
              {
                predicted_start_time = start_time;
              }
            var trip_id = stop_times[i].get("tripId");
            if (trip_id == null)
              {
                continue;
              }

            var trip = trips.get(trip_id);
            if (trip == null)
              {
                continue;
              }

            var route_id = trip.get("routeId");
            if (route_id == null)
              {
                continue;
              }
            direction = trip.get("tripHeadsign");

            var route = routes.get(route_id);
            if (route == null)
              {
                continue;
              }

            line_number = route.get("shortName");

            nearby_stops_details_array.add({
              START_TIME => start_time,
                  PREDICTED_START_TIME => predicted_start_time,
                  DIRECTION => direction,
                  LINE_NUMBER => line_number
                });

            if (nearby_stops_details_array.size() == 10)
              {
                break;
              }
          }
      }
    catch (ex instanceof JsonParseException)
      {
        callback.invoke(-9999);
        callback = null;
        return;
      }

    callback.invoke(response_code);
    callback = null;
  }

}