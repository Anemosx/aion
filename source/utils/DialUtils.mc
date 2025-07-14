import Toybox.Graphics;
import Toybox.Math;
import Toybox.System;
import Toybox.Lang;

using $.ThemeColors;
using $.GlobalVariables;

module DialUtils {
    //! Calculates the (x, y) coordinates on a circle for a given angle and radius.
    //! @param angle The angle in degrees.
    //! @param x The x-coordinate of the circle's center.
    //! @param y The y-coordinate of the circle's center.
    //! @param radius The radius of the circle.
    //! @return An array containing the [x, y] coordinates as Numbers.
    function calculateCoords(angle as Float, x as Number, y as Number, radius as Float) as Array<Number> {
        var angleRad = Math.toRadians(angle);
        var xCoord = x + (radius * Math.cos(angleRad));
        var yCoord = y - (radius * Math.sin(angleRad));
        return [xCoord.toNumber(), yCoord.toNumber()];
    }

    //! Applies a radial offset to a given coordinate pair relative to the screen center.
    //! @param x The original x-coordinate.
    //! @param y The original y-coordinate.
    //! @return An array containing the new [x, y] coordinates.
    function getRadialOffsetCoords(x as Number, y as Number) as Array<Number> {
        var centerX = GlobalVariables.gUi[:deviceCenterX] as Number;
        var centerY = GlobalVariables.gUi[:deviceCenterY] as Number;
        var radiusOffset = GlobalVariables.gBurnInRadiusOffset;

        var vecX = x - centerX;
        var vecY = y - centerY;

        var r = Math.sqrt(vecX * vecX + vecY * vecY);
        if (r > 0) {
            var scale = (r + radiusOffset) / r;
            var newX = centerX + vecX * scale;
            var newY = centerY + vecY * scale;
            return [Math.round(newX), Math.round(newY)];
        }
        return [x, y];
    }

    //! This function generates the base coordinates of a watch hand polygon without rotation or translation.
    //! The coordinates are centered at (0,0) and point towards 12 o'clock.
    //! @param handLength The length of the hand.
    //! @param tailLength The length of the tail.
    //! @param width The width of the hand.
    //! @param triangleFactor A factor to control the sharpness of the hand's tip.
    //! @return The array of points for the hand polygon.
    function generateBaseHandCoordinates(handLength as Number, tailLength as Number, width as Float, triangleFactor as Float) as Array<[Float, Float]> {
        var handLengthF = handLength.toFloat();
        var tailLengthF = tailLength.toFloat();
        var triangleFactorF = triangleFactor.toFloat();
        var widthF = width.toFloat();

        return [
            [-(widthF / 2.0), tailLengthF],
            [-(widthF / 2.0), -handLengthF],
            [0.0, -handLengthF * triangleFactorF],
            [widthF / 2.0, -handLengthF],
            [widthF / 2.0, tailLengthF]
        ];
    }

    //! This function takes base coordinates, transforms them (rotate and translate), and fills the resulting polygon.
    //! @param dc The graphics context to draw on.
    //! @param baseCoords The pre-calculated base coordinates of the polygon.
    //! @param angle The rotation angle in radians.
    //! @param centerPtX The X coordinate of the rotation center.
    //! @param centerPtY The Y coordinate of the rotation center.
    //! @param color The color to fill the polygon with.
    function transformAndFillPolygon(dc as Dc, baseCoords as Array<[Float, Float]>, angle as Float, centerPtX as Number, centerPtY as Number, color as ColorType) as Void {
        var result = new Array<[Float, Float]>[5];
        var cosAngle = Math.cos(angle);
        var sinAngle = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 5; i++) {
            var x = (baseCoords[i][0] * cosAngle) - (baseCoords[i][1] * sinAngle);
            var y = (baseCoords[i][0] * sinAngle) + (baseCoords[i][1] * cosAngle);
            result[i] = [centerPtX + x, centerPtY + y];
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(result);
    }

