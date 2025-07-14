import Toybox.Lang;
import Toybox.System;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.UserProfile;
import Toybox.Position;

using $.GlobalVariables;
using $.ThemeColors;
using $.AionIcons;
using $.DialUtils;

//! Manages fetching, processing, and caching of all dynamic watch face data.
//! It encapsulates the logic for updating sensor data, system stats, weather,
//! and other application state.
module DataManager {

    // --- Data Cache Settings ---
    const ACTIVITY_MONITOR_EXPIRATION_SECONDS as Number = 600;
    const BODY_BATTERY_EXPIRATION_SECONDS as Number = 600;
    const STRESS_EXPIRATION_SECONDS as Number = 300;
    const HEART_RATE_EXPIRATION_SECONDS as Number = 60;
    const WEATHER_EXPIRATION_MINUTES as Number = 30;

    // --- Calorie Calculation Constants ---
    // Activity level multipliers for TDEE calculation
    const ACTIVITY_SEDENTARY = 1.2f;          // Little/no exercise
    const ACTIVITY_LIGHTLY_ACTIVE = 1.375f;   // 1-3 days/week
    const ACTIVITY_MODERATELY_ACTIVE = 1.55f; // 3-5 days/week
    const ACTIVITY_VERY_ACTIVE = 1.725f;      // 6-7 days/week
    const ACTIVITY_EXTRA_ACTIVE = 1.9f;       // Very intense training or physical job

    //! User profile data structure for calorie calculations
    typedef UserProfileData as {
        :weight as Number or Null,            // Weight in kg
        :height as Number or Null,            // Height in cm
        :age as Number or Null,               // Age in years
        :gender as Number or Null,            // UserProfile.GENDER_MALE or GENDER_FEMALE
        :activityLevel as Float or Null       // Activity multiplier
    };

    //! Initializes all data fields with default values to prevent null data issues.
    //! This should be called once during application startup before the first update.
    function initializeData() as Void {
        var now = Time.now();
        var deviceSettings = System.getDeviceSettings();
        var stats = System.getSystemStats();

        // --- Time and Date ---
        updateDate(now);
        GlobalVariables.gMoonPhaseIconId = AionIcons.getMoonPhaseIconId(now);

        GlobalVariables.gUi[:polarArcWidth] = ThemeSizing.POLAR_ARC_WIDTH;

        // --- Activity and Sensor Data (with defaults) ---
        GlobalVariables.gCalories = 0;
        GlobalVariables.gCalorieGoal = null;
        GlobalVariables.gSteps = 0;
        GlobalVariables.gStepGoal = 10000;
        GlobalVariables.gTimeToRecovery = null;
        GlobalVariables.gActiveMinutesRaw = 0;
        GlobalVariables.gActiveMinutesGoal = 30;
        GlobalVariables.gLastActivityInfoUpdate = now;

        GlobalVariables.gHeartRate = null;
        GlobalVariables.gLastHeartRateUpdate = now;

        GlobalVariables.gBodyBattery = null;
        GlobalVariables.gLastBodyBatteryUpdate = now;

        GlobalVariables.gStressLevel = null;
        GlobalVariables.gLastStressUpdate = now;

        // --- System and Device Data ---
        var batteryLevel = stats.battery.toNumber();
        GlobalVariables.gIsCharging = stats.charging;
        GlobalVariables.gBatteryLevel = batteryLevel;

        GlobalVariables.gNotificationCount = deviceSettings.notificationCount;
        if (deviceSettings has :doNotDisturb) {
            GlobalVariables.gIsDndEnabled = deviceSettings.doNotDisturb;
        } else {
            GlobalVariables.gIsDndEnabled = false;
        }
        GlobalVariables.gTempUnitIconId = AionIcons.getTempUnitIconId(deviceSettings.temperatureUnits);

        // --- Weather Data (with defaults) ---
        GlobalVariables.gWeatherCondition = null;
        GlobalVariables.gUvIndex = null;
        GlobalVariables.gPrecipitationChance = null;
        GlobalVariables.gTemperature = null;
        GlobalVariables.gIsDayTime = true;
        GlobalVariables.gLastWeatherUpdate = now;
        GlobalVariables.gLastDayValue = Gregorian.info(now, Time.FORMAT_SHORT).day;

        // Update weather-dependent icons with defaults
        GlobalVariables.gUvIndexIconId = AionIcons.getUvIndexIconId(GlobalVariables.gUvIndex);
        GlobalVariables.gWeatherConditionIconId = AionIcons.mapConditionToIconId(GlobalVariables.gWeatherCondition, GlobalVariables.gIsDayTime);

        // --- Derived Data (for UI) ---
        updatePolarArcsData();
        updateDerivedUIState();
    }

