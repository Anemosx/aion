import Toybox.Graphics;
import Toybox.Lang;

//!
//! This module defines the color palette for the watch face.
//! It centralizes all color definitions to allow for easy theming and consistency across all
//! drawn elements.
//!
module ThemeColors {
    // Clock Hands
    var handBorderColor as Graphics.ColorType        = Graphics.COLOR_BLACK;
    var hourHandColor as Graphics.ColorType          = 0xEAEAEA;
    var minuteHandAccentColor as Graphics.ColorType  = 0xEAEAEA;
    var arborColor as Graphics.ColorType             = Graphics.COLOR_DK_GRAY;
    var arborOuterColor as Graphics.ColorType        = Graphics.COLOR_LT_GRAY;
    var hourLumeColor as Graphics.ColorType          = Graphics.COLOR_LT_GRAY;
    var minuteLumeColor as Graphics.ColorType        = Graphics.COLOR_LT_GRAY;
    var secondHandColor as Graphics.ColorType        = 0xFF5750;

    // Dial
    var hashMarkAccentColor as Graphics.ColorType    = Graphics.COLOR_WHITE;
    var defaultTickColor as Graphics.ColorType       = Graphics.COLOR_DK_GRAY;

    // Data Arcs
    var stressArcColor as Graphics.ColorType         = 0xFF8A80;
    var bodyBatteryArcColor as Graphics.ColorType    = 0x80B3FF;
    var stepsArcColor as Graphics.ColorType          = 0x7EE8FA;
    var activeMinutesArcColor as Graphics.ColorType  = 0x9EFFA1;
    var caloriesArcColor as Graphics.ColorType       = 0xFFD47E;
    var recoveryMarkerColor as Graphics.ColorType    = 0xF6A3D7;

    // Weather
    var precipitationColor as Graphics.ColorType     = 0x80B3FF;
    var unfilledBarColor as Graphics.ColorType       = Graphics.COLOR_DK_GRAY;

    var heartRateColor as Graphics.ColorType         = Graphics.COLOR_WHITE;
    var heartRateZone1Color as Graphics.ColorType    = 0xA5D6A7;
    var heartRateZone2Color as Graphics.ColorType    = 0x80DEEA;
    var heartRateZone3Color as Graphics.ColorType    = 0x81D4FA;
    var heartRateZone4Color as Graphics.ColorType    = 0xB39DDB;
    var heartRateZone5Color as Graphics.ColorType    = 0xFF8A80;

    // Battery
    var batteryLowColor as Graphics.ColorType        = 0xFF8A80;
    var batteryColor as Graphics.ColorType           = 0xEAEAEA;
    var batteryChargingColor as Graphics.ColorType   = 0x80B3FF;

    // UI Elements
    var primaryColor as Graphics.ColorType           = Graphics.COLOR_WHITE;
    var backgroundColor as Graphics.ColorType        = Graphics.COLOR_TRANSPARENT;
}

//!
//! This module defines sizing parameters and scaling factors for UI elements.
//! Using factors instead of hard-coded pixel values allows the watch face to scale
//! gracefully across different screen sizes and resolutions.
//!
module ThemeSizing {
    // Hand Length Factors (division of screen width)
    const HOUR_HAND_OUTLINE_LENGTH_FACTOR as Float = 4.2f;
    const HOUR_HAND_FILL_LENGTH_FACTOR as Float = 4.25f;
    const HOUR_HAND_LUME_LENGTH_FACTOR as Float = 4.4f;
    const MINUTE_HAND_OUTLINE_LENGTH_FACTOR as Float = 2.7f;
    const MINUTE_HAND_FILL_LENGTH_FACTOR as Float = 2.75f;
    const MINUTE_HAND_LUME_LENGTH_FACTOR as Float = 2.8f;

    // Factors for calculating hand coordinates
    const HOUR_HAND_TRIANGLE_FACTOR as Float = 1.09f;
    const HOUR_LUME_TRIANGLE_FACTOR as Float = 1.07f;
    const MINUTE_HAND_TRIANGLE_FACTOR as Float = 1.09f;
    const MINUTE_LUME_TRIANGLE_FACTOR as Float = 1.07f;

    // Factors for calculating hand widths
    const HOUR_LUME_WIDTH_FACTOR as Float = 0.4f;
    const MINUTE_HAND_WIDTH_FACTOR as Float = 0.8f;
    const MINUTE_LUME_WIDTH_FACTOR as Float = 0.3f;
    const HAND_OUTLINE_WIDTH_ADDITION_FACTOR as Float = 0.01f;

    // Polar Drawing dimensions
    const POLAR_ARC_WIDTH as Number = 15;

    //! Determines the base visual width of the hour hand based on screen size.
    //! This function returns a specific width tailored to different device screen resolutions
    //! to ensure the hand proportions are aesthetically pleasing across the product line.
    //! @param screenWidth The width of the device screen in pixels.
    //! @return The calculated width for the hour hand in pixels.
    function getVisualHourHandWidth(screenWidth as Float) as Float {
        // These values are fine-tuned for optimal appearance on specific device screen sizes.
        if (screenWidth == 260.0f) { return 11.0f; }
        if (screenWidth == 240.0f) { return 11.0f; }
        if (screenWidth == 280.0f) { return 11.5f; }
        if (screenWidth <= 218.0f) { return 10.0f; }
        if (screenWidth == 360.0f || screenWidth == 320.0f) { return 13.5f; }
        if (screenWidth >= 390.0f) { return 13.0f; }
        return 11.0f; // Default for other sizes
    }
}