    //! Draws a single hash mark (tick mark) on a dial.
    //! @param dc The graphics context to draw on.
    //! @param angle The angle in radians where the mark should be drawn.
    //! @param centerX The X coordinate of the dial center.
    //! @param centerY The Y coordinate of the dial center.
    //! @param outerRad The outer radius for the hash mark.
    //! @param length The length of the hash mark.
    //! @param penWidth The width of the line.
    //! @param color The color of the hash mark.
    function drawHashMark(dc as Dc, angle as Float, centerX as Numeric, centerY as Numeric, outerRad as Float, length as Float, penWidth as Number, color as ColorType) as Void {
        var cosAngle = Math.cos(angle);
        var sinAngle = Math.sin(angle);

        // Adjust radii to account for pen width, ensuring the drawn line fits within the intended bounds.
        var halfPen = penWidth / 2.0f;
        var adjustedOuterRad = outerRad - halfPen;
        var adjustedInnerRad = outerRad - length + halfPen;

        // To prevent the marker from disappearing or inverting if length is less than penWidth.
        if (adjustedInnerRad > adjustedOuterRad) {
            adjustedInnerRad = adjustedOuterRad;
        }

        var sX = centerX + adjustedInnerRad * sinAngle;
        var sY = centerY - adjustedInnerRad * cosAngle;
        var eX = centerX + adjustedOuterRad * sinAngle;
        var eY = centerY - adjustedOuterRad * cosAngle;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penWidth);
        dc.drawLine(sX, sY, eX, eY);

