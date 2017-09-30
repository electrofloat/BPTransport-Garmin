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

using Toybox.Math;

class Utils
{
  public function get_distance(location, stop_location)
  {
    var R = 6371e3;
    var fi1 = location.toRadians()[0];
    var fi2 = stop_location.toRadians()[0];
    var delta_fi = fi2-fi1;
    var delta_lambda = stop_location.toRadians()[1] - location.toRadians()[1];

    var a = Math.sin(delta_fi/2) * Math.sin(delta_fi/2) +
        Math.cos(fi1) * Math.cos(fi2) *
        Math.sin(delta_lambda/2) * Math.sin(delta_lambda/2);

    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    var ret_value = R * c;

    return ret_value;
  }

  public function get_simple_distance(location, stop_location)
  {
    var R = 6371e3;
    var fi1 = location.toRadians()[0];
    var fi2 = stop_location.toRadians()[0];
    var delta_fi = fi2-fi1;
    var delta_lambda = stop_location.toRadians()[1] - location.toRadians()[1];

    var x = delta_lambda * Math.cos((fi1+fi2)/2);

    var ret_value = Math.sqrt(x*x + delta_fi * delta_fi) * R;

    return ret_value;
  }

  public function get_text_for_error_code(error_code)
  {
    if (error_code == -1001)
      {
        return "Secure connection required";
      }
    else if (error_code == -402)
      {
        return "Response too large, try lowering the Radius";
      }
    else if (error_code == -9999)
      {
        return "Cannot parse response";
      }

    return error_code.toString();
  }
}