    //! Updates all dynamic data for the watch face.
    //! This includes sensor data, system stats, device settings, weather, and moon phase.
    //! This function is called periodically to keep the watch face data fresh.
    function updateAllData() as Void {
        var now = Time.now();
        var deviceSettings = System.getDeviceSettings();
        var activityInfo = ActivityMonitor.getInfo();
        var stats = System.getSystemStats();

        // --- Time and Date ---
        updateDate(now);
        GlobalVariables.gMoonPhaseIconId = AionIcons.getMoonPhaseIconId(now);

        // --- Activity and Sensor Data ---
        updateActivityMonitorData(now, activityInfo);
        updateCalorieGoalData();
        updateHeartRateData(now);
        updateStressLevelData(now);
        if (Toybox has :SensorHistory) {
            updateBodyBatteryData(now);
        }

        // --- System and Device Data ---
        updateSystemStats(stats);
        updateDeviceSettings(deviceSettings);

        // --- Weather Data ---
        updateWeatherData(now, deviceSettings);

        // --- Derived Data (for UI) ---
        updatePolarArcsData();
        updateDerivedUIState();
    }

    //! Checks if a cached value has expired.
    //! @param lastUpdateMoment The timestamp of the last update.
    //! @param expirationDuration The duration after which the cache is considered expired.
    //! @param now The current time.
    //! @return True if the cache is expired, false otherwise.
    function isCacheExpired(lastUpdateMoment as Time.Moment or Null, expirationDuration as Time.Duration, now as Time.Moment) as Boolean {
        if (lastUpdateMoment == null) {
            return false;
        }
        return now.subtract(lastUpdateMoment).value() > expirationDuration.value();
    }

    //! Updates the formatted date string (e.g., "Mon 1").
    //! @param now The current time moment.
    function updateDate(now as Time.Moment) as Void {
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        GlobalVariables.gDateString = Lang.format("$1$ $2$", [info.day_of_week, info.day]);
    }

    //! Updates all data derived from `ActivityMonitor.Info`.
    //! This includes calories, steps, active minutes, and time to recovery.
    //! If the data is stale, it is cleared.
    //! @param now The current time moment, used for cache validation.
    //! @param activityInfo The latest info object from `ActivityMonitor`.
    function updateActivityMonitorData(now as Time.Moment, activityInfo as ActivityMonitor.Info or Null) as Void {
        if (activityInfo != null) {
            GlobalVariables.gLastActivityInfoUpdate = now;
            GlobalVariables.gCalories = activityInfo.calories;
            GlobalVariables.gSteps = activityInfo.steps;
            GlobalVariables.gStepGoal = activityInfo.stepGoal;

            if (activityInfo has :timeToRecovery) {
                GlobalVariables.gTimeToRecovery = activityInfo.timeToRecovery;
            }

            if (activityInfo.activeMinutesDay != null) {
                var activeMinutes = activityInfo.activeMinutesDay.total;
                GlobalVariables.gActiveMinutesRaw = activeMinutes;

                // Get active minutes goal (weekly goal divided by 7 for daily goal)
                if (activityInfo has :activeMinutesWeekGoal && activityInfo.activeMinutesWeekGoal != null) {
                    GlobalVariables.gActiveMinutesGoal = activityInfo.activeMinutesWeekGoal / 7;
                } else {
                    GlobalVariables.gActiveMinutesGoal = 30;
                }
            } else {
                GlobalVariables.gActiveMinutesRaw = 0;
                GlobalVariables.gActiveMinutesGoal = 30;
            }
        } else if (isCacheExpired(GlobalVariables.gLastActivityInfoUpdate, GlobalVariables.gActivityMonitorExpirationDuration, now)) {
            GlobalVariables.gCalories = null;
            GlobalVariables.gSteps = null;
            GlobalVariables.gStepGoal = null;
            GlobalVariables.gTimeToRecovery = null;
            GlobalVariables.gActiveMinutesRaw = 0;
            GlobalVariables.gActiveMinutesGoal = 30;
            GlobalVariables.gLastActivityInfoUpdate = null;
        }
    }

