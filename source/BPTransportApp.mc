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

using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Communications as Comm;

var debug = false;

var WRITER = new WrapText();
var DEBUGGER = new Debugger(debug);
var COMM = new Communications();
var HAS_PHONE_APP = false;
var WAIT_FOR_DATA = true;
var MESSAGE_QUEUE = [];
var data_in_progress;
var COMM_TIMER;
var COMM_RETRY;

class BPTransportApp extends App.AppBase {

  function initialize()
  {
    AppBase.initialize();
    $.data_in_progress = null;
    $.COMM_TIMER = new Timer.Timer();
    $.COMM_RETRY = 0;
    $.COMM.initializer();
  }

    // onStart() is called on application start up
  function onStart(state)
  {
  }

    // onStop() is called when your application is exiting
  function onStop(state)
  {
  }

    // Return the initial view of your application here
  function getInitialView()
  {
    var view = new NearbyStopsView();
    return [ view, new BPTInputDelegate(view)];
  }
}
