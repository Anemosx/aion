import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Math;
import Toybox.WatchUi;

using $.ThemeColors;
using $.AionIcons;
using $.GlobalVariables;

//! This module provides a collection of generic utility functions for drawing UI elements,
//! such as text with icons, arcs, gradients, and handling icon spritesheets.
module DrawingUtils {
    // A configurable options dictionary for drawing functions
    typedef DrawOptions as {
        :font as Graphics.FontType,
        :fontColor as Graphics.ColorType,
        :iconTextGap as Number,
        :percentIconGap as Number,
        :percentIconYOffset as Number,
        :percentIconXOffset as Number,
        :textYOffset as Number
    };

    // Default options to avoid passing a full dictionary for every call
    var defaultOptions as DrawOptions = {
        :font => Graphics.FONT_XTINY,
        :fontColor => ThemeColors.primaryColor,
        :iconTextGap => 4,
        :percentIconGap => -12,
        :percentIconYOffset => 3,
        :percentIconXOffset => 0,
        :textYOffset => 0
    };

    //! Draws a circular arc representing a percentage value, starting from the 12 o'clock position
    //! and progressing clockwise. The arc features a color gradient and a rounded end cap.
    //! @param dc The graphics context.
    //! @param percentage The percentage (0-100) to visualize. The arc is not drawn for null or < 0 values.
    //! @param radius The radius of the arc.
    //! @param arcColor The target color of the arc's gradient and end cap.
    //! @param penWidth The thickness of the arc.
    function drawPercentageArc(dc as Graphics.Dc, percentage as Lang.Number or Null, radius as Lang.Number, arcColor as Graphics.ColorType, penWidth as Lang.Number or Null) as Void {
        if (percentage == null || penWidth == null) {
            return;
        }
        if (GlobalVariables.gUi[:deviceCenterX] == null || GlobalVariables.gUi[:deviceCenterY] == null) { return; }

        var percentageFloat = percentage.toFloat();
        if (percentageFloat < 0) {
            return;
        } else if (percentageFloat > 100) {
            percentageFloat = 100.0f;
        }

        var centerX = GlobalVariables.gUi[:deviceCenterX] as Number;
        var centerY = GlobalVariables.gUi[:deviceCenterY] as Number;
        var finalRadius = radius + GlobalVariables.gBurnInRadiusOffset;

        // --- Draw the arc for percentages greater than 0 ---
        if (percentageFloat > 0) {
            dc.setPenWidth(penWidth);

            // --- Define gradient and solid portions ---
            var gradientPercentage = percentageFloat;
            var startOfGradient = 0;

            // --- Draw Gradient Arc ---
            // Dynamically calculate the number of steps for the gradient.
            // More steps are used for larger arcs to ensure smoothness, while fewer steps
            // are used for smaller arcs to optimize performance. The multiplier is an empirical
            // formula to balance visual quality and drawing cost.
            var percentageRatio = gradientPercentage / 100.0f;
            var multiplier = 3.2f - (2.0f * percentageRatio);
            var numStepsFloat = gradientPercentage * multiplier;

            var numSteps = numStepsFloat.toNumber();

            var stepSize = gradientPercentage / numSteps.toFloat();
            var backgroundColor = Graphics.COLOR_BLACK;

            for (var i = 0; i < numSteps; i++) {
                var p1 = startOfGradient + (i * stepSize);
                var p2 = startOfGradient + ((i + 1) * stepSize);

                var p2_overlap = p2 + 1f;
                if (p2_overlap > percentageFloat) {
                    p2_overlap = percentageFloat;
                }

                var ratio = (p1 - startOfGradient) / gradientPercentage;
                if (ratio > 1.0f) { ratio = 1.0f; }
                if (ratio < 0.0f) { ratio = 0.0f; }

                var segmentColor = lerpColorNonLinear(backgroundColor, arcColor, ratio);
                dc.setColor(segmentColor, Graphics.COLOR_TRANSPARENT);

                var startAngle = 270.0f - (p1 / 100.0f) * 360.0f;
                var endAngle = 270.0f - (p2_overlap / 100.0f) * 360.0f;
                dc.drawArc(centerX, centerY, finalRadius, Graphics.ARC_CLOCKWISE, startAngle, endAngle);
            }
        }

        // --- Draw a rounded cap at the end of the arc ---
        var capRadius = penWidth.toFloat() / 1.8f;
        if (capRadius > 0) {
            dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
            var endAngleRad = Math.toRadians(270.0f - (percentageFloat / 100.0f) * 360.0f);

            var adjustedRadius = finalRadius + (penWidth / 2.0f) - capRadius;

            var endX = centerX + (adjustedRadius * Math.cos(endAngleRad));
            var endY = centerY - (adjustedRadius * Math.sin(endAngleRad));
            dc.fillCircle(endX.toNumber(), endY.toNumber(), capRadius.toNumber());
        }
    }

