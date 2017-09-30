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

using Toybox.Position;
using Toybox.Timer;
using Toybox.System;

class LocationProvider
{
  private var info = null;
  private var prev_info = null;
  private var callback = null;
  private var timer = new Timer.Timer();
  private const DEVIATION = 3; //in meters;

  public function initialize()
  {
  }

  private function on_position(param_info)
  {

    if (param_info.accuracy < Position.QUALITY_USABLE)
      {
        return;
      }
    info = param_info;

    if (prev_info != null)
      {
        return;
      }

    $.DEBUGGER.println("LocationProvider first position");
    prev_info = info;
    callback.invoke(info);
    timer.start(method(:timercallback), 5000, true);
  }

  private function timercallback()
  {
    var distance = Utils.get_simple_distance(info.position, prev_info.position);
    $.DEBUGGER.println(Lang.format("LocationProvider::timercallback; $1$", [distance]));
    if (distance > DEVIATION)
      {
        prev_info = info;
        callback.invoke(prev_info);
      }
  }

  public function start(param_callback)
  {
    callback = param_callback;
    if (prev_info != null)
      {
        timer.start(method(:timercallback), 5000, true);
      }
  	Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:on_position));
  }

  public function stop()
  {
    timer.stop();
    Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:on_position));
    callback = null;
  }
}