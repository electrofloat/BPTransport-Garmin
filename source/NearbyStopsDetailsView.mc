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
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.System;
import Toybox.Lang;

class NearbyStopsDetailsView extends Ui.View
{
  private var FONT = Gfx.FONT_SYSTEM_XTINY;
  private var DISPLAY_ELEMENTS = 4;
  private var current_item = 0;
  private var update_timer = new Timer.Timer();

  private var download_done = false;
  private var error_response_code = null;
  private var progress_lines;
  private var error_draw;
  private var linenum_color;
  private var linenum_color2;
  private var nearby_stops_details_data_provider;
    
  public function initialize(stop_id, color, color2, nearby_stops_current_item)
  {
    $.DEBUGGER.println(Lang.format("initialize, download_done: $1$", [download_done]));
    
    if ($.NEW_LAYOUT)
      {
        current_item = 1;
      }

    if ($.SCREEN_SHAPE == System.SCREEN_SHAPE_SEMI_OCTAGON)
      {
        DISPLAY_ELEMENTS = 3;
      }
  
    progress_lines = new ProgressLines();
    error_draw = new ErrorDraw();
    linenum_color = color;
    linenum_color2 = color2;
    nearby_stops_details_data_provider = new NearbyStopsDetailsDataProvider();
    if ($.HAS_PHONE_APP)
      {
        $.COMM.send_get_nearby_stops_details(nearby_stops_current_item, method(:on_get_nearby_stops_details));
      }
    else if ($.debug && $.FAKE_FUTAR_DATA)
        {
          var my_dict = {
            "start_time" => Time.now().value() + 60,
            "pred_start" => Time.now().value() + 120,
            "direction" => "Gazdagréti tér - Újpalota, Nyírpalota utca",
            "line_num" => "8E"
          };
          var data = [MESSAGE_TYPE_GET_NEARBY_STOPS_DETAILS_REPLY];
          for (var i = 0; i < 5; i++)
          {
            data.add(my_dict);
          }

          on_get_nearby_stops_details(data);
        }
    else
      {
        nearby_stops_details_data_provider.get_data(stop_id, method(:on_data));
      }

    View.initialize();
  }

  public function on_get_nearby_stops_details(data as Lang.Array)
  {
    if (data.size() == 0 ||
        data[0] != MESSAGE_TYPE_GET_NEARBY_STOPS_DETAILS_REPLY)
      {
        return;
      }
    data = data.slice(1, data.size());
    nearby_stops_details_data_provider.populate_array_from_online_data(data);
    on_data(200);
  }
  
  public function on_data(response_code)
  {
    if (response_code != 200)
      {
        error_response_code = response_code;
        Ui.requestUpdate();
        return;
      }

    download_done = true;
    progress_lines.stop();
    Ui.requestUpdate();
    update_timer.start(method(:timercallback), 1000, true);
  }

  public function timercallback()
  {
    Ui.requestUpdate();
  }