        // Draw round caps to make the ends look like the arcs
        var capRadius = penWidth / 2.0;
        if (capRadius > 0) {
            dc.fillCircle(sX.toNumber(), sY.toNumber(), capRadius.toNumber());
            dc.fillCircle(eX.toNumber(), eY.toNumber(), capRadius.toNumber());
        }
    }

    //! Draws all tick marks to the given graphics context (DC).
    //! This function is intended to be used for drawing into a buffer.
    //! @param dc The graphics context to draw on.
    //! @param width The width of the display.
    //! @param centerX The X coordinate of the dial center.
    //! @param centerY The Y coordinate of the dial center.
    function drawTicksToDc(dc as Dc, width as Number, centerX as Number, centerY as Number) as Void {
        var accentColor = ThemeColors.hashMarkAccentColor;

        dc.clear();

        // Tick mark properties
        var longTickLength = 25.0;
        var majorPenWidth = 4;

        var outerRadLong = width / 2.1;

        // Draw the tick marks
        for (var i = 0; i < 60; i++) {
            var angle = i * Math.PI / 30.0;
            if (i % 5 == 0) {
                drawHashMark(dc, angle, centerX, centerY, outerRadLong, longTickLength, majorPenWidth, accentColor);
            }
        }
    }

    //! Draws a complete hand (outline, fill, lume) by transforming pre-calculated base coordinates.
    //! This is a helper function.
    //! @param dc The graphics context.
    //! @param angle The rotation angle in radians.
    //! @param centerX The X coordinate of the center.
    //! @param centerY The Y coordinate of the center.
    //! @param outlineCoords Base coordinates for the hand outline.
    //! @param fillCoords Base coordinates for the hand fill.
    //! @param lumeCoords Base coordinates for the hand lume.
    //! @param fillColor Color for the hand fill.
    //! @param lumeColor Color for the hand lume.
    //! @param borderColor Color for the hand border.
    function _drawCompleteHand(dc as Dc, angle as Float, centerX as Number, centerY as Number,
                                       outlineCoords as Array<[Float,Float]> or Null, fillCoords as Array<[Float,Float]> or Null, lumeCoords as Array<[Float,Float]> or Null,
                                       fillColor as ColorType, lumeColor as ColorType, borderColor as ColorType) as Void {

        if (fillCoords != null) {
            transformAndFillPolygon(dc, fillCoords, angle, centerX, centerY, fillColor);
        }
        if (lumeCoords != null) {
            transformAndFillPolygon(dc, lumeCoords, angle, centerX, centerY, lumeColor);
        }
    }

    //! Draws the second hand as a simple line with a tail.
    //! This is a helper function.
    //! @param dc The graphics context.
    //! @param angle The rotation angle in radians for the second hand.
    //! @param centerX The X coordinate of the dial center.
    //! @param centerY The Y coordinate of the dial center.
    //! @param width The width of the display (used for calculating hand length).
    //! @param color The color of the second hand.
    function _drawSecondHand(dc as Dc, angle as Float, centerX as Number, centerY as Number, width as Number, color as ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        var secondHandTipLength = (width / 2.0) * 0.80;
        var secondHandTailLength = (width / 2.0) * 0.15;

        var sinAngle = Math.sin(angle);
        var cosAngle = Math.cos(angle);

        var tipX = centerX + secondHandTipLength * sinAngle;
        var tipY = centerY - secondHandTipLength * cosAngle;

        var tailX = centerX - secondHandTailLength * sinAngle;
        var tailY = centerY + secondHandTailLength * cosAngle;

        dc.drawLine(tailX, tailY, tipX, tipY);
    }

    //! Draws the central arbor of the watch hands, which covers the pivot point.
    //! @param dc The graphics context to draw on.
    //! @param centerX The X coordinate of the dial center.
    //! @param centerY The Y coordinate of the dial center.
    //! @param arborColor The main color of the arbor.
    //! @param handBorderColor The color for the arbor's border.
    function _drawArbor(dc as Dc, centerX as Number, centerY as Number, arborColor as ColorType, handBorderColor as ColorType) as Void {
        if (GlobalVariables.gUi[:visualHourHandWidth] == null) {
            return;
        }
        var visualHourHandWidth = GlobalVariables.gUi[:visualHourHandWidth] as Float;

        // Outer Arbor Ring
        var outerArborOuterRadius = visualHourHandWidth * 1.1;
        var outerArborInnerRadius = outerArborOuterRadius - 3.0;
        if (outerArborInnerRadius < 1.0) { outerArborInnerRadius = 1.0; }

        dc.setColor(ThemeColors.arborOuterColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, outerArborOuterRadius);

        // Inner Arbor
        var arborOuterRadius = visualHourHandWidth * 0.75;
        var arborInnerRadius = arborOuterRadius - 1.0;
        if (arborInnerRadius < 1.0) { arborInnerRadius = 1.0; }

        dc.setColor(arborColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, arborInnerRadius);
    }

    //! Draws the hour, minute, and second hands, plus the central arbor.
    //! @param dc The graphics context.
    //! @param width The width of the display.
    //! @param height The height of the display.
    //! @param centerX The X coordinate of the dial center.
    //! @param centerY The Y coordinate of the dial center.
    //! @param minuteHandColor The color of the minute hand.
    //! @param hourHandColor The color of the hour hand.
    //! @param handBorderColor The border color for both hands.
    //! @param arborColor The color of the central arbor.
    //! @param hourLumeColor The lume color for the hour hand.
    //! @param minuteLumeColor The lume color for the minute hand.
    //! @param secondHandColor The color of the second hand.
    function drawCustomHands(dc as Dc, width as Number, height as Number, centerX as Number, centerY as Number,
                                   minuteHandColor as ColorType, hourHandColor as ColorType, handBorderColor as ColorType, arborColor as ColorType,
                                   hourLumeColor as ColorType, minuteLumeColor as ColorType, secondHandColor as ColorType) as Void {
        var clockTime = System.getClockTime();

        // Quantize seconds to 6-second intervals to make minute/hour hand movements discrete.
        var effectiveSeconds = (Math.floor(clockTime.sec.toFloat() / 6) * 6).toFloat();
        var hourHandAngle = (Math.PI/6.0) * (clockTime.hour.toFloat() + clockTime.min.toFloat()/60.0 + effectiveSeconds/3600.0);
        var minuteHandAngle = (clockTime.min.toFloat() + effectiveSeconds/60.0) * (Math.PI / 30.0);
        var secondHandAngle = clockTime.sec.toFloat() * (Math.PI / 30.0);

        // --- Hour Hand ---
        _drawCompleteHand(dc, hourHandAngle, centerX, centerY,
                          GlobalVariables.gUi[:hourHandOutlineCoords], GlobalVariables.gUi[:hourHandFillCoords], GlobalVariables.gUi[:hourHandLumeCoords],
                          hourHandColor, hourLumeColor, handBorderColor);

        // --- Minute Hand ---
        _drawCompleteHand(dc, minuteHandAngle, centerX, centerY,
                          GlobalVariables.gUi[:minuteHandOutlineCoords], GlobalVariables.gUi[:minuteHandFillCoords], GlobalVariables.gUi[:minuteHandLumeCoords],
                          minuteHandColor, minuteLumeColor, handBorderColor);

        // --- Seconds Hand ---
        if (GlobalVariables.gIsAwake) {
            _drawSecondHand(dc, secondHandAngle, centerX, centerY, width, secondHandColor);
        }

        // --- Arbor ---
        _drawArbor(dc, centerX, centerY, arborColor, handBorderColor);
    }

}