    //! Updates the current stress level from `ActivityMonitor.Info`.
    //! If the data is stale, it is cleared.
    //! @param now The current time moment, used for cache validation.
    function updateStressLevelData(now as Time.Moment) as Void {
        var activityInfo = ActivityMonitor.getInfo();
        var stressValue = null;
        if (activityInfo != null && activityInfo has :stressScore) {
            stressValue = activityInfo.stressScore;
        }

        if (stressValue != null) {
            GlobalVariables.gStressLevel = stressValue;
            GlobalVariables.gLastStressUpdate = now;
        } else if (isCacheExpired(GlobalVariables.gLastStressUpdate, GlobalVariables.gStressExpirationDuration, now)) {
            GlobalVariables.gStressLevel = null;
            GlobalVariables.gLastStressUpdate = null;
        }
    }

    //! Updates the heart rate from the sensor history.
    //! It also determines the appropriate color for the heart rate value based on user zones or a fallback calculation.
    //! If the data is stale, it is cleared.
    //! @param now The current time moment, used for cache validation.
    function updateHeartRateData(now as Time.Moment) as Void {
        var hrIterator = null;
        try {
            hrIterator = ActivityMonitor.getHeartRateHistory(1, true);
        } catch (e instanceof Lang.Exception) {
            hrIterator = null;
        }

        var latestHrSample = (hrIterator != null) ? hrIterator.next() : null;

        if (latestHrSample != null && latestHrSample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
            GlobalVariables.gHeartRate = latestHrSample.heartRate;
            GlobalVariables.gLastHeartRateUpdate = now;
        } else if (isCacheExpired(GlobalVariables.gLastHeartRateUpdate, GlobalVariables.gHeartRateExpirationDuration, now)) {
            GlobalVariables.gHeartRate = null;
            GlobalVariables.gLastHeartRateUpdate = null;
        }

        // --- Calculate HR Color ---
        var heartRate = GlobalVariables.gHeartRate;
        var heartRateColor = ThemeColors.heartRateColor; // Default color

        if (heartRate != null) {
            // First, try to use the zones defined in the user's profile
            var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
            if (zones != null && zones.size() == 6) {
                if (heartRate >= zones[5]) { heartRateColor = ThemeColors.secondHandColor; }               // Zone 5
                else if (heartRate >= zones[4]) { heartRateColor = ThemeColors.heartRateZone4Color; }      // Zone 4
                else if (heartRate >= zones[3]) { heartRateColor = ThemeColors.heartRateZone3Color; }      // Zone 3
                else if (heartRate >= zones[2]) { heartRateColor = ThemeColors.heartRateZone2Color; }      // Zone 2
                else if (heartRate >= zones[0]) { heartRateColor = ThemeColors.heartRateZone1Color; }      // Zone 1
            } else {
                // Fallback: Estimate zones using the 220 - age formula
                var profile = UserProfile.getProfile();
                if (profile != null && profile.birthYear != null) {
                    var currentYear = Gregorian.info(Time.now(), Time.FORMAT_SHORT).year;
                    var age = currentYear - profile.birthYear;
                    var maxHr = 220 - age;
                    var hrPercentage = (heartRate.toFloat() / maxHr) * 100;

                    if (hrPercentage >= 90) {
                        heartRateColor = ThemeColors.secondHandColor;        // Zone 5: >90%
                    } else if (hrPercentage >= 80) {
                        heartRateColor = ThemeColors.heartRateZone4Color;    // Zone 4: 80-90%
                    } else if (hrPercentage >= 70) {
                        heartRateColor = ThemeColors.heartRateZone3Color;    // Zone 3: 70-80%
                    } else if (hrPercentage >= 60) {
                        heartRateColor = ThemeColors.heartRateZone2Color;    // Zone 2: 60-70%
                    } else {
                        heartRateColor = ThemeColors.heartRateZone1Color;    // Zone 1: <60%
                    }
                }
            }
        }
        GlobalVariables.gHeartRateColor = heartRateColor;
    }