  private function draw_arrow(dc, clock_height, bottom_height, element_height)
  {
    var y = clock_height + element_height;
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    dc.drawLine(0, y, dc.getWidth(), y);
    y = y + element_height;
    dc.drawLine(0, y, dc.getWidth(), y);
    if (current_item < nearby_stops_details_data_provider.nearby_stops_details_array.size() - 1)
      {
        dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, dc.getHeight() - bottom_height + 1, dc.getWidth(), dc.getHeight());
        if ($.SCREEN_SHAPE == System.SCREEN_SHAPE_SEMI_OCTAGON)
          {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
          }
        else
          {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
          }
        
        dc.drawText((dc.getWidth() / 2) , dc.getHeight() - bottom_height - 8, Gfx.FONT_TINY, "->", Gfx.TEXT_JUSTIFY_CENTER);
      }
    else
      {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y + 1, dc.getWidth(), dc.getHeight());
      }
  }

  private function draw_countdown_timer(dc, time, color, font, y)
  {
    if ($.SCREEN_SHAPE == System.SCREEN_SHAPE_SEMI_OCTAGON)
      {
        var width_at_pos = dc.getTextWidthInPixels(time, font);
        //$.DEBUGGER.println(Lang.format("width at pos: $1$, width: $2$", [width_at_pos, dc.getWidth()]));
        dc.drawText(dc.getWidth() - width_at_pos - 5, y, font, time, Gfx.TEXT_JUSTIFY_LEFT);

        return;
      }

    var fontheight = dc.getFontHeight(font);

    dc.setColor(color, Gfx.COLOR_TRANSPARENT);
    var width_at_pos = $.WRITER.getWidthForLine(y + 5, fontheight);
    dc.drawText((dc.getWidth() - width_at_pos) / 2 + width_at_pos, y, font, time, Gfx.TEXT_JUSTIFY_RIGHT);
  }

  private function draw_center_time(dc, x, y, font, start_time)
  {
    var time_moment = new Time.Moment(start_time.toNumber());
    var time = Gregorian.info(time_moment, Time.FORMAT_SHORT);

    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
    dc.drawText(x, y, font, Lang.format("$1$:$2$", [time.hour.format("%02d"), time.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);

    return time;
  }

  public function onUpdate(dc)
  {
    //$.DEBUGGER.println("onupdate");
    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    dc.setPenWidth(1);
    dc.clear();

    if (error_response_code != null)
      {
        error_draw.draw(dc, Lang.format("Error downloading data; $1$", [Utils.get_text_for_error_code(error_response_code)]), 50);
        return;
      }
    if (!download_done)
      {
        progress_lines.draw(dc, Gfx.COLOR_BLUE, Gfx.COLOR_BLACK, 8);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

        var text_area = new Ui.TextArea({
            :text=>"Downloading realtime data...",
            :color=>Gfx.COLOR_WHITE,
            :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_SYSTEM_TINY, Gfx.FONT_SYSTEM_XTINY],
            :justification=>Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER,
            :locX =>Ui.LAYOUT_HALIGN_CENTER,
            :locY=>Ui.LAYOUT_VALIGN_CENTER,
            :width=>dc.getWidth() * 0.8,
            :height=>dc.getHeight() * 0.7
        });

        text_area.draw(dc);
        return;
      }
    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
    dc.clear();

    var clock_height = 1 + Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY);
    var y = clock_height;
    
    if  (nearby_stops_details_data_provider.nearby_stops_details_array.size() == 0)
      {
        var text_area = new Ui.TextArea({
            :text=>"No departures in the near future.",
            :color=>Gfx.COLOR_BLACK,
            :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_SYSTEM_TINY, Gfx.FONT_SYSTEM_XTINY],
            :justification=>Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER,
            :locX =>Ui.LAYOUT_HALIGN_CENTER,
            :locY=>Ui.LAYOUT_VALIGN_CENTER,
            :width=>dc.getWidth() * 0.8,
            :height=>dc.getHeight() * 0.7
        });

        text_area.draw(dc);
        return;
      }

    var now = new Time.Moment(Time.now().value());
    var now_greg = Gregorian.info(now, Time.FORMAT_SHORT);
    dc.setColor( Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK );
    dc.fillRectangle(0, 0, dc.getWidth(), clock_height);
    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY);
    dc.drawText(dc.getWidth() / 2, 0, Gfx.FONT_SYSTEM_TINY, Lang.format("$1$:$2$", [now_greg.hour.format("%02d"), now_greg.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
    
    if (!$.NEW_LAYOUT)
    {
      var fontheight = Gfx.getFontHeight(FONT);
      var element_height = (dc.getHeight() - clock_height) / DISPLAY_ELEMENTS;
    for (var i = 0; i < DISPLAY_ELEMENTS; i++)
      {
         var local_y = y + (i * element_height);

         if (i == 0 && current_item == 0)
           {
             dc.fillRectangle(0, clock_height, dc.getWidth(), element_height);
             continue;
           }
         if (current_item + i - 1 > nearby_stops_details_data_provider.nearby_stops_details_array.size() - 1)
           {
             dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
             dc.fillRectangle(0, local_y, dc.getWidth(), dc.getHeight());
             continue;
           }
         dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );

         var item = nearby_stops_details_data_provider.nearby_stops_details_array[current_item + i - 1];

         var one_line_height = element_height / 2;
         var first_line_y = local_y + ((one_line_height - fontheight) / 2);
         var second_line_y = first_line_y + one_line_height;

         var width_at_pos = $.WRITER.getWidthForLine(first_line_y, fontheight);
         dc.setColor(linenum_color, Gfx.COLOR_TRANSPARENT);
         var x_pos = (dc.getWidth() - width_at_pos) / 2;
         if ($.SCREEN_SHAPE == System.SCREEN_SHAPE_SEMI_OCTAGON)
           {
             x_pos = 5;
           }
         dc.drawText(x_pos, first_line_y , FONT, item.get(NearbyStopsDetailsDataProvider.LINE_NUMBER), Gfx.TEXT_JUSTIFY_LEFT);

         var start_time = item.get(NearbyStopsDetailsDataProvider.START_TIME);
         //$.DEBUGGER.println(Lang.format("STARTTIME: $1$, download_done: $2$", [start_time, download_done]));
         var predicted_start_time = item.get(NearbyStopsDetailsDataProvider.PREDICTED_START_TIME);
         var center_time_x = dc.getWidth() / 2;
         if ((i == 0 || i == DISPLAY_ELEMENTS - 1) && $.SCREEN_SHAPE != System.SCREEN_SHAPE_SEMI_OCTAGON)
           {
             center_time_x = center_time_x - 20;
           }
         var time = draw_center_time(dc, center_time_x, first_line_y, FONT, start_time);

         if (predicted_start_time == 0)
           {
             predicted_start_time = start_time;
           }
         time = get_pred_time(predicted_start_time);
         var time_color = get_color_for_time(start_time, predicted_start_time);

         draw_countdown_timer(dc, time, time_color, FONT, first_line_y);

         dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
         width_at_pos = $.WRITER.getWidthForLine(second_line_y, fontheight);
         x_pos = (dc.getWidth() - width_at_pos) / 2;
         if ($.SCREEN_SHAPE == System.SCREEN_SHAPE_SEMI_OCTAGON)
           {
             x_pos = 5;
           }
         dc.drawText(x_pos, second_line_y, FONT, item.get(NearbyStopsDetailsDataProvider.DIRECTION), Gfx.TEXT_JUSTIFY_LEFT);
         dc.drawLine(0, local_y, dc.getWidth(), local_y);
      }
    }
    else
      {
        DISPLAY_ELEMENTS = 2;
        FONT = Gfx.FONT_SYSTEM_TINY;

        var bottom_height = dc.getHeight() * 0.06;
        var element_height = (dc.getHeight() - clock_height - bottom_height) / DISPLAY_ELEMENTS;
        for (var i = 0; i < DISPLAY_ELEMENTS; i++)
          {
            var local_y = clock_height + (i * element_height);

            var item = nearby_stops_details_data_provider.nearby_stops_details_array[current_item + i - 1];

            //var one_line_height = element_height / 2;
            var first_line_y = local_y + (element_height * 0.03);
            var second_line_y = local_y + (element_height * 0.3);

            // 1 - LINE NUMBER
            var x = 5;
            if (i == 0 && $.SCREEN_SHAPE == System.SCREEN_SHAPE_ROUND)
              {
                x = dc.getWidth() * 0.12;
              }
            if (i == 1 && $.SCREEN_SHAPE == System.SCREEN_SHAPE_ROUND)
              {
                x = dc.getWidth() * 0.05;
              }
            var text_area = new Ui.TextArea({
                :text=>item.get(NearbyStopsDetailsDataProvider.LINE_NUMBER),
                :color=>linenum_color2,
                :backgroundColor=>linenum_color,
                :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
                :justification=>Gfx.TEXT_JUSTIFY_LEFT,
                :locX =>x,
                :locY=>first_line_y,
                :width=>dc.getWidth() * 0.27,
                :height=>dc.getHeight() * 0.15
            });
            text_area.draw(dc);

            // 1 - CENTER TIME
            var start_time = item.get(NearbyStopsDetailsDataProvider.START_TIME);
            //$.DEBUGGER.println(Lang.format("STARTTIME: $1$, download_done: $2$", [start_time, download_done]));
            var predicted_start_time = item.get(NearbyStopsDetailsDataProvider.PREDICTED_START_TIME);
            var time_moment = new Time.Moment(start_time.toNumber());
            var time = Gregorian.info(time_moment, Time.FORMAT_SHORT);

            x = dc.getWidth() * 0.4;
            y = first_line_y + 3;
            var width = dc.getWidth() * 0.25;
            if (i == 1)
              {
                width = dc.getWidth() * 0.3;
                y = first_line_y;
              }
            if (i == 0 && $.SCREEN_SHAPE == System.SCREEN_SHAPE_ROUND)
              {
                x = dc.getWidth() * 0.34;
              }
            if (i == 1 && $.SCREEN_SHAPE == System.SCREEN_SHAPE_ROUND)
              {
                x = dc.getWidth() * 0.35;
              }
            text_area = new Ui.TextArea({
                :text=>Lang.format("$1$:$2$", [time.hour.format("%02d"), time.min.format("%02d")]),
                :color=>Gfx.COLOR_BLACK,
                :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
                :justification=>Gfx.TEXT_JUSTIFY_LEFT,
                :locX =>x,
                :locY=>y,
                :width=>width,
                :height=>dc.getHeight() * 0.15
            });
            text_area.draw(dc);

            if (predicted_start_time == 0)
              {
                predicted_start_time = start_time;
              }

           // 1 - COUNTDOWN TIMER
            time = get_pred_time(predicted_start_time);
            var time_color = get_color_for_time(start_time, predicted_start_time);

            x = dc.getWidth() * 0.55;
            if (i == 1 || $.SCREEN_SHAPE != System.SCREEN_SHAPE_ROUND)
              {
                x = dc.getWidth() * 0.63;
              }
            text_area = new Ui.TextArea({
                :text=>time,
                :color=>Gfx.COLOR_WHITE,
                :backgroundColor=>time_color,
                :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
                :justification=>Gfx.TEXT_JUSTIFY_RIGHT,
                :locX =>x,
                :locY=>first_line_y,
                :width=>dc.getWidth() * 0.33,
                :height=>dc.getHeight() * 0.15
            });
            text_area.draw(dc);

            // 2 - DIRECTION
            var locx = dc.getWidth() * 0.05;
            var locy = second_line_y;
            var locwidth = dc.getWidth() * 0.95;
            var locheight = dc.getHeight() * 0.3;
            if (i == 1 && $.SCREEN_SHAPE == System.SCREEN_SHAPE_ROUND)
              {
                locx = dc.getWidth() * 0.1;
                locy = dc.getHeight() * 0.65;
                locwidth = dc.getWidth() * 0.70;                
              }
            text_area = new Ui.TextArea({
                :text=>item.get(NearbyStopsDetailsDataProvider.DIRECTION),
                :color=>Gfx.COLOR_BLACK,
                :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
                :justification=>Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER,
                :locX =>locx,
                :locY=>locy,
                :width=>locwidth,
                :height=>locheight
            });
            text_area.draw(dc);
          }
        draw_arrow(dc, clock_height, bottom_height, element_height);
      }
  }

  private function get_color_for_time(start_time, predicted_start_time)
  {
    if (start_time == predicted_start_time)
      {
        return Gfx.COLOR_DK_GREEN;
      }
    else if (start_time + 30 > predicted_start_time &&
             start_time - 30 < predicted_start_time)
      {
        return Gfx.COLOR_DK_BLUE;
      }

    return Gfx.COLOR_DK_RED;
  }

  private function get_pred_time(pred_start_time)
  {
    var now = new Time.Moment(Time.now().value());
    var pred_start = new Time.Moment(pred_start_time.toNumber());

    var seconds = now.compare(pred_start);

    return format_seconds(seconds);
  }
  
  private function format_seconds(seconds)
  {
     var string = "";

    if (seconds < 0)
      {
        string = "-";
        seconds = seconds * -1;
      }
    else
      {
        string = "+";
      }

    var hour = seconds / 3600;
    var minute = (seconds / 60) % 60;
    var second = seconds % 60;
    if (($.SCREEN_SHAPE == System.SCREEN_SHAPE_SEMI_OCTAGON) or $.NEW_LAYOUT)
      {
        return Lang.format("$1$$2$:$3$", [string, minute.format("%02d"), second.format("%02d")]);
      }
    else 
      {
        return Lang.format("$1$$2$:$3$:$4$", [string, hour.format("%02d"), minute.format("%02d"), second.format("%02d")]);
      }
  }

  public function onShow()
  {
    //$.DEBUGGER.println("onShow");
  }

  public function onHide()
  {
    update_timer.stop();
    progress_lines.stop();
    nearby_stops_details_data_provider.clear_callback();
  }

  public function next()
  {
    if (current_item >= nearby_stops_details_data_provider.nearby_stops_details_array.size() - 1)
      {
        return true;
      }

    current_item++;
    Ui.requestUpdate();

    return true;
  }

  public function prev()
  {
    var first_item = 0;
    if ($.NEW_LAYOUT)
      {
        first_item = 1;
      }

    if (current_item == first_item)
    {
      return true;
    }

    current_item = current_item -1;
    Ui.requestUpdate();

    return true;
  }

  public function back()
  {
    $.DEBUGGER.println("back");
    Ui.popView(Ui.SLIDE_RIGHT);

    return true;
  }

  public function select()
  {
    return true;
  }

  public function on_menu()
  {
    return true;
  }
}