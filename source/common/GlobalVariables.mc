import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
import Toybox.Weather;
import Toybox.Time;

//! This module stores and manages all global variables for the watch face.
//! It centralizes application state, including device properties, coordinates,
//! cached sensor data, and theme-related values.
module GlobalVariables {
    // Type definition for the UI elements dictionary to enforce structure.
    typedef UiElements as {
        // --- Device Properties ---
        :deviceWidth as Number or Null,
        :deviceHeight as Number or Null,
        :deviceCenterX as Number or Null,
        :deviceCenterY as Number or Null,
        :dataRadius as Float or Null,
        :dialBuffer as Graphics.BufferedBitmap or Null,
        :visualHourHandWidth as Float or Null,

        // --- UI Element Dimensions ---
        :fontTinyHeight as Number or Null,
        :fontXtinyHeight as Number or Null,
        :temperatureTextWidth as Number or Null,
        :temperatureTextHeight as Number or Null,

        // --- Polar Drawing Properties ---
        :polarArcWidth as Number or Null,

        // --- Hand Coordinates ---
        :hourHandOutlineCoords as Array<[Float,Float]> or Null,
        :hourHandFillCoords as Array<[Float,Float]> or Null,
        :hourHandLumeCoords as Array<[Float,Float]> or Null,
        :minuteHandOutlineCoords as Array<[Float,Float]> or Null,
        :minuteHandFillCoords as Array<[Float,Float]> or Null,
        :minuteLumeCoords as Array<[Float,Float]> or Null,

        // --- Data Field Coordinates ---
        :dndCoords as Array<Number> or Null,
        :recoveryCoords as Array<Number> or Null,
        :notificationCoords as Array<Number> or Null,
        :weatherGroupCoords as Array<Number> or Null,
        :standardGroupCoords as Array<Number> or Null,
        :weatherGroupElementCoords as Dictionary<Symbol, Number> or Null,
        :standardGroupElementCoords as Dictionary<Symbol, Number> or Null
    };

    // This dictionary holds all UI-related variables, initialized as empty.
    var gUi as UiElements = {};

    // --- Burn-In Protection ---
    var gBurnInRadiusOffset as Number = 0;
    var gBurnInProtectionTick as Number = 0;
    const BURN_IN_OFFSET_SEQUENCE as Array<Number> = [0, 1];
    const BURN_IN_UPDATE_INTERVAL as Number = 30;

    var gHeartRateExpirationDuration as Time.Duration or Null = null;
    var gBodyBatteryExpirationDuration as Time.Duration or Null = null;
    var gStressExpirationDuration as Time.Duration or Null = null;
    var gActivityMonitorExpirationDuration as Time.Duration or Null = null;
    var gWeatherExpirationDuration as Time.Duration or Null = null;

    // --- Data Timestamps ---
    var gLastActivityInfoUpdate as Time.Moment or Null = null;
    var gLastHeartRateUpdate as Time.Moment or Null = null;
    var gLastBodyBatteryUpdate as Time.Moment or Null = null;
    var gLastStressUpdate as Time.Moment or Null = null;
    var gLastWeatherUpdate as Time.Moment or Null = null;

    // --- Cached Data ---
    var gDateString as String or Null = null;
    var gHeartRate as Number or Null = null;
    var gBodyBattery as Number or Null = null;
    var gCalories as Number or Null = null;
    var gCalorieGoal as Number or Null = null;
    var gSteps as Number or Null = null;
    var gStepGoal as Number or Null = null;
    var gActiveMinutesGoal as Number or Null = null;
    var gActiveMinutesRaw as Number or Null = null;
    var gStressLevel as Number or Null = null;
    var gTimeToRecovery as Number or Null = null;
    var gTemperature as Float or Null = null;
    var gPrecipitationChance as Number or Null = null;
    var gUvIndex as Number or Null = null;
    var gUvIndexIconId as Symbol or Null = null;
    var gTempUnitIconId as Symbol or Null = null;
    var gWeatherCondition as Weather.Condition or Null = null;
    var gWeatherConditionIconId as Symbol or Null = null;
    var gIsDayTime as Boolean = true;
    var gIsAwake as Boolean = true;
    var gIsCharging as Boolean = false;
    var gBatteryLevel as Number or Null = null;
    var gNotificationCount as Number = 0;
    var gIsDndEnabled as Boolean = false;
    var gMoonPhaseIconId as Symbol or Null = null;
    var gHeartRateColor as Graphics.ColorType or Null = null;

    var gLastDayValue as Number or Null = null;

    var gSortedPolarArcs as Array<Dictionary<Symbol, Number or Graphics.ColorType>> or Null = null;
}