    //! Updates the daily calorie goal by calculating the user's Total Daily Energy Expenditure (TDEE).
    //! It uses the Mifflin-St Jeor BMR formula combined with an activity multiplier derived from the user's profile.
    function updateCalorieGoalData() as Void {
        var profile = UserProfile.getProfile();
        var userData = {
            :weight => null,
            :height => null,
            :age => null,
            :gender => null,
            :activityLevel => null
        } as UserProfileData;

        if (profile != null) {
            // Get weight in kg
            if (profile has :weight) {
                var weightInGrams = profile.weight;
                if (weightInGrams != null) {
                    // Convert grams to kilograms
                    userData[:weight] = weightInGrams / 1000.0f;
                }
            }

            // Get height in cm
            if (profile has :height) {
                var height = profile.height;
                if (height != null) {
                    // Height is already in cm, which is what the formula uses
                    userData[:height] = height;
                }
            }

            // Get age from birth year
            if (profile has :birthYear) {
                var birthYear = profile.birthYear;
                if (birthYear != null) {
                    var currentYear = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT).year;
                    userData[:age] = currentYear - birthYear;
                }
            }

            // Get gender
            if (profile has :gender) {
                var gender = profile.gender;
                if (gender != null) {
                    userData[:gender] = gender;
                }
            }

            // Get activity level from activity class if available
            if (profile has :activityClass && profile.activityClass != null) {
                // userData[:activityLevel] = getActivityMultiplierFromClass(profile.activityClass as Number);
                if (profile.activityClass < 20) {
                    userData[:activityLevel] = ACTIVITY_SEDENTARY;          // 0-19
                } else if (profile.activityClass < 40) {
                    userData[:activityLevel] = ACTIVITY_LIGHTLY_ACTIVE;     // 20-39
                } else if (profile.activityClass < 60) {
                    userData[:activityLevel] = ACTIVITY_MODERATELY_ACTIVE;  // 40-59
                } else if (profile.activityClass < 80) {
                    userData[:activityLevel] = ACTIVITY_VERY_ACTIVE;        // 60-79
                } else {
                    userData[:activityLevel] = ACTIVITY_EXTRA_ACTIVE;       // 80-100
                }
            } else {
                // Fallback to default activity level
                userData[:activityLevel] = ACTIVITY_MODERATELY_ACTIVE;
            }
        }

        if (userData[:weight] == null || userData[:height] == null ||
            userData[:age] == null || userData[:gender] == null) {
            return;
        }

        var weight = userData[:weight] as Number;
        var height = userData[:height] as Number;
        var age = userData[:age] as Number;
        var gender = userData[:gender] as Number;

        var bmr = 10.0f * weight + 6.25f * height - 5.0f * age;

        if (gender == UserProfile.GENDER_MALE) {
            bmr += 5.0f;
        } else {
            bmr -= 161.0f;
        }

