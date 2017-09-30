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

using Toybox.WatchUi as Ui;
using Toybox.System;

class BPTInputDelegate extends Ui.BehaviorDelegate
{
  var view;

  function initialize(_view)
  {
    view = _view;
    BehaviorDelegate.initialize();
  }

  function onNextPage()
  {
     return view.next();
  }

  function onPreviousPage()
  {
    return view.prev();
  }

  function onSelect()
  {
    return view.select();
  }

  function onBack()
  {
    return view.back();
  }

  function onMenu()
  {
    return view.on_menu();
  }
}