import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;

using $.DialUtils;
using $.GlobalVariables;
using $.ThemeSizing;
using $.DataManager;

//! Manages the initialization of layout-dependent and graphical elements,
//! such as UI coordinates and pre-rendered buffers.
module LayoutManager {
    //! Initializes all layout-dependent settings and pre-renders graphical assets.
    //! @param dc The device context.
    function initialize(dc as Graphics.Dc) as Void {
        initializeDeviceSettings(dc);
        createDialBuffer();
    }

    //! Initializes device-specific dimensions and UI element coordinates.
    //! This sets global variables based on the screen size and should only be called once.
    //! @param dc The device context used to get screen dimensions.
    function initializeDeviceSettings(dc as Graphics.Dc) as Void {
        if (GlobalVariables.gUi[:deviceWidth] == null) {
            GlobalVariables.gHeartRateExpirationDuration = new Time.Duration(DataManager.HEART_RATE_EXPIRATION_SECONDS);
            GlobalVariables.gBodyBatteryExpirationDuration = new Time.Duration(DataManager.BODY_BATTERY_EXPIRATION_SECONDS);
            GlobalVariables.gStressExpirationDuration = new Time.Duration(DataManager.STRESS_EXPIRATION_SECONDS);
            GlobalVariables.gActivityMonitorExpirationDuration = new Time.Duration(DataManager.ACTIVITY_MONITOR_EXPIRATION_SECONDS);
            GlobalVariables.gWeatherExpirationDuration = new Time.Duration(DataManager.WEATHER_EXPIRATION_MINUTES * 60);

            // Store device dimensions
            var width = dc.getWidth();
            var height = dc.getHeight();
            var centerX = width / 2;
            var centerY = height / 2;
            var dataRadius = centerX * 0.6;

            GlobalVariables.gUi[:deviceWidth] = width;
            GlobalVariables.gUi[:deviceHeight] = height;
            GlobalVariables.gUi[:deviceCenterX] = centerX;
            GlobalVariables.gUi[:deviceCenterY] = centerY;
            GlobalVariables.gUi[:dataRadius] = dataRadius;

            // Calculate coordinates for all data fields on the dial
            GlobalVariables.gUi[:dndCoords] = DialUtils.calculateCoords(248.0f, centerX, centerY, dataRadius * 0.9);
            GlobalVariables.gUi[:recoveryCoords] = DialUtils.calculateCoords(270.0f, centerX, centerY, dataRadius * 0.9);
            GlobalVariables.gUi[:notificationCoords] = DialUtils.calculateCoords(292.0f, centerX, centerY, dataRadius * 0.9);
            GlobalVariables.gUi[:weatherGroupCoords] = DialUtils.calculateCoords(180.0f, centerX, centerY, dataRadius * 0.95);
            GlobalVariables.gUi[:standardGroupCoords] = DialUtils.calculateCoords(0.0f, centerX, centerY, dataRadius * 0.64);

            // Pre-calculate common font and text dimensions
            GlobalVariables.gUi[:fontTinyHeight] = dc.getFontHeight(Graphics.FONT_TINY);
            GlobalVariables.gUi[:fontXtinyHeight] = dc.getFontHeight(Graphics.FONT_XTINY);

            var temperatureTextDimensions = dc.getTextDimensions("000", Graphics.FONT_XTINY);
            GlobalVariables.gUi[:temperatureTextWidth] = temperatureTextDimensions[0];
            GlobalVariables.gUi[:temperatureTextHeight] = (temperatureTextDimensions[1] * 1.2).toNumber();

            // Initialize other dynamic visual elements
            initializeHandCoordinates();
        }
    }

