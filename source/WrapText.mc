// Copyright 2017 by HarryOnline
// https://creativecommons.org/licenses/by/4.0/
//
// Wrap text so lines will fit on the screen

using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.Timer;

class WrapText {

  hidden var screenWidth;
  hidden var screenHeight;
  hidden var screenShape;
  hidden var linePadding = 1;   // Padding between lines
  hidden var sidePadding = 1;   // Padding on the sides of the screen;
  hidden var roundMargin = 15;  // Minimal margin at the top of round screens;
  hidden var rectangleAlignment = Gfx.TEXT_JUSTIFY_LEFT;
  hidden var offset;            // Nr of lines to skip when scrolling
  hidden var skipped = 0;       // Lines skipped
  hidden var scrollDelay = 5000; // Scroll step time in ms
  hidden var scrollStep = 3;     // Number of lines to proceed on scroll
  hidden var timer;
  hidden var overflow = false;

  function initialize() {
    var settings = System.getDeviceSettings();
    screenWidth = settings.screenWidth;
    screenHeight = settings.screenHeight;
    screenShape = settings.screenShape;
    offset = 0;
  }

  // Write the text in lines fit on the screen,
  // return posY for next line
  function writeLines(dc, text, font, posY) {
    if (posY >= screenHeight) {
      return posY;
    }
    // Should have some space above
    if (posY == 0) {
      posY = linePadding;
    }
    // On round screens, needs more space from top, otherwise always zero width
    if( screenShape == System.SCREEN_SHAPE_ROUND && posY < roundMargin ) {
      posY = roundMargin;
    }
    var height = dc.getFontHeight(font);
    var parts = ["", text];
    while( parts.size() == 2 ) {
      var width = getWidthForLine(posY, height);
      // Now calculate how much fits on the line
      parts = lineSplit(dc, parts[1], font, width);
      if( offset <= skipped ) {
        drawText(dc, width, posY, font, parts[0]);
        posY += height + linePadding;
      } else {
        skipped ++;
      }
    }
    return posY;
  }

  function reset() {
    if (timer != null) {
      timer.stop();
      timer = null;
    }
    offset = 0;
  }

  // Check if text fits on screen, if not, start scrolling
  function testFit(posY) {
    overflow = posY > screenHeight;
    if( timer == null && overflow ) {
     timer = new Timer.Timer();
     timer.start(method(:scroll), scrollDelay, true);
    }
    skipped = 0;
  }

  // Splits the text into a part that fits on the line, and the remaining text
  function lineSplit(dc, text, font, width) {
    var os = 0;
    var parts = wordSplit(text, os);
    var count = 0;
    while (parts.size() == 2 && count < 10) {
      var newParts = wordSplit(text, parts[0].length()+1);
      if (dc.getTextWidthInPixels(newParts[0], font) > width ) {
          break;
      }
      count ++;
      parts = newParts;
    }
    return parts;
  }

  // Splits the subject into first word and remaining text (if exists)
  function wordSplit(subject, start) {
    var len = subject.length();
    var substr = subject.substring(start, len);
    var ptr = substr.find(" ");
    return ptr == null ? [subject] : [subject.substring(0, ptr+start), subject.substring( ptr+start+1, len)];
  }

  // Find alignment, draw the text
  function drawText( dc, width, posY, font, text ) {
    if( screenShape != System.SCREEN_SHAPE_RECTANGLE || rectangleAlignment == Gfx.TEXT_JUSTIFY_CENTER ) {
      dc.drawText(screenWidth/2, posY, font, text, Gfx.TEXT_JUSTIFY_CENTER );
    } else if( rectangleAlignment == Gfx.TEXT_JUSTIFY_LEFT ) {
      dc.drawText(screenWidth/2 - width/2, posY, font, text, Gfx.TEXT_JUSTIFY_LEFT );
    } else {
      dc.drawText(screenWidth/2 + width/2, posY, font, text, Gfx.TEXT_JUSTIFY_RIGHT );
    }
  }

  // Return the width for a line at certain Y poistion and with height
  function getWidthForLine(posY, height) {
    // Middle of the line should have some distance from border (sidePadding)
    var avgY = posY + height/2;
    var w1 = getWidthAt(avgY) - 2 * sidePadding;
    // Corner should not get outside visible space
    var upperHalf = avgY < screenHeight/2;
    var cornerY = upperHalf ? posY : posY + height;
    var w2 = getWidthAt(cornerY);
    // Take minimum of both widths
    var width = w1 < w2 ? w1 : w2;
    return width;
  }

  // Return the width at certain Y position
  function getWidthAt(posY) {
    if( screenShape == System.SCREEN_SHAPE_RECTANGLE ) {
      return screenWidth;
    }
    var r = screenWidth / 2;
    var dY = posY - screenHeight/2;

    if( dY.abs() >= r ) {
        return 0;
    }
    var a = Math.asin(dY.toFloat()/r);
    var w = 2 * (r * Math.cos(a));
    return w.toNumber();
  }

  function scroll() {
    if (overflow) {
      offset += scrollStep;
    } else {
      offset = 0;
    }
    Ui.requestUpdate();
  }

  function scrollDown() {
    if (!overflow) {
      return false;
    }
    offset += 3;
    timer.stop();
    timer.start(method(:scroll), scrollDelay, true);
    Ui.requestUpdate();
    return true;
  }

}
