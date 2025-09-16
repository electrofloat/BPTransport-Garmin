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
using Toybox.Attention;

class NearbyStopsView extends Ui.View
{
  private var current_item;

  private var FONT = Gfx.FONT_SYSTEM_XTINY;

  private const LOWER_LEFT_LAT = 47.1523107;
  private const LOWER_LEFT_LON = 18.8460594;
  private const UPPER_RIGHT_LAT = 47.6837053;
  private const UPPER_RIGHT_LON = 19.3915303;

  private var location_provider;
  private var nearby_stops_data_provider;
  private var progress_lines;
  private var error_draw;
  private var location;
  private var gps_done = false;
  private var out_of_zone = false;
  private var error_response_code = null;
  private var first_download_done = false;
  private var download_in_progress = false;
  private var nearby_stops_sent = false;
  
  public function initialize()
  {
    $.DEBUGGER.println("NearbyStopsView::initialize");
    current_item = 0;
    location_provider = new LocationProvider();
    nearby_stops_data_provider = new NearbyStopsDataProvider();
    progress_lines = new ProgressLines();
    error_draw = new ErrorDraw();

    View.initialize();
  }

  public function on_position(info)
  {
    location = info.position.toDegrees();
    $.DEBUGGER.println(location);
    gps_done = true;
    progress_lines.stop();

    if ($.debug)
      {
        //====== TEST_DATA ====== 
        location[0] = NearbyStopsDataProvider.TEST_LAT;
        location[1] = NearbyStopsDataProvider.TEST_LON;
      }

    if (location[0] > UPPER_RIGHT_LAT ||
        location[0] < LOWER_LEFT_LAT ||
        location[1] > UPPER_RIGHT_LON ||
        location[1] < LOWER_LEFT_LON)
      {
        out_of_zone = true;
        Ui.requestUpdate();
        return;
      }
    Ui.requestUpdate();
    if (!download_in_progress)
      {
        download_in_progress = true;
        location_provider.stop();
        nearby_stops_data_provider.get_data(location, method(:on_data));
      }
  }

  public function on_data(response_code)
  {
    download_in_progress = false;
    if (response_code != 200)
      {
        error_response_code = response_code;
        Ui.requestUpdate();
        return;
      }

    if (!first_download_done)
      {
        if (Attention has :vibrate)
          {
             var vibeData =
              [
                new Attention.VibeProfile(100, 700), // On for 0.7 second
              ];
             Attention.vibrate(vibeData);
          }
        first_download_done = true;
      }
    
    progress_lines.stop();
    location_provider.start(method(:on_position));

    Ui.requestUpdate();
  }

  public function on_get_nearby_stops(data)
  {
    if (data.size() == 0 ||
        data[0] != MESSAGE_TYPE_GET_NEARBY_STOPS_REPLY)
      {
        return;
      }
    data = data.slice(1, data.size());
    nearby_stops_data_provider.populate_array_from_online_data(data);
    on_data(200);
  }

  function get_language_reply()
  {
    $.DEBUGGER.println("******get_language_reply invoked");
  }

