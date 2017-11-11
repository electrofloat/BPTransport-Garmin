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

class CommListener extends Comm.ConnectionListener
{
  private var callback;
  function initialize(cb)
  {
    callback = cb;

    Comm.ConnectionListener.initialize();
  }

  public function onComplete()
  {
    $.DEBUGGER.println("Transmit complete");

    $.data_in_progress = null;
    $.MESSAGE_QUEUE = $.MESSAGE_QUEUE.slice(1, $.MESSAGE_QUEUE.size());
    $.COMM_RETRY = 0;
    $.DEBUGGER.println(Lang.format("Message queue size AFTER COMPLETE: $1$", [$.MESSAGE_QUEUE.size()]));
    if ($.MESSAGE_QUEUE.size() > 0)
      {
        $.COMM_TIMER.start(callback, 50, false);
      }

    callback = null;
  }

  public function onError()
  {
    $.DEBUGGER.println("Transmit error");

    var backoff = 200 + ($.COMM_RETRY * 100);
    $.COMM_TIMER.start(callback, backoff, false);
    callback = null;
  }
}

class Communications
{
  public var comm_check_listener;
  public var comm_in_progress = false;
    
  private const MAX_RETRIES = 2;
  
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

  public function enqueue(data)
  {
    $.DEBUGGER.println(Lang.format("Enqueue data: $1$", [data]));
    $.MESSAGE_QUEUE.add(data);
    $.DEBUGGER.println(Lang.format("Enqueue MQ size: $1$", [$.MESSAGE_QUEUE.size()]));
    if ($.data_in_progress == null)
      {
        send_next_message();
      }
  }
  
  public function send_next_message()
  {
    $.DEBUGGER.println("send_next_message");
    if ($.data_in_progress != null)
      {
        $.COMM_RETRY += 1;
        if ($.COMM_RETRY > MAX_RETRIES)
          {
            //$.MESSAGE_QUEUE.remove(0);
            $.MESSAGE_QUEUE = $.MESSAGE_QUEUE.slice(1, $.MESSAGE_QUEUE.size());
            $.data_in_progress = null;
            if ($.WAIT_FOR_DATA)
              {
                $.HAS_PHONE_APP = false;
                $.WAIT_FOR_DATA = false;
                Ui.requestUpdate();
                return;
              }
          }
      }
      
    if ($.MESSAGE_QUEUE.size() == 0)
      {
        return;
      }
    $.DEBUGGER.println(Lang.format("Message queue size: $1$", [$.MESSAGE_QUEUE.size()]));
    if ($.data_in_progress == null)
      {
        $.data_in_progress = $.MESSAGE_QUEUE[0];
      }
      
    $.DEBUGGER.println(Lang.format("Sending: $1$", [$.data_in_progress]));
    Comm.transmit($.data_in_progress, null, new CommListener(method(:send_next_message)));
  }
  
  public function initializer()
  {
    Comm.registerForPhoneAppMessages(method(:on_received));
    enqueue(MESSAGE_TYPE_GET_LANGUAGE);
  }

  public function send_get_nearby_stops(param_callback)
  {
    $.DEBUGGER.println("send get nearby_stops");
    callback = param_callback;
    enqueue(MESSAGE_TYPE_GET_NEARBY_STOPS);
  }

  public function send_get_nearby_stops_details()
  {
    //callback = null;
    enqueue(MESSAGE_TYPE_GET_NEARBY_STOPS_DETAILS);
    $.DEBUGGER.println("send get nearby_stops details");
  }

  private function on_received(msg)
  {
    $.DEBUGGER.println(Lang.format("data: $1$", [msg.data.toString()]));
    if (msg.data[0] == MESSAGE_TYPE_GET_LANGUAGE_REPLY)
      {
        $.WAIT_FOR_DATA = false;
        $.HAS_PHONE_APP = true;
        Ui.requestUpdate();
        return;
      }
    var new_data = msg.data.slice(1, msg.data.size());
    callback.invoke(new_data);
  }
}