    //! Draws a circular arc that is horizontally balanced around the 6 o'clock position.
    //! For example, a 25% arc would extend from the 7:30 position to the 4:30 position on a clock face.
    //! Includes rounded caps at both ends of the arc.
    //! @param dc The graphics context.
    //! @param percentage The percentage (0-100) that determines the sweep angle of the arc.
    //! @param radius The radius of the arc.
    //! @param arcColor The color of the arc and its caps.
    //! @param penWidth The thickness of the arc.
    function drawBottomBalancedArc(dc as Graphics.Dc, percentage as Lang.Number or Null, radius as Lang.Number, arcColor as Graphics.ColorType, penWidth as Lang.Number or Null) as Void {
        if (percentage == null || penWidth == null || GlobalVariables.gUi[:deviceCenterX] == null || GlobalVariables.gUi[:deviceCenterY] == null) { return; }

        var percentageFloat = percentage.toFloat();
        if (percentageFloat < 0) { percentageFloat = 0.0f; }
        else if (percentageFloat > 100) { percentageFloat = 100.0f; }

        var centerX = GlobalVariables.gUi[:deviceCenterX] as Number;
        var centerY = GlobalVariables.gUi[:deviceCenterY] as Number;
        var finalRadius = radius + GlobalVariables.gBurnInRadiusOffset;

        dc.setPenWidth(penWidth);
        dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);

        var sweepAngle = (percentageFloat / 100.0f) * 360.0f;

        if (sweepAngle >= 360.0f) {
            // Draw a full circle if percentage is 100 or more
            dc.drawArc(centerX, centerY, finalRadius, Graphics.ARC_CLOCKWISE, 270, 270);
            return;
        }

        var centerAngle = 270; // 6 o'clock position
        var halfSweep = sweepAngle / 2.0;
        var startAngle = centerAngle + halfSweep;
        var endAngle = centerAngle - halfSweep;

        dc.drawArc(centerX, centerY, finalRadius, Graphics.ARC_CLOCKWISE, startAngle, endAngle);

