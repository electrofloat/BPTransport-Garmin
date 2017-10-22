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
using Toybox.WatchUi as Ui;

class CommCheckListener extends Comm.ConnectionListener
{
  function initialize()
  {
    Comm.ConnectionListener.initialize();
  }

  public function onComplete()
  {
    $.DEBUGGER.println("Transmit complete");
    $.HAS_PHONE_APP = true;
    $.WAIT_FOR_DATA = false;
    Ui.requestUpdate();
  }

  public function onError()
  {
    $.DEBUGGER.println("Transmit error");
    $.HAS_PHONE_APP = false;
    $.WAIT_FOR_DATA = false;
    Ui.requestUpdate();
  }
}

class NearbyStopsListener extends Comm.ConnectionListener
{
  function initialize()
  {
    Comm.ConnectionListener.initialize();
  }

  public function onComplete()
  {
    $.DEBUGGER.println("Transmit complete");

    Ui.requestUpdate();
  }

  public function onError()
  {
    $.DEBUGGER.println("Transmit error");

    Ui.requestUpdate();
  }
}

class NearbyStopsDetailsListener extends Comm.ConnectionListener
{
  function initialize()
  {
    Comm.ConnectionListener.initialize();
  }

  public function onComplete()
  {
    $.DEBUGGER.println("Transmit complete");

    Ui.requestUpdate();
  }

  public function onError()
  {
    $.DEBUGGER.println("Transmit error");

    Ui.requestUpdate();
  }
}
class Communications
{
  public var comm_check_listener;
  enum
  {
    MESSAGE_TYPE_GET_LANGUAGE                   = 0,
    MESSAGE_TYPE_GET_LANGUAGE_REPLY             = 1,
    MESSAGE_TYPE_GET_NEARBY_STOPS               = 2,
    MESSAGE_TYPE_GET_NEARBY_STOPS_REPLY         = 3,
    MESSAGE_TYPE_GET_NEARBY_STOPS_DETAILS       = 4,
    MESSAGE_TYPE_GET_NEARBY_STOPS_DETAILS_REPLY = 5,
    MESSAGE_TYPE_GET_FAVORITES                  = 6
  }

  private var callback = null;
  public function initialize()
  {

  }

  public function initializer()
  {
    Comm.registerForPhoneAppMessages(method(:on_received));

    Comm.transmit(MESSAGE_TYPE_GET_LANGUAGE, null, new CommCheckListener());

  }

  public function send_get_nearby_stops(param_callback)
  {
    callback = param_callback;
    Comm.transmit(MESSAGE_TYPE_GET_NEARBY_STOPS, null, new NearbyStopsListener());
    $.DEBUGGER.println("send get nearby_stops");
  }

  public function send_get_nearby_stops_details()
  {
    callback = null;
    Comm.transmit(MESSAGE_TYPE_GET_NEARBY_STOPS_DETAILS, null, new NearbyStopsDetailsListener());
    $.DEBUGGER.println("send get nearby_stops details");
  }

  private function on_received(msg)
  {
    $.DEBUGGER.println(Lang.format("data: $1$", [msg.data.toString()]));
    callback.invoke(msg.data);
  }
}