        GlobalVariables.gCalorieGoal = (bmr.toFloat() * userData[:activityLevel]).toNumber();
    }

    //! Updates the Body Battery value from `SensorHistory`.
    //! If the data is stale, it is cleared.
    //! @param now The current time moment, used for cache validation.
    function updateBodyBatteryData(now as Time.Moment) as Void {
        if (!(SensorHistory has :getBodyBatteryHistory)) { return; }

        var bbIterator = null;
        try {
            bbIterator = SensorHistory.getBodyBatteryHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
        } catch (e instanceof Lang.Exception) {
            bbIterator = null;
        }

        var sample = (bbIterator != null) ? bbIterator.next() : null;
        if (sample != null && sample.data != null) {
            GlobalVariables.gBodyBattery = sample.data;
            GlobalVariables.gLastBodyBatteryUpdate = now;
        } else if (isCacheExpired(GlobalVariables.gLastBodyBatteryUpdate, GlobalVariables.gBodyBatteryExpirationDuration, now)) {
            GlobalVariables.gBodyBattery = null;
            GlobalVariables.gLastBodyBatteryUpdate = null;
        }
    }

    //! Updates system-wide statistics, including battery level and charging status.
    //! @param stats The system stats object from `System.getSystemStats()`.
    function updateSystemStats(stats as System.Stats) as Void {
        var batteryLevel = (stats.battery != null) ? stats.battery.toNumber() : 0;
        GlobalVariables.gIsCharging = stats.charging;
        GlobalVariables.gBatteryLevel = batteryLevel;
    }

    //! Updates settings that are specific to the device and user preferences.
    //! This includes notification count, Do Not Disturb status, and temperature units.
    //! @param deviceSettings The device settings object from `System.getDeviceSettings()`.
    function updateDeviceSettings(deviceSettings as System.DeviceSettings) as Void {
        GlobalVariables.gNotificationCount = deviceSettings.notificationCount;
        if (deviceSettings has :doNotDisturb) {
            GlobalVariables.gIsDndEnabled = deviceSettings.doNotDisturb;
        } else {
            GlobalVariables.gIsDndEnabled = false;
        }
        GlobalVariables.gTempUnitIconId = AionIcons.getTempUnitIconId(deviceSettings.temperatureUnits);
    }

    //! Updates the sunrise/sunset time to determine if it's day or night.
    //! This is computationally more expensive, so it should only be run when the day changes.
    //! @param now The current time moment.
    //! @param conditions The current weather conditions.
    function updateDayNightStatus(now as Time.Moment, conditions as Weather.CurrentConditions or Null) as Void {
        if (conditions == null) { return; }
        var location = conditions.observationLocationPosition;
        if (location != null && (Weather has :getSunrise) && (Weather has :getSunset)) {
            var sunrise = Weather.getSunrise(location, now);
            var sunset = Weather.getSunset(location, now);
            if (sunrise != null && sunset != null) {
                GlobalVariables.gIsDayTime = now.greaterThan(sunrise) && now.lessThan(sunset);
            }
        }
    }

    //! Updates all weather-related data, including conditions, temperature, and UV index.
    //! It also triggers the day/night status update if the day has changed.
    //! If weather data is stale, it is cleared.
    //! @param now The current time moment, used for cache validation.
    //! @param deviceSettings The device settings, used for temperature unit conversion.
    function updateWeatherData(now as Time.Moment, deviceSettings as System.DeviceSettings) as Void {
        if (!(Toybox has :Weather && Weather has :getCurrentConditions)) { return; }

        var conditions = null;
        try {
            conditions = Weather.getCurrentConditions();
        } catch (e instanceof Lang.Exception) {
            conditions = null;
        }

        if (conditions != null) {
            GlobalVariables.gLastWeatherUpdate = now;
            GlobalVariables.gWeatherCondition = conditions.condition;
            GlobalVariables.gUvIndex = conditions.uvIndex == null ? null : conditions.uvIndex.toNumber();
            GlobalVariables.gPrecipitationChance = conditions.precipitationChance;

            if (conditions.temperature != null) {
                var temp = conditions.temperature.toFloat();
                if (deviceSettings.temperatureUnits == System.UNIT_STATUTE) {
                    temp = (temp * 9.0 / 5.0) + 32.0;
                }
                GlobalVariables.gTemperature = temp;
            } else {
                GlobalVariables.gTemperature = null;
            }

            // Determine if it is day time, but only if the day has changed to save calculations
            var today = Gregorian.info(now, Time.FORMAT_SHORT).day;
            if (GlobalVariables.gLastDayValue != today) {
                GlobalVariables.gLastDayValue = today;
                updateDayNightStatus(now, conditions);
            }
        } else if (isCacheExpired(GlobalVariables.gLastWeatherUpdate, GlobalVariables.gWeatherExpirationDuration, now)) {
            GlobalVariables.gWeatherCondition = null;
            GlobalVariables.gUvIndex = null;
            GlobalVariables.gPrecipitationChance = null;
            GlobalVariables.gTemperature = null;
            GlobalVariables.gIsDayTime = true;
            GlobalVariables.gLastWeatherUpdate = null;
        }

        // Update weather-dependent icons
        GlobalVariables.gUvIndexIconId = AionIcons.getUvIndexIconId(GlobalVariables.gUvIndex);
        GlobalVariables.gWeatherConditionIconId = AionIcons.mapConditionToIconId(GlobalVariables.gWeatherCondition, GlobalVariables.gIsDayTime);
    }

    //! Populates the data for the polar arcs in a fixed order.
    //! The order is: body battery, calories, steps, stress, active minutes.
    function updatePolarArcsData() as Void {
        var arcsData = [] as Array<Dictionary<Symbol, Number or Graphics.ColorType>>;

        // BODY BATTERY ARC
        if (GlobalVariables.gBodyBattery != null) {
            arcsData.add({:percentage => GlobalVariables.gBodyBattery as Number, :color => ThemeColors.bodyBatteryArcColor});
        }

        // STRESS ARC
        if (GlobalVariables.gStressLevel != null) {
            arcsData.add({:percentage => GlobalVariables.gStressLevel as Number, :color => ThemeColors.stressArcColor});
        }

        // STEPS ARC
        if (GlobalVariables.gSteps != null && GlobalVariables.gStepGoal != null && GlobalVariables.gStepGoal > 0) {
            var stepsPercentageFloat = (GlobalVariables.gSteps.toFloat() / GlobalVariables.gStepGoal.toFloat()) * 100.0f;
            arcsData.add({:percentage => stepsPercentageFloat.toNumber(), :color => ThemeColors.stepsArcColor});
        }

        // CALORIES ARC
        if (GlobalVariables.gCalories != null && GlobalVariables.gCalorieGoal != null && GlobalVariables.gCalorieGoal > 0) {
            var caloriesPercentageFloat = (GlobalVariables.gCalories.toFloat() / GlobalVariables.gCalorieGoal.toFloat()) * 100.0f;
            arcsData.add({:percentage => caloriesPercentageFloat.toNumber(), :color => ThemeColors.caloriesArcColor});
        }

        // ACTIVE MINUTES ARC
        if (GlobalVariables.gActiveMinutesRaw != null && GlobalVariables.gActiveMinutesGoal != null && GlobalVariables.gActiveMinutesGoal > 0) {
            var activeMinutesPercentageFloat = (GlobalVariables.gActiveMinutesRaw.toFloat() / GlobalVariables.gActiveMinutesGoal.toFloat()) * 100.0f;
            arcsData.add({:percentage => activeMinutesPercentageFloat.toNumber(), :color => ThemeColors.activeMinutesArcColor});
        }

        GlobalVariables.gSortedPolarArcs = arcsData;
    }

    //! Calculates and updates the coordinates for various UI elements.
    //! This function is called after data updates to ensure that any layout
    //! changes dependent on dynamic data (like icon widths) are reflected.
    function updateDerivedUIState() as Void {
        // --- Weather Group Coordinates ---
        var weatherGroupCoords = GlobalVariables.gUi[:weatherGroupCoords];
        var temperatureTextHeight = GlobalVariables.gUi[:temperatureTextHeight];
        var temperatureTextWidth = GlobalVariables.gUi[:temperatureTextWidth];

        if (weatherGroupCoords != null && temperatureTextHeight != null && temperatureTextWidth != null) {
            var coords = DialUtils.getRadialOffsetCoords(weatherGroupCoords[0], weatherGroupCoords[1]);
            var newX = coords[0];
            var newY = coords[1];

            var tempUnitIconData = AionIcons.getIcon(GlobalVariables.gTempUnitIconId);
            var tempUnitIconWidth = (tempUnitIconData != null && tempUnitIconData["width"] != null) ? tempUnitIconData["width"] as Number : 0;

            GlobalVariables.gUi[:weatherGroupElementCoords] = {
                :topRowY => newY - temperatureTextHeight / 2,
                :bottomRowY => newY + temperatureTextHeight / 2,
                :uvIconX => newX + temperatureTextWidth - tempUnitIconWidth / 2,
                :moonIconX => newX + temperatureTextWidth + tempUnitIconWidth / 2,
                :tempTextX => newX + temperatureTextWidth / 1.5,
                :tempUnitIconX => newX + temperatureTextWidth - tempUnitIconWidth / 8,
                :weatherIconX => newX + temperatureTextWidth + tempUnitIconWidth / 2,
                :precipBarX => newX + temperatureTextWidth - tempUnitIconWidth + tempUnitIconWidth / 8,
                :precipBarWidth => 2 * tempUnitIconWidth - tempUnitIconWidth / 4,
                :precipBarY => newY,
            };
        }

        // --- Standard Group Coordinates ---
        var standardGroupCoords = GlobalVariables.gUi[:standardGroupCoords];
        var dateTextHeight = GlobalVariables.gUi[:fontTinyHeight];
        var heartRateTextHeight = GlobalVariables.gUi[:fontXtinyHeight];
        if (standardGroupCoords != null && dateTextHeight != null && heartRateTextHeight != null) {
            var coords = DialUtils.getRadialOffsetCoords(standardGroupCoords[0], standardGroupCoords[1]);
            var newX = coords[0];
            var newY = coords[1];

            var middle = dateTextHeight / 4 + heartRateTextHeight / 4;

            GlobalVariables.gUi[:standardGroupElementCoords] = {
                :dateX => newX,
                :dateY => newY - middle,
                :heartRateX => newX,
                :heartRateY => newY + middle
            };
        }
    }
}