  private function draw_arrows(dc, top_space, fontheight)
  {
    /*if (top_space + 12 < fontheight)
    {
      FONT = Gfx.FONT_XTINY;
    }*/
    var front_color = Gfx.COLOR_BLACK;
    if ($.SCREEN_SHAPE == System.SCREEN_SHAPE_SEMI_OCTAGON)
      {
        front_color = Gfx.COLOR_WHITE;
      }


    if (current_item < nearby_stops_data_provider.nearby_stops_array.size() - 1)
      {
        dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, dc.getHeight() - top_space, dc.getWidth(), dc.getHeight());
        dc.setColor(front_color, Gfx.COLOR_TRANSPARENT);
        dc.drawText((dc.getWidth() / 2) , dc.getHeight() - top_space - 8 , FONT, "->", Gfx.TEXT_JUSTIFY_CENTER);
      }
    else
      {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, dc.getHeight() - top_space, dc.getWidth(), dc.getHeight());
      }
    dc.setColor(front_color, Gfx.COLOR_TRANSPARENT);
    dc.drawLine(0, dc.getHeight() - top_space, dc.getWidth(), dc.getHeight() - top_space);
    if (current_item > 0)
      {
        dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, dc.getWidth(), top_space);
        dc.setColor(front_color, Gfx.COLOR_TRANSPARENT);
        dc.drawText((dc.getWidth() / 2), - 8, FONT, "<-", Gfx.TEXT_JUSTIFY_CENTER);
      }
    else
      {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, dc.getWidth(), top_space);
      }
    dc.setColor(front_color, Gfx.COLOR_TRANSPARENT);
    dc.drawLine(0, top_space, dc.getWidth(), top_space);
  }

  public function onUpdate(dc)
  {
    //$.DEBUGGER.println(Lang.format("WAIT FOR DATA: $1$, HAS_PHONE_APP: $2$", [$.WAIT_FOR_DATA, $.HAS_PHONE_APP]));
    if (!$.WAIT_FOR_DATA)
      {
        if (!$.HAS_PHONE_APP && !location_provider.is_started())
          {
            //progress_lines.stop();
            location_provider.start(method(:on_position));
          }
        else if ($.HAS_PHONE_APP && !nearby_stops_sent)
          {
            gps_done = true;
            progress_lines.stop();
            $.COMM.send_get_nearby_stops(method(:on_get_nearby_stops));
            nearby_stops_sent = true;
          }
        else if ($.debug && $.FAKE_FUTAR_DATA)
          {
              var my_dict = {
                "stop_color_type" => "BUS",
                "stop_id" => "1",
                "stop_name" => "Blaha Lujzta tér",
                "direction_name" => "Újpalota, Nyírpalota út | Kelenföld vasútállomás",
                "line_numbers" => "8E, 108E, 133E, 907, 907A",
                "distance" => 38
              };
              var data = [MESSAGE_TYPE_GET_NEARBY_STOPS_REPLY];
              for (var i = 0; i < 5; i++)
              {
                data.add(my_dict);
              }
              gps_done = true;
              progress_lines.stop();

              on_get_nearby_stops(data);
          }
      }

    var array_size = nearby_stops_data_provider.nearby_stops_array.size();
    if ((array_size > 0) && (current_item > (nearby_stops_data_provider.nearby_stops_array.size() - 1)))
      {
        current_item = nearby_stops_data_provider.nearby_stops_array.size() - 1;
      }

    dc.setPenWidth(1);

    if (handle_errors(dc))
      {
        return;
      }

    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
    dc.clear();

    var x = 5;
    var y = 0;
    if (!$.NEW_LAYOUT)
      {
        var fontheight = Gfx.getFontHeight(FONT);
        var element_height = dc.getHeight() / 3;

        for (var i = 0; i < 3; i++)
          {
            //$.DEBUGGER.println(i);
            var local_y = y + (i * element_height);
            if (i == 0 && current_item == 0)
              {
                dc.fillRectangle(0, 0, dc.getWidth(), element_height);
                continue;
              }
            if (current_item + i - 1 > nearby_stops_data_provider.nearby_stops_array.size() - 1)
              {
                dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
                dc.fillRectangle(0, local_y, dc.getWidth(), dc.getHeight());
                continue;
              }
            var text_color;
            if (i == 1)
              {
                dc.setColor( Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK );
                dc.fillRectangle(0, local_y, dc.getWidth(), element_height);
                text_color = Gfx.COLOR_WHITE;
              }
            else
              {
                text_color = Gfx.COLOR_BLACK;
              }

            var item = nearby_stops_data_provider.nearby_stops_array[current_item + i - 1];

            var one_line_height = element_height / 3;
            var first_line_y = local_y + ((one_line_height - fontheight) / 2);
            var second_line_y = first_line_y + one_line_height;
            var third_line_y = second_line_y + one_line_height;

            dc.setColor(text_color, Gfx.COLOR_TRANSPARENT);
            if (item.get(NearbyStopsDataProvider.RESOURCE) != null)
              {
                var image = Ui.loadResource(item.get(NearbyStopsDataProvider.RESOURCE));
                dc.drawBitmap(x - 1, first_line_y, image);
              }
            dc.drawText(x + 35, first_line_y, FONT, item.get(NearbyStopsDataProvider.STOP), Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(x, second_line_y, FONT, item.get(NearbyStopsDataProvider.DIRECTION), Gfx.TEXT_JUSTIFY_LEFT);

            var lines_color = item.get(NearbyStopsDataProvider.COLOR);
            if (lines_color == Gfx.COLOR_BLACK)
              {
                lines_color = text_color;
              }
            dc.setColor(lines_color, Gfx.COLOR_TRANSPARENT);
            var distance = Lang.format("$1$m", [Math.round(item.get(NearbyStopsDataProvider.DISTANCE)).format("%d")]);
            var distance_width = dc.getTextWidthInPixels(distance, FONT);
            var lines_text = Gfx.fitTextToArea(item.get(NearbyStopsDataProvider.LINES), FONT, dc.getWidth() - distance_width - x, fontheight, false);

            if (lines_text == null)
              {
                lines_text = Gfx.fitTextToArea(item.get(NearbyStopsDataProvider.LINES), FONT, dc.getWidth() - distance_width - x, fontheight, true);
              }
            dc.drawText(x, third_line_y , FONT, lines_text, Gfx.TEXT_JUSTIFY_LEFT);
            dc.setColor(text_color, Gfx.COLOR_TRANSPARENT );

            dc.drawText(x + dc.getWidth() - 10, third_line_y, FONT, distance, Gfx.TEXT_JUSTIFY_RIGHT);

            //dc.drawLine(0, local_y + 3 * fontheight + 10, dc.getWidth(), local_y + 3 * fontheight + 10);
        }
    }
    else
      {
        FONT = Gfx.FONT_SYSTEM_TINY;
        var fontheight = Gfx.getFontHeight(FONT);
       
        var top_space = dc.getHeight() * 0.06;
        var element_height = dc.getHeight() - (2 * top_space);

        var local_y = y + (top_space);
        var text_color = Gfx.COLOR_WHITE;
    
        dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
        dc.fillRectangle(0, local_y, dc.getWidth(), element_height);
   
        var item = nearby_stops_data_provider.nearby_stops_array[current_item];

        var one_line_height = element_height / 3;
        var first_line_y = local_y;
        var second_line_y = first_line_y + one_line_height;
        var third_line_y = second_line_y + one_line_height;

        dc.setColor(item.get(NearbyStopsDataProvider.COLOR), Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0,first_line_y,dc.getWidth(), one_line_height);

        var text_area = new Ui.TextArea({
            :text=>item.get(NearbyStopsDataProvider.STOP),
            :color=>item.get(NearbyStopsDataProvider.COLOR2),
            :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
            :justification=>Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER,
            :locX =>dc.getWidth() * 0.1,
            :locY=>first_line_y,
            :width=>dc.getWidth() * 0.80,
            :height=>one_line_height
        });
        text_area.draw(dc);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, second_line_y, dc.getWidth(), second_line_y);
             
        var w = $.WRITER.getWidthForLine(second_line_y, fontheight);
        x = (dc.getWidth() - w) / 2;
        text_area = new Ui.TextArea({
            :text=>item.get(NearbyStopsDataProvider.DIRECTION),
            :color=>text_color,
            :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
            :justification=>Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER,
            :locX =>x,
            :locY=>second_line_y,
            :width=>dc.getWidth() * 0.95,
            :height=>one_line_height
        });
        text_area.draw(dc);

        // DRAW 3rd ITEM
        dc.setColor(item.get(NearbyStopsDataProvider.COLOR), Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0,third_line_y,dc.getWidth() * 0.70, one_line_height);

        text_area = new Ui.TextArea({
            :text=>item.get(NearbyStopsDataProvider.LINES),
            :color=>item.get(NearbyStopsDataProvider.COLOR2),
            :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
            :justification=>Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER,
            :locX =>dc.getWidth() * 0.10,
            :locY=>dc.getHeight() * 0.63,
            :width=>(dc.getWidth() * 0.60),
            :height=>one_line_height
        });
        text_area.draw(dc);        
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, third_line_y , dc.getWidth(), third_line_y );
        dc.fillRectangle(dc.getWidth() * 0.70,third_line_y,dc.getWidth(), one_line_height);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        var distance = Lang.format("$1$m", [Math.round(item.get(NearbyStopsDataProvider.DISTANCE)).format("%d")]);
        w = $.WRITER.getWidthForLine(third_line_y, fontheight);
        text_area = new Ui.TextArea({
            :text=>distance,
            :color=>Gfx.COLOR_BLACK,
            :font=>[Gfx.FONT_SYSTEM_LARGE, Gfx.FONT_SYSTEM_MEDIUM, Gfx.FONT_SYSTEM_SMALL, Gfx.FONT_SYSTEM_TINY],
            :justification=>Gfx.TEXT_JUSTIFY_LEFT,
            :locX =>(dc.getWidth() * 0.70) + 5,
            :locY=>third_line_y,
            :width=>dc.getWidth() * 0.22,
            :height=>one_line_height
        });
        text_area.draw(dc);

        draw_arrows(dc, top_space, fontheight);
      }
}

  private function handle_errors(dc)
  {
    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_BLACK );
    dc.clear();

    if ($.WAIT_FOR_DATA)
      {
        progress_lines.draw(dc, Gfx.COLOR_BLUE, Gfx.COLOR_BLACK, 8);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        $.WRITER.writeLines(dc, "Checking for companion app...", Gfx.FONT_SYSTEM_TINY, dc.getHeight() / 2 - Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY));
        return true;
      }
    else if (out_of_zone)
      {
        error_draw.draw(dc, "Out of service zone. Maybe try travelling to Budapest first?", 50);
        location_provider.stop();
        progress_lines.stop();
        return true;
      }
    else if (error_response_code != null)
      {
        error_draw.draw(dc, Lang.format("Error downloading data; $1$", [Utils.get_text_for_error_code(error_response_code)]), 50);
        location_provider.stop();
        progress_lines.stop();
        return true;
      }
    else if (!gps_done)
      {
        progress_lines.draw(dc, Gfx.COLOR_RED, Gfx.COLOR_BLACK, 8);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

        var text_area = new Ui.TextArea({
            :text=>"Acquiring GPS Signal...",
            :color=>Gfx.COLOR_WHITE,
            :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_SYSTEM_TINY, Gfx.FONT_SYSTEM_XTINY],
            :justification=>Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER,
            :locX =>Ui.LAYOUT_HALIGN_CENTER,
            :locY=>Ui.LAYOUT_VALIGN_CENTER,
            :width=>dc.getWidth() * 0.8,
            :height=>dc.getHeight() * 0.7
        });

        text_area.draw(dc);
        return true;
      }
    else if (!first_download_done)
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
        return true;
      }
    else if (nearby_stops_data_provider.nearby_stops_array.size() == 0)
      {
        error_draw.draw(dc, "There are no nearby stops. Try increasing the search radius.", 50);
        location_provider.stop();
        progress_lines.stop();
        return true;
      }
    return false;
  }

  public function onShow()
  {
    nearby_stops_sent = false;
    if (!$.WAIT_FOR_DATA && !$.HAS_PHONE_APP && !location_provider.is_started())
      {
        location_provider.start(method(:on_position));
      }
  }

  public function onHide()
  {
    location_provider.stop();
    progress_lines.stop();
    nearby_stops_data_provider.clear_callback();
  }

  public function next()
  {
    if (current_item >= nearby_stops_data_provider.nearby_stops_array.size() - 1)
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

  public function select()
  {
    if (nearby_stops_data_provider.nearby_stops_array.size() == 0)
      {
        return false;
      }
    var nearby_stops_details_view = new NearbyStopsDetailsView(nearby_stops_data_provider.nearby_stops_array[current_item].get(NearbyStopsDataProvider.STOP_ID),
                                                             nearby_stops_data_provider.nearby_stops_array[current_item].get(NearbyStopsDataProvider.COLOR), nearby_stops_data_provider.nearby_stops_array[current_item].get(NearbyStopsDataProvider.COLOR2), current_item);

    nearby_stops_data_provider.clear_callback();
    Ui.pushView(nearby_stops_details_view, new BPTInputDelegate(nearby_stops_details_view), Ui.SLIDE_LEFT);

    return true;
  }

  public function back()
  {
    //System.exit();
    if (nearby_stops_sent)
      {
        $.COMM.send_exit();
      }
    if (location_provider.is_started())
      {
        location_provider.stop();
      }
      
    return false;
  }

  public function on_menu()
  {
    return true;
  }
}