    //! Initializes the coordinates for drawing the hour and minute hands.
    //! Calculates coordinates for the outline, fill, and lume parts of the hands
    //! based on screen size and theme settings.
    function initializeHandCoordinates() as Void {
        if (GlobalVariables.gUi[:deviceWidth] == null) { return; }
        var width = GlobalVariables.gUi[:deviceWidth] as Number;
        var screenWidthFloat = width.toFloat();

        // --- Hour Hand ---
        var visualHourHandWidth = ThemeSizing.getVisualHourHandWidth(screenWidthFloat);
        GlobalVariables.gUi[:visualHourHandWidth] = visualHourHandWidth;

        var hourHandOutlineWidth = visualHourHandWidth + (width * ThemeSizing.HAND_OUTLINE_WIDTH_ADDITION_FACTOR);
        var hourLumeWidth = visualHourHandWidth * ThemeSizing.HOUR_LUME_WIDTH_FACTOR;

        GlobalVariables.gUi[:hourHandOutlineCoords] = DialUtils.generateBaseHandCoordinates((width / ThemeSizing.HOUR_HAND_OUTLINE_LENGTH_FACTOR) as Number, 0, hourHandOutlineWidth, ThemeSizing.HOUR_HAND_TRIANGLE_FACTOR);
        GlobalVariables.gUi[:hourHandFillCoords] = DialUtils.generateBaseHandCoordinates((width / ThemeSizing.HOUR_HAND_FILL_LENGTH_FACTOR) as Number, 0, visualHourHandWidth, ThemeSizing.HOUR_HAND_TRIANGLE_FACTOR - 0.01);
        GlobalVariables.gUi[:hourHandLumeCoords] = DialUtils.generateBaseHandCoordinates((width / ThemeSizing.HOUR_HAND_LUME_LENGTH_FACTOR) as Number, 0, hourLumeWidth, ThemeSizing.HOUR_LUME_TRIANGLE_FACTOR);

        // --- Minute Hand ---
        var visualMinuteHandWidth = visualHourHandWidth * ThemeSizing.MINUTE_HAND_WIDTH_FACTOR;
        var minuteHandOutlineWidth = visualMinuteHandWidth + (width * ThemeSizing.HAND_OUTLINE_WIDTH_ADDITION_FACTOR);
        var minuteLumeWidth = visualMinuteHandWidth * ThemeSizing.MINUTE_LUME_WIDTH_FACTOR;

        GlobalVariables.gUi[:minuteHandOutlineCoords] = DialUtils.generateBaseHandCoordinates((width / ThemeSizing.MINUTE_HAND_OUTLINE_LENGTH_FACTOR) as Number, 0, minuteHandOutlineWidth, ThemeSizing.MINUTE_HAND_TRIANGLE_FACTOR);
        GlobalVariables.gUi[:minuteHandFillCoords] = DialUtils.generateBaseHandCoordinates((width / ThemeSizing.MINUTE_HAND_FILL_LENGTH_FACTOR) as Number, 0, visualMinuteHandWidth, ThemeSizing.MINUTE_HAND_TRIANGLE_FACTOR - 0.01);
        GlobalVariables.gUi[:minuteHandLumeCoords] = DialUtils.generateBaseHandCoordinates((width / ThemeSizing.MINUTE_HAND_LUME_LENGTH_FACTOR) as Number, 0, minuteLumeWidth, ThemeSizing.MINUTE_LUME_TRIANGLE_FACTOR);
    }

    //! Creates a buffered bitmap for static dial elements (e.g., ticks).
    //! This optimizes drawing performance by avoiding redrawing static elements in onUpdate.
    function createDialBuffer() as Void {
        if (GlobalVariables.gUi[:deviceWidth] == null) {
            return;
        }
        var width = GlobalVariables.gUi[:deviceWidth] as Number;
        var height = GlobalVariables.gUi[:deviceHeight] as Number;

        var options = {
            :width => width,
            :height => height
        };

        if (Graphics has :createBufferedBitmap) {
            GlobalVariables.gUi[:dialBuffer] = Graphics.createBufferedBitmap(options).get() as Graphics.BufferedBitmap;
            var dc = GlobalVariables.gUi[:dialBuffer].getDc();
            dc.clear();
            DialUtils.drawTicksToDc(dc, width, width/2, height/2);
        } else {
            GlobalVariables.gUi[:dialBuffer] = null;
        }
    }
}
