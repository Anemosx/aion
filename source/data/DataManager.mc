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
import Toybox.Application;

using $.GlobalVariables;
using $.ThemeColors;
using $.ThemeUtils;
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
    const ACTIVITY_SEDENTARY = 1.2f;        // Little/no exercise
    const ACTIVITY_LIGHTLY_ACTIVE = 1.375f; // 1-3 days/week
    const ACTIVITY_MODERATELY_ACTIVE = 1.55f; // 3-5 days/week
    const ACTIVITY_VERY_ACTIVE = 1.725f;    // 6-7 days/week
    const ACTIVITY_EXTRA_ACTIVE = 1.9f;     // Very intense training or physical job

    //! User profile data structure for calorie calculations
    typedef UserProfileData as {
        :weight as Number or Null,      // Weight in kg
        :height as Number or Null,      // Height in cm
        :age as Number or Null,         // Age in years
        :gender as Number or Null,      // UserProfile.GENDER_MALE or GENDER_FEMALE
        :activityLevel as Float or Null // Activity multiplier
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

        GlobalVariables.gFloorsClimbed = 0;
        GlobalVariables.gFloorsClimbedGoal = 10;
        GlobalVariables.gDistance = 0.0f;
        GlobalVariables.gDistanceGoal = 10.0f;
        GlobalVariables.gElevationGain = 0.0f;
        GlobalVariables.gElevationGainGoal = 500.0f;
        GlobalVariables.gRespirationRate = null;

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

        readArcConfigurations();

        // --- Derived Data (for UI) ---
        updatePolarArcsData();
        updateDerivedUIState();
    }

    //! Called when application settings have changed.
    //! Re-reads the arc configurations from properties.
    function onSettingsChanged() as Void {
        readArcConfigurations();
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
        updateFloorsClimbedData();
        updateDistanceData();
        updateElevationGainData();
        if (Toybox has :SensorHistory) {
            updateBodyBatteryData(now);
            updateRespirationRateData();
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

    //! Updates floors climbed data from ActivityMonitor.
    function updateFloorsClimbedData() as Void {
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo != null && activityInfo has :floorsClimbed) {
            GlobalVariables.gFloorsClimbed = activityInfo.floorsClimbed;
            GlobalVariables.gFloorsClimbedGoal = activityInfo.floorsClimbedGoal;
        }
    }

    //! Updates distance data from ActivityMonitor.
    function updateDistanceData() as Void {
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo != null && activityInfo has :distance) {
            // Distance is in meters, convert to kilometers for display
            GlobalVariables.gDistance = activityInfo.distance / 1000.0f;
            GlobalVariables.gDistanceGoal = 10.0f; // 10km default goal
        }
    }

    //! Updates elevation gain data from ActivityMonitor.
    function updateElevationGainData() as Void {
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo != null && activityInfo has :elevationGain) {
            GlobalVariables.gElevationGain = activityInfo.elevationGain;
            GlobalVariables.gElevationGainGoal = 500.0f; // 500m default goal
        }
    }

    //! Updates respiration rate from ActivityMonitor.
    //! Note: Respiration rate is available via ActivityMonitor.Info on supported devices.
    function updateRespirationRateData() as Void {
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo != null && activityInfo has :respirationRate) {
            var rate = activityInfo.respirationRate;
            if (rate != null) {
                GlobalVariables.gRespirationRate = rate.toFloat();
            }
        }
    }

    // Data type constants (matching settings values)
    const DATA_TYPE_NONE = 0;
    const DATA_TYPE_BODY_BATTERY = 1;
    const DATA_TYPE_STRESS = 2;
    const DATA_TYPE_STEPS = 3;
    const DATA_TYPE_CALORIES = 4;
    const DATA_TYPE_ACTIVE_MINUTES = 5;
    const DATA_TYPE_FLOORS_CLIMBED = 6;
    const DATA_TYPE_DISTANCE = 7;
    const DATA_TYPE_ELEVATION_GAIN = 8;
    const DATA_TYPE_RESPIRATION_RATE = 9;

    // Goal constants (matching settings values) - Updated with consolidated goal sets
    const GOAL_AUTO = 0;

    // Steps goals
    const GOAL_500 = 1;
    const GOAL_1000 = 2;
    const GOAL_2000 = 3;
    const GOAL_3000 = 4;
    const GOAL_4000 = 5;
    const GOAL_5000_STEPS = 6;
    const GOAL_7500 = 7;
    const GOAL_10000_STEPS = 8;
    const GOAL_12500 = 9;
    const GOAL_15000_STEPS = 10;
    const GOAL_20000_STEPS = 11;
    const GOAL_25000 = 12;
    const GOAL_30000 = 13;
    const GOAL_35000 = 14;
    const GOAL_40000 = 15;
    const GOAL_50000 = 16;
    const GOAL_60000 = 17;

    // Active Minutes goals
    const GOAL_1_MIN = 18;
    const GOAL_3_MIN = 19;
    const GOAL_5_MIN = 20;
    const GOAL_10_MIN = 21;
    const GOAL_15_MIN = 22;
    const GOAL_20_MIN = 23;
    const GOAL_30_MIN = 24;
    const GOAL_45 = 25;
    const GOAL_60_MIN = 26;
    const GOAL_90 = 27;
    const GOAL_120_MIN = 28;
    const GOAL_150 = 29;
    const GOAL_180_MIN = 30;
    const GOAL_240 = 31;
    const GOAL_300 = 32;

    // Calories goals
    const GOAL_50_CAL = 33;
    const GOAL_100_CAL = 34;
    const GOAL_150_CAL = 35;
    const GOAL_200_CAL = 36;
    const GOAL_300_CAL = 37;
    const GOAL_600 = 38;
    const GOAL_800 = 39;
    const GOAL_1000_CAL = 40;
    const GOAL_1200 = 41;
    const GOAL_1500_CAL = 42;
    const GOAL_1800 = 43;
    const GOAL_2000_CAL = 44;
    const GOAL_2200 = 45;
    const GOAL_2500 = 46;
    const GOAL_3000_CAL = 47;
    const GOAL_3500 = 48;
    const GOAL_4000_CAL = 49;

    // Floors goals
    const GOAL_0_FLOORS = 50;
    const GOAL_1_FLOOR = 51;
    const GOAL_2_FLOORS = 52;
    const GOAL_3_FLOORS = 53;
    const GOAL_5_FLOORS = 54;
    const GOAL_10_FLOORS = 55;
    const GOAL_15_FLOORS = 56;
    const GOAL_20_FLOORS = 57;
    const GOAL_25_FLOORS = 58;
    const GOAL_30_FLOORS = 59;
    const GOAL_40_FLOORS = 60;
    const GOAL_50_FLOORS = 61;
    const GOAL_75_FLOORS = 62;
    const GOAL_100_FLOORS = 63;

    // Distance goals (km)
    const GOAL_0_2_KM = 64;
    const GOAL_0_5_KM = 65;
    const GOAL_1_KM = 66;
    const GOAL_1_5_KM = 67;
    const GOAL_2_KM_DIST = 68;
    const GOAL_2_5_KM = 69;
    const GOAL_5_KM_DIST = 70;
    const GOAL_7_5_KM = 71;
    const GOAL_10_KM_DIST = 72;
    const GOAL_15_KM = 73;
    const GOAL_20_KM_DIST = 74;
    const GOAL_25_KM = 75;
    const GOAL_30_KM = 76;
    const GOAL_40_KM = 77;
    const GOAL_42_KM = 78;

    // Elevation goals (meters)
    const GOAL_5M = 79;
    const GOAL_10M = 80;
    const GOAL_20M = 81;
    const GOAL_30M = 82;
    const GOAL_50M = 83;
    const GOAL_100M_ELEV = 84;
    const GOAL_200M_ELEV = 85;
    const GOAL_500M_ELEV = 86;
    const GOAL_1000M_ELEV = 87;
    const GOAL_1500M_ELEV = 88;
    const GOAL_2000M_ELEV = 89;
    const GOAL_2500M = 90;
    const GOAL_3000M_ELEV = 91;

    // Respiration goals (breaths/min)
    const GOAL_10_RESP = 92;
    const GOAL_12_RESP = 93;
    const GOAL_14_RESP = 94;
    const GOAL_16_RESP = 95;
    const GOAL_18_RESP = 96;
    const GOAL_20_RESP = 97;
    const GOAL_22_RESP = 98;

    //! Gets the available goal options for a given data type.
    //! @param dataType The data type number.
    //! @return Array of goal indices that are valid for this data type.
    function getAvailableGoalsForDataType(dataType as Number) as Array<Number> {
        var goals = [GOAL_AUTO] as Array<Number>; // Auto is always available

        if (dataType == DATA_TYPE_STEPS) {
            goals.addAll([
                GOAL_500, GOAL_1000, GOAL_2000, GOAL_3000, GOAL_4000,
                GOAL_5000_STEPS, GOAL_7500, GOAL_10000_STEPS, GOAL_12500, GOAL_15000_STEPS,
                GOAL_20000_STEPS, GOAL_25000, GOAL_30000, GOAL_35000, GOAL_40000, GOAL_50000, GOAL_60000
            ]);
        } else if (dataType == DATA_TYPE_ACTIVE_MINUTES) {
            goals.addAll([
                GOAL_1_MIN, GOAL_3_MIN, GOAL_5_MIN, GOAL_10_MIN, GOAL_15_MIN,
                GOAL_20_MIN, GOAL_30_MIN, GOAL_45, GOAL_60_MIN,
                GOAL_90, GOAL_120_MIN, GOAL_150, GOAL_180_MIN, GOAL_240, GOAL_300
            ]);
        } else if (dataType == DATA_TYPE_CALORIES) {
            goals.addAll([
                GOAL_50_CAL, GOAL_100_CAL, GOAL_150_CAL, GOAL_200_CAL, GOAL_300_CAL,
                GOAL_600, GOAL_800, GOAL_1000_CAL, GOAL_1200, GOAL_1500_CAL,
                GOAL_1800, GOAL_2000_CAL, GOAL_2200, GOAL_2500, GOAL_3000_CAL, GOAL_3500, GOAL_4000_CAL
            ]);
        } else if (dataType == DATA_TYPE_FLOORS_CLIMBED) {
            goals.addAll([
                GOAL_0_FLOORS, GOAL_1_FLOOR, GOAL_2_FLOORS, GOAL_3_FLOORS, GOAL_5_FLOORS,
                GOAL_10_FLOORS, GOAL_15_FLOORS, GOAL_20_FLOORS, GOAL_25_FLOORS, GOAL_30_FLOORS,
                GOAL_40_FLOORS, GOAL_50_FLOORS, GOAL_75_FLOORS, GOAL_100_FLOORS
            ]);
        } else if (dataType == DATA_TYPE_DISTANCE) {
            goals.addAll([
                GOAL_0_2_KM, GOAL_0_5_KM, GOAL_1_KM, GOAL_1_5_KM, GOAL_2_KM_DIST,
                GOAL_2_5_KM, GOAL_5_KM_DIST, GOAL_7_5_KM, GOAL_10_KM_DIST, GOAL_15_KM,
                GOAL_20_KM_DIST, GOAL_25_KM, GOAL_30_KM, GOAL_40_KM, GOAL_42_KM
            ]);
        } else if (dataType == DATA_TYPE_ELEVATION_GAIN) {
            goals.addAll([
                GOAL_5M, GOAL_10M, GOAL_20M, GOAL_30M, GOAL_50M,
                GOAL_100M_ELEV, GOAL_200M_ELEV, GOAL_500M_ELEV, GOAL_1000M_ELEV,
                GOAL_1500M_ELEV, GOAL_2000M_ELEV, GOAL_2500M, GOAL_3000M_ELEV
            ]);
        } else if (dataType == DATA_TYPE_RESPIRATION_RATE) {
            goals.addAll([
                GOAL_10_RESP, GOAL_12_RESP, GOAL_14_RESP, GOAL_16_RESP, GOAL_18_RESP, GOAL_20_RESP, GOAL_22_RESP
            ]);
        }
        // For Body Battery and Stress, only Auto is available

        return goals;
    }

    //! Converts a goal index to its actual numerical value.
    //! @param goalIndex The goal constant index.
    //! @return The numerical value of the goal.
    function getGoalValue(goalIndex as Number) as Number or Float {
        if (goalIndex == GOAL_AUTO) { return 0; } // Will use default values

        // Steps goals
        else if (goalIndex == GOAL_500) { return 500; }
        else if (goalIndex == GOAL_1000) { return 1000; }
        else if (goalIndex == GOAL_2000) { return 2000; }
        else if (goalIndex == GOAL_3000) { return 3000; }
        else if (goalIndex == GOAL_4000) { return 4000; }
        else if (goalIndex == GOAL_5000_STEPS) { return 5000; }
        else if (goalIndex == GOAL_7500) { return 7500; }
        else if (goalIndex == GOAL_10000_STEPS) { return 10000; }
        else if (goalIndex == GOAL_12500) { return 12500; }
        else if (goalIndex == GOAL_15000_STEPS) { return 15000; }
        else if (goalIndex == GOAL_20000_STEPS) { return 20000; }
        else if (goalIndex == GOAL_25000) { return 25000; }
        else if (goalIndex == GOAL_30000) { return 30000; }
        else if (goalIndex == GOAL_35000) { return 35000; }
        else if (goalIndex == GOAL_40000) { return 40000; }
        else if (goalIndex == GOAL_50000) { return 50000; }
        else if (goalIndex == GOAL_60000) { return 60000; }

        // Active Minutes goals
        else if (goalIndex == GOAL_1_MIN) { return 1; }
        else if (goalIndex == GOAL_3_MIN) { return 3; }
        else if (goalIndex == GOAL_5_MIN) { return 5; }
        else if (goalIndex == GOAL_10_MIN) { return 10; }
        else if (goalIndex == GOAL_15_MIN) { return 15; }
        else if (goalIndex == GOAL_20_MIN) { return 20; }
        else if (goalIndex == GOAL_30_MIN) { return 30; }
        else if (goalIndex == GOAL_45) { return 45; }
        else if (goalIndex == GOAL_60_MIN) { return 60; }
        else if (goalIndex == GOAL_90) { return 90; }
        else if (goalIndex == GOAL_120_MIN) { return 120; }
        else if (goalIndex == GOAL_150) { return 150; }
        else if (goalIndex == GOAL_180_MIN) { return 180; }
        else if (goalIndex == GOAL_240) { return 240; }
        else if (goalIndex == GOAL_300) { return 300; }

        // Calories goals
        else if (goalIndex == GOAL_50_CAL) { return 50; }
        else if (goalIndex == GOAL_100_CAL) { return 100; }
        else if (goalIndex == GOAL_150_CAL) { return 150; }
        else if (goalIndex == GOAL_200_CAL) { return 200; }
        else if (goalIndex == GOAL_300_CAL) { return 300; }
        else if (goalIndex == GOAL_600) { return 600; }
        else if (goalIndex == GOAL_800) { return 800; }
        else if (goalIndex == GOAL_1000_CAL) { return 1000; }
        else if (goalIndex == GOAL_1200) { return 1200; }
        else if (goalIndex == GOAL_1500_CAL) { return 1500; }
        else if (goalIndex == GOAL_1800) { return 1800; }
        else if (goalIndex == GOAL_2000_CAL) { return 2000; }
        else if (goalIndex == GOAL_2200) { return 2200; }
        else if (goalIndex == GOAL_2500) { return 2500; }
        else if (goalIndex == GOAL_3000_CAL) { return 3000; }
        else if (goalIndex == GOAL_3500) { return 3500; }
        else if (goalIndex == GOAL_4000_CAL) { return 4000; }

        // Floors goals
        else if (goalIndex == GOAL_0_FLOORS) { return 0; }
        else if (goalIndex == GOAL_1_FLOOR) { return 1; }
        else if (goalIndex == GOAL_2_FLOORS) { return 2; }
        else if (goalIndex == GOAL_3_FLOORS) { return 3; }
        else if (goalIndex == GOAL_5_FLOORS) { return 5; }
        else if (goalIndex == GOAL_10_FLOORS) { return 10; }
        else if (goalIndex == GOAL_15_FLOORS) { return 15; }
        else if (goalIndex == GOAL_20_FLOORS) { return 20; }
        else if (goalIndex == GOAL_25_FLOORS) { return 25; }
        else if (goalIndex == GOAL_30_FLOORS) { return 30; }
        else if (goalIndex == GOAL_40_FLOORS) { return 40; }
        else if (goalIndex == GOAL_50_FLOORS) { return 50; }
        else if (goalIndex == GOAL_75_FLOORS) { return 75; }
        else if (goalIndex == GOAL_100_FLOORS) { return 100; }

        // Distance goals (km)
        else if (goalIndex == GOAL_0_2_KM) { return 0.2; }
        else if (goalIndex == GOAL_0_5_KM) { return 0.5; }
        else if (goalIndex == GOAL_1_KM) { return 1.0; }
        else if (goalIndex == GOAL_1_5_KM) { return 1.5; }
        else if (goalIndex == GOAL_2_KM_DIST) { return 2.0; }
        else if (goalIndex == GOAL_2_5_KM) { return 2.5; }
        else if (goalIndex == GOAL_5_KM_DIST) { return 5.0; }
        else if (goalIndex == GOAL_7_5_KM) { return 7.5; }
        else if (goalIndex == GOAL_10_KM_DIST) { return 10.0; }
        else if (goalIndex == GOAL_15_KM) { return 15.0; }
        else if (goalIndex == GOAL_20_KM_DIST) { return 20.0; }
        else if (goalIndex == GOAL_25_KM) { return 25.0; }
        else if (goalIndex == GOAL_30_KM) { return 30.0; }
        else if (goalIndex == GOAL_40_KM) { return 40.0; }
        else if (goalIndex == GOAL_42_KM) { return 42.0; }

        // Elevation goals (meters)
        else if (goalIndex == GOAL_5M) { return 5.0; }
        else if (goalIndex == GOAL_10M) { return 10.0; }
        else if (goalIndex == GOAL_20M) { return 20.0; }
        else if (goalIndex == GOAL_30M) { return 30.0; }
        else if (goalIndex == GOAL_50M) { return 50.0; }
        else if (goalIndex == GOAL_100M_ELEV) { return 100.0; }
        else if (goalIndex == GOAL_200M_ELEV) { return 200.0; }
        else if (goalIndex == GOAL_500M_ELEV) { return 500.0; }
        else if (goalIndex == GOAL_1000M_ELEV) { return 1000.0; }
        else if (goalIndex == GOAL_1500M_ELEV) { return 1500.0; }
        else if (goalIndex == GOAL_2000M_ELEV) { return 2000.0; }
        else if (goalIndex == GOAL_2500M) { return 2500.0; }
        else if (goalIndex == GOAL_3000M_ELEV) { return 3000.0; }

        // Respiration goals (breaths/min)
        else if (goalIndex == GOAL_10_RESP) { return 10; }
        else if (goalIndex == GOAL_12_RESP) { return 12; }
        else if (goalIndex == GOAL_14_RESP) { return 14; }
        else if (goalIndex == GOAL_16_RESP) { return 16; }
        else if (goalIndex == GOAL_18_RESP) { return 18; }
        else if (goalIndex == GOAL_20_RESP) { return 20; }
        else if (goalIndex == GOAL_22_RESP) { return 22; }

        return 0;
    }

    //! Reads the configurable arc settings from application properties.
    //! This function initializes the gArcConfigurations array with the user's selected
    //! data types, colors, and goals for each of the 5 polar arcs.
    function readArcConfigurations() as Void {
        var configurations = [] as Array<Dictionary<Symbol, Number>>;

        for (var i = 1; i <= 5; i++) {
            var dataTypeKey = "Arc" + i.toString() + "DataType";
            var colorKey = "Arc" + i.toString() + "Color";
            var goalKey = "Arc" + i.toString() + "Goal";

            var dataType = Application.Properties.getValue(dataTypeKey) as Number;
            var color = Application.Properties.getValue(colorKey) as Number;
            var goal = Application.Properties.getValue(goalKey) as Number;

            configurations.add({
                :dataType => dataType,
                :color => color,
                :goal => goal
            });
        }

        GlobalVariables.gArcConfigurations = configurations;
    }

    //! Populates the data for the polar arcs based on user configuration.
    //! Each arc can display different data types with user-selected colors.
    function updatePolarArcsData() as Void {
        var arcsData = [] as Array<Dictionary<Symbol, Number or Graphics.ColorType>>;
        var configurations = GlobalVariables.gArcConfigurations;

        if (configurations == null) {
            return;
        }

        for (var i = 0; i < configurations.size(); i++) {
            var config = configurations[i] as Dictionary<Symbol, Number>;
            var dataType = config[:dataType] as Number;
            var colorIndex = config[:color] as Number;
            var goalIndex = config[:goal] as Number;

            // Skip if data type is None
            if (dataType == DATA_TYPE_NONE) {
                continue;
            }

            // Get the percentage value for this data type
            var percentage = getDataTypePercentage(dataType, goalIndex);
            if (percentage == null) {
                continue;
            }

            // Get the color for this arc
            var color = ThemeUtils.getColorByIndex(colorIndex);

            arcsData.add({
                :percentage => percentage,
                :color => color
            });
        }

        GlobalVariables.gSortedPolarArcs = arcsData;
    }

    //! Gets the percentage value for a given data type and goal.
    //! @param dataType The data type number (0-9).
    //! @param goalIndex The goal index (0 for auto, or specific goal value).
    //! @return The percentage value (0-100) or null if data is unavailable.
    function getDataTypePercentage(dataType as Number, goalIndex as Number) as Number or Null {
        if (dataType == DATA_TYPE_BODY_BATTERY) {
            return GlobalVariables.gBodyBattery;
        } else if (dataType == DATA_TYPE_STRESS) {
            return GlobalVariables.gStressLevel;
        } else if (dataType == DATA_TYPE_STEPS) {
            var goal = (goalIndex == GOAL_AUTO) ? GlobalVariables.gStepGoal : getGoalValue(goalIndex) as Number;
            if (GlobalVariables.gSteps != null && goal != null && goal > 0) {
                var percentage = (GlobalVariables.gSteps.toFloat() / goal.toFloat()) * 100.0f;
                return percentage.toNumber();
            }
            return null;
        } else if (dataType == DATA_TYPE_CALORIES) {
            var goal = (goalIndex == GOAL_AUTO) ? GlobalVariables.gCalorieGoal : getGoalValue(goalIndex) as Number;
            if (GlobalVariables.gCalories != null && goal != null && goal > 0) {
                var percentage = (GlobalVariables.gCalories.toFloat() / goal.toFloat()) * 100.0f;
                return percentage.toNumber();
            }
            return null;
        } else if (dataType == DATA_TYPE_ACTIVE_MINUTES) {
            var goal = (goalIndex == GOAL_AUTO) ? GlobalVariables.gActiveMinutesGoal : getGoalValue(goalIndex) as Number;
            if (GlobalVariables.gActiveMinutesRaw != null && goal != null && goal > 0) {
                var percentage = (GlobalVariables.gActiveMinutesRaw.toFloat() / goal.toFloat()) * 100.0f;
                return percentage.toNumber();
            }
            return null;
        } else if (dataType == DATA_TYPE_FLOORS_CLIMBED) {
            var goal = (goalIndex == GOAL_AUTO) ? GlobalVariables.gFloorsClimbedGoal : getGoalValue(goalIndex) as Number;
            if (GlobalVariables.gFloorsClimbed != null && goal != null && goal > 0) {
                var percentage = (GlobalVariables.gFloorsClimbed.toFloat() / goal.toFloat()) * 100.0f;
                return percentage.toNumber();
            }
            return null;
        } else if (dataType == DATA_TYPE_DISTANCE) {
            var goal = (goalIndex == GOAL_AUTO) ? GlobalVariables.gDistanceGoal : getGoalValue(goalIndex) as Float;
            if (GlobalVariables.gDistance != null && goal != null && goal > 0) {
                var percentage = (GlobalVariables.gDistance / goal) * 100.0f;
                return percentage.toNumber();
            }
            return null;
        } else if (dataType == DATA_TYPE_ELEVATION_GAIN) {
            var goal = (goalIndex == GOAL_AUTO) ? GlobalVariables.gElevationGainGoal : getGoalValue(goalIndex) as Float;
            if (GlobalVariables.gElevationGain != null && goal != null && goal > 0) {
                var percentage = (GlobalVariables.gElevationGain / goal) * 100.0f;
                return percentage.toNumber();
            }
            return null;
        } else if (dataType == DATA_TYPE_RESPIRATION_RATE) {
            // Respiration rate is an absolute value, not a percentage
            // We'll normalize it to a 0-100 scale (assuming 8-32 breaths/min is normal range)
            if (GlobalVariables.gRespirationRate != null) {
                var rate = GlobalVariables.gRespirationRate;
                if (rate >= 32.0f) {
                    return 100;
                } else if (rate <= 8.0f) {
                    return 0;
                } else {
                    return ((rate - 8.0f) / (32.0f - 8.0f) * 100.0f).toNumber();
                }
            }
            return null;
        }
        return null;
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
