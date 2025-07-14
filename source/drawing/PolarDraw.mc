import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

import Toybox.Math;

using $.DrawingUtils;
using $.GlobalVariables;
using $.ThemeColors;
using $.DialUtils;

//! This module is responsible for drawing the polar area of the watch face,
//! which includes data arcs and recovery time markers.
module PolarDraw {

    //! Draws the concentric data arcs on the watch face.
    //! The arcs are drawn from the outside in, based on the gSortedPolarArcs array.
    //! @param dc The graphics context to draw on.
    function drawData(dc as Graphics.Dc) as Void {

        var sortedArcs = GlobalVariables.gSortedPolarArcs as Array<Dictionary<Symbol, Number or Graphics.ColorType>> or Null;

        if (sortedArcs == null || sortedArcs.size() == 0) {
            return;
        }

        // Calculate the radius for the outermost arc, centered within its width.
        var arcRadiusFloat = (GlobalVariables.gUi[:deviceCenterX] as Number) - ((GlobalVariables.gUi[:polarArcWidth] as Number) / 2.0);
        var initialRadius = arcRadiusFloat.toNumber();

        // Draw each arc, moving inwards.
        for (var i = 0; i < sortedArcs.size(); i++) {
            var arcData = sortedArcs[i] as Dictionary<Symbol, Number or Graphics.ColorType>;
            // Each subsequent arc is drawn inside the previous one.
            var currentRadius = initialRadius - (i * (GlobalVariables.gUi[:polarArcWidth] as Number));

            DrawingUtils.drawPercentageArc(
                dc,
                arcData[:percentage] as Number,
                currentRadius,
                arcData[:color] as Graphics.ColorType,
                GlobalVariables.gUi[:polarArcWidth] as Number
            );
        }
    }

    //! Draws the battery level as a small arc at the top of the watch face,
    //! inside the main clock hands area. The color and fill reflect the
    //! current charge status (e.g., charging, low battery).
    //! @param dc The graphics context to draw on.
    function drawBattery(dc as Graphics.Dc) as Void {
        var batteryLevel = GlobalVariables.gBatteryLevel;
        if (batteryLevel == null || batteryLevel < 0) {
            return;
        }

        var visualHourHandWidth = GlobalVariables.gUi[:visualHourHandWidth];
        if (visualHourHandWidth == null) {
            return;
        }

        var batteryArcRadius = visualHourHandWidth * 0.82;
        var batteryArcWidth = 4;

        var displayPercentage = batteryLevel;
        var batteryColor;

        if (GlobalVariables.gIsCharging) {
            displayPercentage = 100;
            batteryColor = ThemeColors.batteryChargingColor;
        } else if (batteryLevel < 15) {
            batteryColor = ThemeColors.batteryLowColor;
        } else {
            batteryColor = ThemeColors.batteryColor;
        }

        DrawingUtils.drawBottomBalancedArc(
            dc,
            displayPercentage,
            batteryArcRadius.toNumber(),
            batteryColor,
            batteryArcWidth
        );
    }

    //! Draws a marker on the clock dial indicating the time when the user will be fully recovered.
    //! The marker is only shown if the recovery time is between 1 and 11 hours.
    //! The position is rounded up to the next full hour.
    //! @param dc The graphics context to draw on.
    function drawRecoveryMarker(dc as Graphics.Dc) as Void {
        var timeToRecovery = GlobalVariables.gTimeToRecovery; // In hours

        // Only draw the recovery marker if the time to recovery is between 1 and 11 hours.
        if (timeToRecovery == null || timeToRecovery <= 0 || timeToRecovery > 11) {
            return;
        }

        var recoveryDuration = new Time.Duration((timeToRecovery as Lang.Number) * 3600);
        var recoveryMoment = Time.now().add(recoveryDuration);

        // Round the recovery time up to the next full hour to align the marker with hour marks.
        // For example, if recovery is at 3:15, the marker will point to 4:00.
        var momentInfo = Gregorian.info(recoveryMoment, Time.FORMAT_SHORT);
        if (momentInfo.min > 0 || momentInfo.sec > 0) {
            var secondsUntilNextHour = 3600 - (momentInfo.min * 60 + momentInfo.sec);
            recoveryMoment = recoveryMoment.add(new Time.Duration(secondsUntilNextHour));
        }

        var centerX = GlobalVariables.gUi[:deviceCenterX] as Float;
        var centerY = GlobalVariables.gUi[:deviceCenterY] as Float;

        // Convert time to a position on a 12-hour clock dial
        var recoveryInfo = Gregorian.info(recoveryMoment, Time.FORMAT_SHORT);
        var hourIn12hCycle = recoveryInfo.hour % 12;
        var minutesIn12hCycle = hourIn12hCycle * 60 + recoveryInfo.min;
        var totalMinutesIn12hPeriod = 12 * 60;
        var percentage = (minutesIn12hCycle.toFloat() / totalMinutesIn12hPeriod.toFloat());

        // We need "Clock Angle": 0 at 12 o'clock, increases clockwise.
        var clockAngleRadians = percentage * 2.0 * Math.PI;

        // Use styling from drawTicksToDc to match clock hash marks
        var markColor = ThemeColors.recoveryMarkerColor;
        var markerLength = 28.0f;
        var markerPenWidth = 6;
        var outerRad = (GlobalVariables.gUi[:deviceWidth] as Number) / 2.1f;

        var finalMarkerLength = markerLength - (GlobalVariables.gBurnInRadiusOffset as Number);

        DialUtils.drawHashMark(
            dc,
            clockAngleRadians,
            centerX,
            centerY,
            outerRad,
            finalMarkerLength,
            markerPenWidth,
            markColor
        );
    }
}
