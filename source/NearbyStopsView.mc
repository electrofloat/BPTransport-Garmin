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

class NearbyStopsView extends Ui.View
{
  private var current_item;

  private const FONT = Gfx.FONT_SYSTEM_XTINY;

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
  private var download_done = false;

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

  private function on_position(info)
  {
    location = info.position.toDegrees();
    $.DEBUGGER.println(location);
    gps_done = true;
    progress_lines.stop();

    if ($.debug)
      {
        /*====== TEST_DATA ====== */
        location[0] = NearbyStopsDataProvider.LAT;
        location[1] = NearbyStopsDataProvider.LON;
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

    nearby_stops_data_provider.get_data(location, method(:on_data));
  }

  private function on_data(response_code)
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
  }

  public function onUpdate(dc)
  {
    dc.setPenWidth(1);

    if (handle_errors(dc))
      {
        return;
      }

    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
    dc.clear();

    var x = 5;
    var y = 0;
    var fontheight = Gfx.getFontHeight(FONT);
    var element_height = 85;

    for (var i = 0; i < 3; i++)
      {
        //$.DEBUGGER.println(i);
        var local_y = y + (i * element_height);
        if (i == 0 && current_item == 0)
          {
            dc.fillRectangle(0, 0, dc.getWidth(), element_height);
            continue;
          }
        if (i == 2 && current_item == nearby_stops_data_provider.nearby_stops_array.size() - 1)
          {
            dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_WHITE );
            dc.fillRectangle(0, local_y - element_height + 3 * fontheight + 10, dc.getWidth(), dc.getHeight());
            continue;
          }
        var text_color;
        if (i == 1)
          {
            dc.setColor( Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK );
            dc.fillRectangle(0, local_y - 9, dc.getWidth(), element_height);
            text_color = Gfx.COLOR_WHITE;
          }
        else
          {
            text_color = Gfx.COLOR_BLACK;
          }

        var item = nearby_stops_data_provider.nearby_stops_array[current_item + i - 1];

        dc.setColor(text_color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, local_y , FONT, item.get(NearbyStopsDataProvider.STOP), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(x, local_y + fontheight , FONT, item.get(NearbyStopsDataProvider.DIRECTION), Gfx.TEXT_JUSTIFY_LEFT);
        var lines_color = item.get(NearbyStopsDataProvider.COLOR);
        if (lines_color == Gfx.COLOR_BLACK)
          {
            lines_color = text_color;
          }
        dc.setColor(lines_color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, local_y + fontheight * 2 , FONT, item.get(NearbyStopsDataProvider.LINES), Gfx.TEXT_JUSTIFY_LEFT);
        dc.setColor(text_color, Gfx.COLOR_TRANSPARENT );
        var distance = Lang.format("$1$m", [Math.round(item.get(NearbyStopsDataProvider.DISTANCE)).format("%d")]);
        dc.drawText(x + dc.getWidth() - 10, local_y + fontheight * 2 , FONT, distance, Gfx.TEXT_JUSTIFY_RIGHT);
        //dc.drawLine(0, local_y + 3 * fontheight + 10, dc.getWidth(), local_y + 3 * fontheight + 10);
      }
}

  private function handle_errors(dc)
  {
    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_BLACK );
    dc.clear();

    if (out_of_zone)
      {
        error_draw.draw(dc, "Out of service zone. Maybe try travelling to Budapest first :)", 50);
        location_provider.stop();
        return true;
      }
    else if (error_response_code != null)
      {
        error_draw.draw(dc, Lang.format("Error downloading data; $1$", [Utils.get_text_for_error_code(error_response_code)]), 50);
        location_provider.stop();
        return true;
      }
    else if (!gps_done)
      {
        progress_lines.draw(dc, Gfx.COLOR_RED, Gfx.COLOR_BLACK, 8);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        $.WRITER.writeLines(dc, "Acquiring GPS Signal...", Gfx.FONT_SYSTEM_TINY, dc.getHeight() / 2 - Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY));
        return true;
      }
    else if (!download_done)
      {
        progress_lines.draw(dc, Gfx.COLOR_BLUE, Gfx.COLOR_BLACK, 8);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        $.WRITER.writeLines(dc, "Downloading RealTime data...", Gfx.FONT_SYSTEM_TINY, dc.getHeight() / 2 - Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY));
        return true;
      }
    return false;
  }

  public function onShow()
  {
    location_provider.start(method(:on_position));
  }

  public function onHide()
  {
    location_provider.stop();
    progress_lines.stop();
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
    var nearby_stops_details_view = new NearbyStopsDetailsView(nearby_stops_data_provider.nearby_stops_array[current_item].get(NearbyStopsDataProvider.STOP_ID),
                                                             nearby_stops_data_provider.nearby_stops_array[current_item].get(NearbyStopsDataProvider.COLOR));

    Ui.pushView(nearby_stops_details_view, new BPTInputDelegate(nearby_stops_details_view), Ui.SLIDE_LEFT);

    return true;
  }

  public function back()
  {
    //System.exit();
    return false;
  }

  public function on_menu()
  {
    return true;
  }
}
