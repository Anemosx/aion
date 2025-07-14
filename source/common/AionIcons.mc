import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;
import Toybox.Math;

//! Manages icons for the watch face.
//! Icons are loaded from a spritesheet, and their coordinates are defined in JSON resources.
module AionIcons {
    //! The buffered bitmap for the icon spritesheet.
    var gIconBitmap as Graphics.BufferedBitmap or Graphics.BufferedBitmapReference or Null;
    //! A dictionary mapping icon symbols to their coordinate properties (x, y, width, height).
    var gIconData as Dictionary<Symbol, Dictionary<String, Number> or Null> or Null;

    // --- Icon Calculation Constants ---
    const JD_EPOCH_OFFSET as Float = 2440587.5f; // Julian Day for 1970-01-01
    // A known new moon epoch for reference in calculations.
    const JD_NEW_MOON_EPOCH as Float = 2451550.1f;
    // The synodic period of the Moon.
    const SYNODIC_MONTH_LENGTH as Float = 29.530588853f;
    const UV_INDEX_ICONS as Array<Symbol> = [
        :uv_index_0, :uv_index_1, :uv_index_2, :uv_index_3, :uv_index_4,
        :uv_index_5, :uv_index_6, :uv_index_7, :uv_index_8, :uv_index_9, :uv_index_10
    ];

    //! Loads the icon spritesheet and metadata. Should be called once on app initialization.
    function loadIcons() as Void {
        if (gIconBitmap == null && (Graphics has :createBufferedBitmap)) {
            gIconBitmap = Graphics.createBufferedBitmap({
                :bitmapResource => WatchUi.loadResource(Rez.Drawables.icons)
            });
        }

        if (gIconData == null) {
            gIconData = {};
            _loadIconData();
        }
    }

    //! Releases icon resources. Should be called from onHide() to free memory.
    function releaseIcons() as Void {
        gIconBitmap = null;
        gIconData = null;
    }

    //! Returns the buffered bitmap of the icon spritesheet.
    function getIconBitmap() as Graphics.BufferedBitmap or Graphics.BufferedBitmapReference or Null {
        return gIconBitmap;
    }

    //! Retrieves the properties for a specific icon.
    //! @param id The symbol identifier for the icon.
    //! @return A dictionary of properties (x, y, width, height), or null if not found.
    function getIcon(id as Symbol or Number or Null) as Dictionary<String, Number> or Null {
        if (gIconData == null) {
            return null;
        }

        return gIconData.get(id);
    }

    //! Gets the temperature unit icon ID based on device settings.
    function getTempUnitIconId(temperatureUnits as System.UnitsSystem) as Symbol {
        if (temperatureUnits == System.UNIT_STATUTE) {
            return :fahrenheit;
        } else {
            return :celsius;
        }
    }

    //! Calculates the moon phase icon ID for a given moment in time.
    function getMoonPhaseIconId(now as Time.Moment) as Symbol {
        // Convert the current time to a Julian Day number.
        var JD = now.value().toFloat() / Gregorian.SECONDS_PER_DAY.toFloat() + JD_EPOCH_OFFSET;

        // Normalize the Julian Day against a known new moon epoch to determine the moon's age.
        var valToNormalize = (JD - JD_NEW_MOON_EPOCH) / SYNODIC_MONTH_LENGTH;
        // The fractional part of the result represents the current phase in the lunar cycle.
        var IP = valToNormalize - Math.floor(valToNormalize);
        if (IP < 0) {
            IP = IP + 1;
        }

        var age = IP * SYNODIC_MONTH_LENGTH;

        if (age < 1.84566f) {
            return :moon_phase_new_moon;
        } else if (age < 5.53699f) {
            return :moon_phase_waxing_crescent;
        } else if (age < 9.22831f) {
            return :moon_phase_first_quarter;
        } else if (age < 12.91963f) {
            return :moon_phase_waxing_gibbous;
        } else if (age < 16.61096f) {
            return :moon_phase_full_moon;
        } else if (age < 20.30228f) {
            return :moon_phase_waning_gibbous;
        } else if (age < 23.99361f) {
            return :moon_phase_last_quarter;
        } else if (age < 27.68493f) {
            return :moon_phase_waning_crescent;
        } else {
            return :moon_phase_new_moon;
        }
    }

    //! Gets the UV Index icon ID from the UV index value.
    function getUvIndexIconId(uvIndex as Number or Null) as Symbol {
        if (uvIndex == null || uvIndex < 0 || uvIndex >= UV_INDEX_ICONS.size()) {
            return :uv_index_undefined;
        }
        return UV_INDEX_ICONS[uvIndex as Number];
    }

