import Toybox.Graphics;
import Toybox.Lang;

using $.GlobalVariables;
using $.ThemeColors;
using $.DialUtils;
using $.DrawingUtils;

//! This module is responsible for drawing all the data fields on the watch face.
//! It includes functions for rendering icons and text for various metrics like
//! battery, date, weather, and activity stats.
module DataDraw {

    //! Draws all data components on the screen.
    //! @param dc The graphics context to draw on.
    function drawData(dc as Dc) as Void {
        drawDndStatus(dc);
        drawRecoveryStatus(dc);
        drawNotificationStatus(dc);
        drawWeatherGroup(dc);
        drawStandardGroup(dc);
    }

    //! Draws the Do Not Disturb (DND) status icon.
    //! @param dc The graphics context to draw on.
    //! @param x The x-coordinate for the icon.
    //! @param y The y-coordinate for the icon.
    function drawDndStatus(dc as Graphics.Dc) as Void {
        var dndCoords = GlobalVariables.gUi[:dndCoords];
        if (dndCoords == null || !GlobalVariables.gIsDndEnabled) {
            return;
        }
        var coords = DialUtils.getRadialOffsetCoords(dndCoords[0], dndCoords[1]);
        DrawingUtils.drawIconById(dc, coords[0], coords[1], :dnd);
    }

    //! Draws the notification status icon based on the notification count.
    //! @param dc The graphics context to draw on.
    //! @param x The x-coordinate for the icon.
    //! @param y The y-coordinate for the icon.
    function drawNotificationStatus(dc as Graphics.Dc) as Void {
        var notificationCoords = GlobalVariables.gUi[:notificationCoords];
        if (notificationCoords == null) {
            return;
        }
        if (GlobalVariables.gNotificationCount <= 0) {
            return;
        }
        var coords = DialUtils.getRadialOffsetCoords(notificationCoords[0], notificationCoords[1]);
        DrawingUtils.drawIconById(dc, coords[0], coords[1], :notification);
    }

    //! Draws the recovery/training readiness status icon.
    //! It shows a specific icon if the time to recovery is zero or less.
    //! @param dc The graphics context to draw on.
    //! @param x The x-coordinate for the icon.
    //! @param y The y-coordinate for the icon.
    function drawRecoveryStatus(dc as Graphics.Dc) as Void {
        var recoveryCoords = GlobalVariables.gUi[:recoveryCoords];
        if (recoveryCoords == null || GlobalVariables.gTimeToRecovery == null || GlobalVariables.gTimeToRecovery > 0) {
            return;
        }
        var coords = DialUtils.getRadialOffsetCoords(recoveryCoords[0], recoveryCoords[1]);
        DrawingUtils.drawIconById(dc, coords[0], coords[1], :train_readiness);
    }

    //! Draws the weather-related data group, including temperature, UV index, moon phase,
    //! weather condition icon, and a precipitation chance bar.
    //! @param dc The graphics context to draw on.
    function drawWeatherGroup(dc as Dc) as Void {
        var coords = GlobalVariables.gUi[:weatherGroupElementCoords];
        if (coords == null || GlobalVariables.gTemperature == null || GlobalVariables.gPrecipitationChance == null) {
            return;
        }

        dc.setColor(ThemeColors.primaryColor, Graphics.COLOR_TRANSPARENT);
        var temperatureString = GlobalVariables.gTemperature.format("%d");

        // Draw top row icons
        DrawingUtils.drawIconById(dc, coords[:uvIconX], coords[:topRowY], GlobalVariables.gUvIndexIconId);
        DrawingUtils.drawIconById(dc, coords[:moonIconX], coords[:topRowY], GlobalVariables.gMoonPhaseIconId);

        // Draw bottom row elements
        dc.drawText(coords[:tempTextX], coords[:bottomRowY], Graphics.FONT_XTINY, temperatureString, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        DrawingUtils.drawIconById(dc, coords[:tempUnitIconX], coords[:bottomRowY], GlobalVariables.gTempUnitIconId);
        DrawingUtils.drawIconById(dc, coords[:weatherIconX], coords[:bottomRowY], GlobalVariables.gWeatherConditionIconId);

        // Draw precipitation bar below the icons
        DrawingUtils.drawPrecipitationBar(dc, coords[:precipBarX], coords[:precipBarY], coords[:precipBarWidth]);
    }

    //! Draws the standard data group, which includes the date and heart rate.
    //! If heart rate is unavailable, the date is centered in the space.
    //! @param dc The graphics context to draw on.
    function drawStandardGroup(dc as Dc) as Void {
        var standardCoords = GlobalVariables.gUi[:standardGroupCoords];
        if (standardCoords == null) {
            return;
        }

        var heartRateString = (GlobalVariables.gHeartRate != null) ? GlobalVariables.gHeartRate.toString() : null;

        dc.setColor(ThemeColors.primaryColor, Graphics.COLOR_TRANSPARENT);

        if (heartRateString == null) {
            // If HR is not available, draw the date centered in the group's original coordinates.
            var coords = DialUtils.getRadialOffsetCoords(standardCoords[0], standardCoords[1]);
            dc.drawText(coords[0], coords[1], Graphics.FONT_TINY, GlobalVariables.gDateString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var elementCoords = GlobalVariables.gUi[:standardGroupElementCoords];

        if (elementCoords == null) {
            return;
        }

        dc.drawText(elementCoords[:dateX], elementCoords[:dateY], Graphics.FONT_TINY, GlobalVariables.gDateString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(GlobalVariables.gHeartRateColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(elementCoords[:heartRateX], elementCoords[:heartRateY], Graphics.FONT_XTINY, heartRateString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
