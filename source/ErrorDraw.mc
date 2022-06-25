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
using Toybox.Graphics as Gfx;
using Toybox.System;

class ErrorDraw
{
  hidden var writer = new WrapText();
  hidden var pen_width = 8;
  hidden var screen_width;
  hidden var screen_height;
  hidden var screen_shape;

  public function initialize()
  {
    var settings = System.getDeviceSettings();
    screen_width = settings.screenWidth;
    screen_height = settings.screenHeight;
    screen_shape = settings.screenShape;
  }

  public function draw(dc, text, y)
  {
    dc.setPenWidth(pen_width);

    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    dc.clear();

    var text_area = new Ui.TextArea({
            :text=>text,
            :color=>Gfx.COLOR_WHITE,
            :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_SYSTEM_TINY, Gfx.FONT_SYSTEM_XTINY],
            :justification=>Gfx.TEXT_JUSTIFY_CENTER,
            :locX =>Ui.LAYOUT_HALIGN_CENTER,
            :locY=>Ui.LAYOUT_VALIGN_CENTER,
            :width=>dc.getWidth() * 0.87,
            :height=>dc.getHeight() * 0.37
        });

    text_area.draw(dc);
    dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_BLACK);
    if (screen_shape == System.SCREEN_SHAPE_ROUND)
       {
         dc.drawCircle(screen_width / 2, screen_height / 2, screen_width / 2 - (pen_width / 2));
       }
  }
}