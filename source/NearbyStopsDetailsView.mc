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

class NearbyStopsDetailsView extends Ui.View
{

  private const FONT = Gfx.FONT_SYSTEM_XTINY;
  private const DISPLAY_ELEMENTS = 4;
  private var current_item = 0;
  private var update_timer = new Timer.Timer();

  private var download_done = false;
  private var error_response_code = null;
  private var progress_lines;
  private var error_draw;
  private var linenum_color;
  private var nearby_stops_details_data_provider;

  public function initialize(stop_id, color, current_item)
  {
    $.DEBUGGER.println(Lang.format("initialize, download_done: $1$", [download_done]));
    progress_lines = new ProgressLines();
    error_draw = new ErrorDraw();
    linenum_color = color;
    nearby_stops_details_data_provider = new NearbyStopsDetailsDataProvider();
    if ($.HAS_PHONE_APP)
      {
        $.COMM.send_get_nearby_stops_details(current_item, method(:on_get_nearby_stops_details));
      }
    else
      {
        nearby_stops_details_data_provider.get_data(stop_id, method(:on_data));
      }

    View.initialize();
  }

  public function on_get_nearby_stops_details(data)
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
        $.WRITER.writeLines(dc, "Downloading RealTime data...", Gfx.FONT_SYSTEM_TINY, dc.getHeight() / 2 - Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY));
        return;
      }
    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
    dc.clear();

    var x = 5;
    var y = 30;
    var fontheight = Gfx.getFontHeight(FONT);
    var element_height = 50;
    if  (nearby_stops_details_data_provider.nearby_stops_details_array.size() == 0)
      {
        $.WRITER.writeLines(dc, "No departures in the near future.", Gfx.FONT_SYSTEM_TINY, dc.getHeight() / 2 - Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY));
        return;
      }

    var now = new Time.Moment(Time.now().value());
    var now_greg = Gregorian.info(now, Time.FORMAT_SHORT);
    dc.setColor( Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK );
    dc.fillRectangle(0, 0, dc.getWidth(), 1 + Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY));
    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY);
    dc.drawText(dc.getWidth() / 2, 0, Gfx.FONT_SYSTEM_TINY, Lang.format("$1$:$2$", [now_greg.hour.format("%02d"), now_greg.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
    for (var i = 0; i < DISPLAY_ELEMENTS; i++)
      {
         var local_y = y + (i * element_height);
         if (i == 0 && current_item == 0)
           {
             dc.fillRectangle(0, 1 + Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY), dc.getWidth(), element_height);
             continue;
           }
         if (current_item + i - 1 > nearby_stops_details_data_provider.nearby_stops_details_array.size() - 1)
           {
             dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
             dc.fillRectangle(0, local_y - element_height + 2 * fontheight, dc.getWidth(), dc.getHeight());
             continue;
           }
         dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );

         var item = nearby_stops_details_data_provider.nearby_stops_details_array[current_item + i - 1];

         var width_at_pos = $.WRITER.getWidthForLine(local_y, fontheight);
         dc.setColor(linenum_color, Gfx.COLOR_TRANSPARENT);
         dc.drawText((dc.getWidth() - width_at_pos) / 2, local_y , FONT, item.get(NearbyStopsDetailsDataProvider.LINE_NUMBER), Gfx.TEXT_JUSTIFY_LEFT);
         dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
         var start_time = item.get(NearbyStopsDetailsDataProvider.START_TIME);
         //$.DEBUGGER.println(Lang.format("STARTTIME: $1$, download_done: $2$", [start_time, download_done]));
         var predicted_start_time = item.get(NearbyStopsDetailsDataProvider.PREDICTED_START_TIME);
         var time_moment = new Time.Moment(start_time.toNumber());
         var time = Gregorian.info(time_moment, Time.FORMAT_SHORT);
         var center_time_x = dc.getWidth() / 2;
         if (i == 0 || i == 3)
           {
             center_time_x = center_time_x - 20;
           }
         dc.drawText(center_time_x, local_y, FONT, Lang.format("$1$:$2$", [time.hour.format("%02d"), time.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);

         if (predicted_start_time == 0)
           {
             predicted_start_time = start_time;
           }
         time = get_pred_time(predicted_start_time);
         width_at_pos = $.WRITER.getWidthForLine(local_y + fontheight, fontheight);
         dc.drawText((dc.getWidth() - width_at_pos) / 2, local_y + fontheight, FONT, item.get(NearbyStopsDetailsDataProvider.DIRECTION), Gfx.TEXT_JUSTIFY_LEFT);
         dc.drawLine(0, local_y + 2 * fontheight, dc.getWidth(), local_y + 2 * fontheight);

         dc.setColor(get_color_for_time(start_time, predicted_start_time), Gfx.COLOR_TRANSPARENT);
         width_at_pos = $.WRITER.getWidthForLine(local_y, fontheight);
         dc.drawText((dc.getWidth() - width_at_pos) / 2 + width_at_pos, local_y, FONT, time, Gfx.TEXT_JUSTIFY_RIGHT);
      }
  }

  private function get_color_for_time(start_time, predicted_start_time)
  {
    if (start_time == predicted_start_time)
      {
        return Gfx.COLOR_BLUE;
      }
    else if (start_time + 30 > predicted_start_time &&
             start_time - 30 < predicted_start_time)
      {
        return Gfx.COLOR_GREEN;
      }

    return Gfx.COLOR_RED;
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

    return Lang.format("$1$$2$:$3$:$4$", [string, hour.format("%02d"), minute.format("%02d"), second.format("%02d")]);
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
    if (current_item == 0)
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