    //! Maps a weather condition enum to a corresponding icon symbol.
    //! @param condition The current weather condition from `Toybox.Weather.Condition`.
    //! @param isDay True if it is daytime to select day/night specific icons.
    function mapConditionToIconId(condition as Weather.Condition or Null, isDay as Boolean) as Symbol {
        if (condition == null) {
            return :weather_undefined;
        }

        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_MOSTLY_CLEAR:
            case Weather.CONDITION_FAIR:
                return isDay ? :sunny : :clear_night;

            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_THIN_CLOUDS:
                return isDay ? :partly_cloudy : :partly_cloudy_night;

            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
                return :cloudy;

            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_LIGHT_SHOWERS:
                return isDay ? :partly_cloudy_rain : :partly_cloudy_rain_night;

            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_DRIZZLE:
                return :rainy;

            case Weather.CONDITION_SCATTERED_SHOWERS:
                return :partly_cloudy_rain;

            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
            case Weather.CONDITION_FLURRIES:
                return :snowy;

            case Weather.CONDITION_WINDY:
            case Weather.CONDITION_DUST:
            case Weather.CONDITION_SAND:
            case Weather.CONDITION_SANDSTORM:
            case Weather.CONDITION_HURRICANE:
                return :windy;

            case Weather.CONDITION_TORNADO:
            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
                return :thunder;

            case Weather.CONDITION_WINTRY_MIX:
            case Weather.CONDITION_HAIL:
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Weather.CONDITION_RAIN_SNOW:
            case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_FREEZING_RAIN:
            case Weather.CONDITION_SLEET:
            case Weather.CONDITION_ICE_SNOW:
            case Weather.CONDITION_ICE:
                return :sleet;

            case Weather.CONDITION_FOG:
            case Weather.CONDITION_HAZY:
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_SMOKE:
            case Weather.CONDITION_VOLCANIC_ASH:
            case Weather.CONDITION_HAZE:
                return :foggy;

            case Weather.CONDITION_SQUALL:
            case Weather.CONDITION_TROPICAL_STORM:
                return :windy_rain;

            case Weather.CONDITION_UNKNOWN_PRECIPITATION:
            case Weather.CONDITION_UNKNOWN:
            default:
                return :weather_undefined;
        }
    }

    //! Loads and registers all icon metadata from JSON resources.
    function _loadIconData() as Void {
        // Moon Phase Icons
        gIconData.put(:moon_phase_new_moon, WatchUi.loadResource(Rez.JsonData.moon_phase_new_moon));
        gIconData.put(:moon_phase_waxing_crescent, WatchUi.loadResource(Rez.JsonData.moon_phase_waxing_crescent));
        gIconData.put(:moon_phase_first_quarter, WatchUi.loadResource(Rez.JsonData.moon_phase_first_quarter));
        gIconData.put(:moon_phase_waxing_gibbous, WatchUi.loadResource(Rez.JsonData.moon_phase_waxing_gibbous));
        gIconData.put(:moon_phase_full_moon, WatchUi.loadResource(Rez.JsonData.moon_phase_full_moon));
        gIconData.put(:moon_phase_waning_gibbous, WatchUi.loadResource(Rez.JsonData.moon_phase_waning_gibbous));
        gIconData.put(:moon_phase_last_quarter, WatchUi.loadResource(Rez.JsonData.moon_phase_last_quarter));
        gIconData.put(:moon_phase_waning_crescent, WatchUi.loadResource(Rez.JsonData.moon_phase_waning_crescent));

        // Status Icons
        gIconData.put(:notification, WatchUi.loadResource(Rez.JsonData.notification));
        gIconData.put(:dnd, WatchUi.loadResource(Rez.JsonData.dnd));

        // Weather Icons
        gIconData.put(:celsius, WatchUi.loadResource(Rez.JsonData.celsius));
        gIconData.put(:fahrenheit, WatchUi.loadResource(Rez.JsonData.fahrenheit));
        gIconData.put(:percent, WatchUi.loadResource(Rez.JsonData.percent));
        gIconData.put(:sunny, WatchUi.loadResource(Rez.JsonData.sunny));
        gIconData.put(:cloudy, WatchUi.loadResource(Rez.JsonData.cloudy));
        gIconData.put(:partly_cloudy, WatchUi.loadResource(Rez.JsonData.partly_cloudy));
        gIconData.put(:partly_cloudy_night, WatchUi.loadResource(Rez.JsonData.partly_cloudy_night));
        gIconData.put(:partly_cloudy_rain, WatchUi.loadResource(Rez.JsonData.partly_cloudy_rain));
        gIconData.put(:thunder, WatchUi.loadResource(Rez.JsonData.thunder));
        gIconData.put(:rainy, WatchUi.loadResource(Rez.JsonData.rainy));
        gIconData.put(:snowy, WatchUi.loadResource(Rez.JsonData.snowy));
        gIconData.put(:windy, WatchUi.loadResource(Rez.JsonData.windy));
        gIconData.put(:partly_cloudy_rain_night, WatchUi.loadResource(Rez.JsonData.partly_cloudy_rain_night));
        gIconData.put(:sleet, WatchUi.loadResource(Rez.JsonData.sleet));
        gIconData.put(:foggy, WatchUi.loadResource(Rez.JsonData.foggy));
        gIconData.put(:clear_night, WatchUi.loadResource(Rez.JsonData.clear_night));
        gIconData.put(:windy_rain, WatchUi.loadResource(Rez.JsonData.windy_rain));

        // Activity Icons
        gIconData.put(:train_readiness, WatchUi.loadResource(Rez.JsonData.train_readiness));

        // UV Index Icons
        gIconData.put(:uv_index_0, WatchUi.loadResource(Rez.JsonData.uv_index_0));
        gIconData.put(:uv_index_1, WatchUi.loadResource(Rez.JsonData.uv_index_1));
        gIconData.put(:uv_index_2, WatchUi.loadResource(Rez.JsonData.uv_index_2));
        gIconData.put(:uv_index_3, WatchUi.loadResource(Rez.JsonData.uv_index_3));
        gIconData.put(:uv_index_4, WatchUi.loadResource(Rez.JsonData.uv_index_4));
        gIconData.put(:uv_index_5, WatchUi.loadResource(Rez.JsonData.uv_index_5));
        gIconData.put(:uv_index_6, WatchUi.loadResource(Rez.JsonData.uv_index_6));
        gIconData.put(:uv_index_7, WatchUi.loadResource(Rez.JsonData.uv_index_7));
        gIconData.put(:uv_index_8, WatchUi.loadResource(Rez.JsonData.uv_index_8));
        gIconData.put(:uv_index_9, WatchUi.loadResource(Rez.JsonData.uv_index_9));
        gIconData.put(:uv_index_10, WatchUi.loadResource(Rez.JsonData.uv_index_10));
    }
}
