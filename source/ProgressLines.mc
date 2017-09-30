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
using Toybox.Math;
using Toybox.Timer;

class ProgressLines
{
  private var screen_width;
  private var screen_height;
  private var screen_shape;
  private var fg_color;
  private var bg_color;
  private var outer_speed;
  private var inner_speed;
  private var outer_fi = 0;
  private var inner_fi = 0;
  private var pen_width = 8;
  private var mytimer = null;

  public function initialize()
  {
    var settings = System.getDeviceSettings();
    screen_width = settings.screenWidth;
    screen_height = settings.screenHeight;
    screen_shape = settings.screenShape;
  }

  public function draw(dc, param_fg_color, param_bg_color, param_speed)
  {
    fg_color = param_fg_color;
    bg_color = param_bg_color;
    outer_speed = param_speed;
    inner_speed = param_speed + 4;

    if (screen_shape == System.SCREEN_SHAPE_ROUND)
      {
        draw_arc(dc, (screen_width / 2) - (pen_width / 2), 150, 0, outer_speed, outer_fi);
        draw_arc(dc, (screen_width / 2) - (pen_width / 2) - 14, 120, 1, inner_speed, inner_fi);
      }
    if (mytimer == null)
      {
        mytimer = new Timer.Timer();
        mytimer.start(method(:timer_callback), 50, true);
      }
  }

  public function stop()
  {
    mytimer.stop();
  }

  public function timer_callback()
  {
    outer_fi = outer_fi + outer_speed;
    if (outer_fi > 360)
      {
        outer_fi = 0;
      }
    inner_fi = inner_fi + inner_speed;
    if (inner_fi > 360)
      {
        inner_fi = 0;
      }
    Ui.requestUpdate();
  }

  private function draw_arc(dc, radius, arc_diff, direction, ANIMATION_STEPS, fi)
  {
    dc.setPenWidth(pen_width);

    dc.setColor(bg_color, bg_color);
    var local_fi = fi - ANIMATION_STEPS;
    var R = radius;

    if (direction == 1)
      {
        local_fi = local_fi * -1;
      }
    draw_one(dc, R, local_fi, arc_diff);

    dc.setColor( fg_color, fg_color );
    local_fi = fi;
    if (direction == 1)
      {
        local_fi = local_fi * -1;
      }
    draw_one(dc, R, local_fi, arc_diff);
  }

  private function draw_one(dc, R, local_fi, arc_diff)
  {
    dc.drawArc(screen_width / 2, screen_height / 2, R, dc.ARC_CLOCKWISE, 90 - local_fi, 360-(arc_diff-90) - local_fi);
    var x = (screen_width / 2) + (R * Math.cos(Math.toRadians(local_fi - 90)));
    var y = (screen_height / 2) + (R * Math.sin(Math.toRadians(local_fi - 90)));
    dc.fillCircle(x.toNumber(), y.toNumber(), pen_width / 2);
    x = (screen_width / 2) + (R * Math.cos(Math.toRadians(local_fi - 90 + arc_diff)));
    y = (screen_height / 2) + (R * Math.sin(Math.toRadians(local_fi - 90 + arc_diff)));
    dc.fillCircle(x.toNumber(), y.toNumber(), pen_width / 2);
  }

}