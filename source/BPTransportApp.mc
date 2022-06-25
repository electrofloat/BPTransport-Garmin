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
var FAKE_FUTAR_DATA = false;

var WRITER = new WrapText();
var DEBUGGER = new Debugger(debug);
var COMM;
var HAS_PHONE_APP = false;
var WAIT_FOR_DATA = false;
var data_in_progress;
var wait_for_answer;

class BPTransportApp extends App.AppBase {

  function initialize()
  {
    AppBase.initialize();
    $.data_in_progress = null;
    $.wait_for_answer = false;
    //$.COMM = new Communications();
    //$.COMM.initializer();
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