        // Draw rounded caps at the start and end of the arc
        var capRadius = penWidth.toFloat() / 2.0f;
        if (capRadius > 0) {
            var startAngleRad = Math.toRadians(startAngle);
            var startX = centerX + (finalRadius * Math.cos(startAngleRad));
            var startY = centerY - (finalRadius * Math.sin(startAngleRad));
            dc.fillCircle(startX.toNumber(), startY.toNumber(), capRadius.toNumber());

            var endAngleRad = Math.toRadians(endAngle);
            var endX = centerX + (finalRadius * Math.cos(endAngleRad));
            var endY = centerY - (finalRadius * Math.sin(endAngleRad));
            dc.fillCircle(endX.toNumber(), endY.toNumber(), capRadius.toNumber());
        }
    }

    //! Linearly interpolates between two colors with a non-linear easing function.
    //! The interpolation is heavily weighted towards the beginning, with the first 33% of the ratio
    //! accounting for approximately 66% of the color transition.
    //! @param pFrom The starting color.
    //! @param pTo The ending color.
    //! @param pRatio The interpolation ratio (0.0 to 1.0).
    //! @return The interpolated color.
    function lerpColorNonLinear(pFrom as Graphics.ColorType, pTo as Graphics.ColorType, pRatio as Float) as Graphics.ColorType {
        var easedRatio = Math.pow(pRatio, 1.5f);
        if (easedRatio > 1.0f) {
            easedRatio = 1.0f;
        } else if (easedRatio < 0.0f) {
            easedRatio = 0.0f;
        }

        var ar = (pFrom & 0xFF0000) >> 16;
        var ag = (pFrom & 0x00FF00) >> 8;
        var ab = (pFrom & 0x0000FF);

        var br = (pTo & 0xFF0000) >> 16;
        var bg = (pTo & 0x00FF00) >> 8;
        var bb = (pTo & 0x0000FF);

        var rr = (ar + easedRatio * (br - ar)).toNumber();
        var rg = (ag + easedRatio * (bg - ag)).toNumber();
        var rb = (ab + easedRatio * (bb - ab)).toNumber();

        return (rr << 16) + (rg << 8) + (rb | 0);
    }

    //! Draws a horizontal bar to represent the chance of precipitation.
    //! The bar is filled with blue according to the percentage, and the remainder is gray.
    //! @param dc The graphics context.
    //! @param startX The starting x-coordinate of the bar.
    //! @param barY The y-coordinate of the center of the bar.
    //! @param width The total width of the bar.
    function drawPrecipitationBar(dc as Graphics.Dc, startX as Number, barY as Number, width as Number) as Void {
        var precipChance = GlobalVariables.gPrecipitationChance;
        if (precipChance == null) { return; }

        var barHeight = 4;
        var precipPercentage = precipChance.toFloat() / 100.0f;
        if (precipPercentage < 0) { precipPercentage = 0.0f; }
        else if (precipPercentage > 1) { precipPercentage = 1.0f; }

        var filledWidth = (width * precipPercentage).toNumber();

        dc.setColor(ThemeColors.precipitationColor, Graphics.COLOR_TRANSPARENT);
        if (filledWidth > 0) {
            dc.fillRectangle(startX, barY - barHeight / 2, filledWidth, barHeight);
        }

        var unfilledWidth = width - filledWidth;
        if (unfilledWidth > 0) {
            dc.setColor(ThemeColors.unfilledBarColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(startX + filledWidth, barY, unfilledWidth, 2);
        }
    }

    //! Draws a single icon from the global icon spritesheet, identified by its ID.
    //! The icon is clipped from the main bitmap and drawn centered at the specified (x, y) coordinates.
    //! @param dc The graphics context to draw on.
    //! @param x The center x-coordinate where the icon should be drawn.
    //! @param y The center y-coordinate where the icon should be drawn.
    //! @param iconId The symbol or ID of the icon to draw.
    //! @return A dictionary containing the icon's metadata (width, height, etc.) or null if not found.
    function drawIconById(dc as Graphics.Dc, x as Number, y as Number, iconId as Symbol or Number or Null) as Dictionary<String, Number> or Null {
        var iconData = AionIcons.getIcon(iconId);

        if (iconData != null) {
            var snipX = iconData["x"];
            var snipY = iconData["y"];
            var snipWidth = iconData["width"];
            var snipHeight = iconData["height"];

            // Ensure all snippet data is available before drawing
            if (snipX != null && snipY != null && snipWidth != null && snipHeight != null) {
                // The snippet is drawn centered on (x, y).
                // Calculate the top-left screen coordinates for the snippet.
                var snippetDrawX = x - (snipWidth / 2);
                var snippetDrawY = y - (snipHeight / 2);

                // To draw the snippet from the source bitmap, we position the entire bitmap
                // such that the snippet's top-left corner aligns with its draw position.
                var bitmapDrawX = snippetDrawX - snipX;
                var bitmapDrawY = snippetDrawY - snipY;

                // Set a clipping region to ensure only the snippet is drawn.
                dc.setClip(snippetDrawX, snippetDrawY, snipWidth, snipHeight);

                // Draw the full bitmap; only the clipped region will be visible.
                var iconBuffer = AionIcons.getIconBitmap();
                if (iconBuffer != null) {
                    dc.drawBitmap(bitmapDrawX, bitmapDrawY, iconBuffer);
                } else {
                    // Fallback for older devices that don't support BufferedBitmap.
                    var iconDrawable = new WatchUi.Bitmap({
                        :rezId => Rez.Drawables.icons,
                        :locX => bitmapDrawX,
                        :locY => bitmapDrawY,
                    });
                    iconDrawable.draw(dc);
                }

                // Clear the clipping region to not affect subsequent drawing operations.
                dc.clearClip();
            }
            return iconData;
        }
        return null;
    }
}
