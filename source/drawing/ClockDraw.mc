import Toybox.Graphics;
import Toybox.Lang;

using $.DialUtils;
using $.GlobalVariables;
using $.ThemeColors;

// This module is responsible for drawing the main clock components,
// including the dial background and the watch hands.
module ClockDraw {

    //! Draws the clock, including the dial and hands.
    //! @param dc The device context (Dc) to draw on.
    function drawClock(dc as Dc) as Void {
        // Draw the pre-rendered dial from the buffer
        if (dc has :drawScaledBitmap && GlobalVariables.gBurnInRadiusOffset == 0) {
            var scaledWidth = GlobalVariables.gUi[:deviceWidth] * 0.995;
            var scaledHeight = GlobalVariables.gUi[:deviceHeight] * 0.995;
            var x = (GlobalVariables.gUi[:deviceWidth] - scaledWidth) / 2;
            var y = (GlobalVariables.gUi[:deviceHeight] - scaledHeight) / 2;
            dc.drawScaledBitmap(x, y, scaledWidth, scaledHeight, GlobalVariables.gUi[:dialBuffer]);
        } else {
            dc.drawBitmap(0, 0, GlobalVariables.gUi[:dialBuffer]);
        }
        DialUtils.drawCustomHands(dc,
            GlobalVariables.gUi[:deviceWidth],
            GlobalVariables.gUi[:deviceHeight],
            GlobalVariables.gUi[:deviceCenterX],
            GlobalVariables.gUi[:deviceCenterY],
            ThemeColors.minuteHandAccentColor,
            ThemeColors.hourHandColor,
            ThemeColors.handBorderColor,
            ThemeColors.arborColor,
            ThemeColors.hourLumeColor,
            ThemeColors.minuteLumeColor,
            ThemeColors.secondHandColor
        );
    }

}
