import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

using $.DataManager;

//! Converts a goal index to its display name.
//! @param goalIndex The goal constant index.
//! @return The display name string for the goal.
function getGoalName(goalIndex as Number) as String {
    if (goalIndex == 0) { return "Auto"; }

    // Steps goals
    else if (goalIndex == 1) { return "500"; }
    else if (goalIndex == 2) { return "1,000"; }
    else if (goalIndex == 3) { return "2,000"; }
    else if (goalIndex == 4) { return "3,000"; }
    else if (goalIndex == 5) { return "4,000"; }
    else if (goalIndex == 6) { return "5,000"; }
    else if (goalIndex == 7) { return "7,500"; }
    else if (goalIndex == 8) { return "10,000"; }
    else if (goalIndex == 9) { return "12,500"; }
    else if (goalIndex == 10) { return "15,000"; }
    else if (goalIndex == 11) { return "20,000"; }
    else if (goalIndex == 12) { return "25,000"; }
    else if (goalIndex == 13) { return "30,000"; }
    else if (goalIndex == 14) { return "35,000"; }
    else if (goalIndex == 15) { return "40,000"; }
    else if (goalIndex == 16) { return "50,000"; }
    else if (goalIndex == 17) { return "60,000"; }

    // Active Minutes goals
    else if (goalIndex == 18) { return "1"; }
    else if (goalIndex == 19) { return "3"; }
    else if (goalIndex == 20) { return "5"; }
    else if (goalIndex == 21) { return "10"; }
    else if (goalIndex == 22) { return "15"; }
    else if (goalIndex == 23) { return "20"; }
    else if (goalIndex == 24) { return "30"; }
    else if (goalIndex == 25) { return "45"; }
    else if (goalIndex == 26) { return "60"; }
    else if (goalIndex == 27) { return "90"; }
    else if (goalIndex == 28) { return "120"; }
    else if (goalIndex == 29) { return "150"; }
    else if (goalIndex == 30) { return "180"; }
    else if (goalIndex == 31) { return "240"; }
    else if (goalIndex == 32) { return "300"; }

    // Calories goals
    else if (goalIndex == 33) { return "50"; }
    else if (goalIndex == 34) { return "100"; }
    else if (goalIndex == 35) { return "150"; }
    else if (goalIndex == 36) { return "200"; }
    else if (goalIndex == 37) { return "300"; }
    else if (goalIndex == 38) { return "600"; }
    else if (goalIndex == 39) { return "800"; }
    else if (goalIndex == 40) { return "1,000"; }
    else if (goalIndex == 41) { return "1,200"; }
    else if (goalIndex == 42) { return "1,500"; }
    else if (goalIndex == 43) { return "1,800"; }
    else if (goalIndex == 44) { return "2,000"; }
    else if (goalIndex == 45) { return "2,200"; }
    else if (goalIndex == 46) { return "2,500"; }
    else if (goalIndex == 47) { return "3,000"; }
    else if (goalIndex == 48) { return "3,500"; }
    else if (goalIndex == 49) { return "4,000"; }

    // Floors goals
    else if (goalIndex == 50) { return "0"; }
    else if (goalIndex == 51) { return "1"; }
    else if (goalIndex == 52) { return "2"; }
    else if (goalIndex == 53) { return "3"; }
    else if (goalIndex == 54) { return "5"; }
    else if (goalIndex == 55) { return "10"; }
    else if (goalIndex == 56) { return "15"; }
    else if (goalIndex == 57) { return "20"; }
    else if (goalIndex == 58) { return "25"; }
    else if (goalIndex == 59) { return "30"; }
    else if (goalIndex == 60) { return "40"; }
    else if (goalIndex == 61) { return "50"; }
    else if (goalIndex == 62) { return "75"; }
    else if (goalIndex == 63) { return "100"; }

    // Distance goals (km)
    else if (goalIndex == 64) { return "0.2km"; }
    else if (goalIndex == 65) { return "0.5km"; }
    else if (goalIndex == 66) { return "1km"; }
    else if (goalIndex == 67) { return "1.5km"; }
    else if (goalIndex == 68) { return "2km"; }
    else if (goalIndex == 69) { return "2.5km"; }
    else if (goalIndex == 70) { return "5km"; }
    else if (goalIndex == 71) { return "7.5km"; }
    else if (goalIndex == 72) { return "10km"; }
    else if (goalIndex == 73) { return "15km"; }
    else if (goalIndex == 74) { return "20km"; }
    else if (goalIndex == 75) { return "25km"; }
    else if (goalIndex == 76) { return "30km"; }
    else if (goalIndex == 77) { return "40km"; }
    else if (goalIndex == 78) { return "42km"; }

    // Elevation goals (meters)
    else if (goalIndex == 79) { return "5m"; }
    else if (goalIndex == 80) { return "10m"; }
    else if (goalIndex == 81) { return "20m"; }
    else if (goalIndex == 82) { return "30m"; }
    else if (goalIndex == 83) { return "50m"; }
    else if (goalIndex == 84) { return "100m"; }
    else if (goalIndex == 85) { return "200m"; }
    else if (goalIndex == 86) { return "500m"; }
    else if (goalIndex == 87) { return "1,000m"; }
    else if (goalIndex == 88) { return "1,500m"; }
    else if (goalIndex == 89) { return "2,000m"; }
    else if (goalIndex == 90) { return "2,500m"; }
    else if (goalIndex == 91) { return "3,000m"; }

    // Respiration goals (breaths/min)
    else if (goalIndex == 92) { return "10"; }
    else if (goalIndex == 93) { return "12"; }
    else if (goalIndex == 94) { return "14"; }
    else if (goalIndex == 95) { return "16"; }
    else if (goalIndex == 96) { return "18"; }
    else if (goalIndex == 97) { return "20"; }
    else if (goalIndex == 98) { return "22"; }

    return "Unknown";
}

//! Main settings menu for configuring polar arcs.
class AionSettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Arc Settings"});

        // Add menu items for each arc
        addItem(new WatchUi.MenuItem("Arc 1", getArcSummary(1), :arc1, {}));
        addItem(new WatchUi.MenuItem("Arc 2", getArcSummary(2), :arc2, {}));
        addItem(new WatchUi.MenuItem("Arc 3", getArcSummary(3), :arc3, {}));
        addItem(new WatchUi.MenuItem("Arc 4", getArcSummary(4), :arc4, {}));
        addItem(new WatchUi.MenuItem("Arc 5", getArcSummary(5), :arc5, {}));
    }

    //! Gets a summary string for an arc's current configuration.
    function getArcSummary(arcIndex as Number) as String {
        var dataTypeKey = "Arc" + arcIndex.toString() + "DataType";
        var dataType = Application.Properties.getValue(dataTypeKey) as Number;
        return getDataTypeName(dataType);
    }

    //! Converts data type index to display name.
    function getDataTypeName(dataType as Number) as String {
        if (dataType == 0) { return "None"; }
        else if (dataType == 1) { return "Body Battery"; }
        else if (dataType == 2) { return "Stress"; }
        else if (dataType == 3) { return "Steps"; }
        else if (dataType == 4) { return "Calories"; }
        else if (dataType == 5) { return "Active Min"; }
        else if (dataType == 6) { return "Floors"; }
        else if (dataType == 7) { return "Distance"; }
        else if (dataType == 8) { return "Elevation"; }
        else if (dataType == 9) { return "Respiration"; }
        return "Unknown";
    }
}

//! Delegate for the main settings menu.
class AionSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var arcIndex = 0;

        if (id == :arc1) { arcIndex = 1; }
        else if (id == :arc2) { arcIndex = 2; }
        else if (id == :arc3) { arcIndex = 3; }
        else if (id == :arc4) { arcIndex = 4; }
        else if (id == :arc5) { arcIndex = 5; }

        if (arcIndex > 0) {
            // Push the arc configuration submenu
            WatchUi.pushView(
                new ArcConfigMenu(arcIndex),
                new ArcConfigMenuDelegate(arcIndex),
                WatchUi.SLIDE_LEFT
            );
        }
    }

    function onBack() as Void {
        // Reload settings and update watch face
        DataManager.onSettingsChanged();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

//! Submenu for configuring a specific arc.
class ArcConfigMenu extends WatchUi.Menu2 {
    function initialize(arcIndex as Number) {
        Menu2.initialize({:title => "Arc " + arcIndex.toString()});

        var dataTypeKey = "Arc" + arcIndex.toString() + "DataType";
        var colorKey = "Arc" + arcIndex.toString() + "Color";
        var goalKey = "Arc" + arcIndex.toString() + "Goal";
        var currentDataType = Application.Properties.getValue(dataTypeKey) as Number;
        var currentColor = Application.Properties.getValue(colorKey) as Number;
        var currentGoal = Application.Properties.getValue(goalKey) as Number;

        addItem(new WatchUi.MenuItem("Data Type", getDataTypeName(currentDataType), :dataType, {}));
        addItem(new WatchUi.MenuItem("Color", getColorName(currentColor), :color, {}));
        addItem(new WatchUi.MenuItem("Goal", getGoalName(currentGoal), :goal, {}));
    }

    function getDataTypeName(dataType as Number) as String {
        if (dataType == 0) { return "None"; }
        else if (dataType == 1) { return "Body Battery"; }
        else if (dataType == 2) { return "Stress"; }
        else if (dataType == 3) { return "Steps"; }
        else if (dataType == 4) { return "Calories"; }
        else if (dataType == 5) { return "Active Min"; }
        else if (dataType == 6) { return "Floors"; }
        else if (dataType == 7) { return "Distance"; }
        else if (dataType == 8) { return "Elevation"; }
        else if (dataType == 9) { return "Respiration"; }
        return "Unknown";
    }

    function getColorName(colorIndex as Number) as String {
        if (colorIndex == 0) { return "Orange-Red"; }
        else if (colorIndex == 1) { return "Light Green"; }
        else if (colorIndex == 2) { return "Light Blue"; }
        else if (colorIndex == 3) { return "Yellow"; }
        else if (colorIndex == 4) { return "Pink"; }
        else if (colorIndex == 5) { return "Cyan"; }
        else if (colorIndex == 6) { return "White"; }
        else if (colorIndex == 7) { return "Gray"; }
        else if (colorIndex == 8) { return "Orange"; }
        else if (colorIndex == 9) { return "Purple"; }
        else if (colorIndex == 10) { return "Blue"; }
        else if (colorIndex == 11) { return "Dark Green"; }
        else if (colorIndex == 12) { return "Brown"; }
        else if (colorIndex == 13) { return "Magenta"; }
        else if (colorIndex == 14) { return "Light Gray"; }
        else if (colorIndex == 15) { return "Navy Blue"; }
        return "Unknown";
    }

}

//! Delegate for arc configuration submenu.
class ArcConfigMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mArcIndex as Number;

    function initialize(arcIndex as Number) {
        Menu2InputDelegate.initialize();
        mArcIndex = arcIndex;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :dataType) {
            WatchUi.pushView(
                new DataTypePickerMenu(mArcIndex),
                new DataTypePickerDelegate(mArcIndex),
                WatchUi.SLIDE_LEFT
            );
        } else if (id == :color) {
            WatchUi.pushView(
                new ColorPickerMenu(mArcIndex),
                new ColorPickerDelegate(mArcIndex),
                WatchUi.SLIDE_LEFT
            );
        } else if (id == :goal) {
            WatchUi.pushView(
                new GoalPickerMenu(mArcIndex),
                new GoalPickerDelegate(mArcIndex),
                WatchUi.SLIDE_LEFT
            );
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

//! Menu for selecting data type.
class DataTypePickerMenu extends WatchUi.Menu2 {
    function initialize(arcIndex as Number) {
        Menu2.initialize({:title => "Data Type"});

        addItem(new WatchUi.MenuItem("None", null, 0, {}));
        addItem(new WatchUi.MenuItem("Body Battery", null, 1, {}));
        addItem(new WatchUi.MenuItem("Stress", null, 2, {}));
        addItem(new WatchUi.MenuItem("Steps", null, 3, {}));
        addItem(new WatchUi.MenuItem("Calories", null, 4, {}));
        addItem(new WatchUi.MenuItem("Active Minutes", null, 5, {}));
        addItem(new WatchUi.MenuItem("Floors Climbed", null, 6, {}));
        addItem(new WatchUi.MenuItem("Distance", null, 7, {}));
        addItem(new WatchUi.MenuItem("Elevation Gain", null, 8, {}));
        addItem(new WatchUi.MenuItem("Respiration", null, 9, {}));
    }
}

//! Delegate for data type picker.
class DataTypePickerDelegate extends WatchUi.Menu2InputDelegate {
    private var mArcIndex as Number;

    function initialize(arcIndex as Number) {
        Menu2InputDelegate.initialize();
        mArcIndex = arcIndex;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var dataType = item.getId() as Number;
        var key = "Arc" + mArcIndex.toString() + "DataType";
        Application.Properties.setValue(key, dataType);
        DataManager.onSettingsChanged();
        WatchUi.requestUpdate();
        WatchUi.pushView(new ArcConfigMenu(mArcIndex), new ArcConfigMenuDelegate(mArcIndex), WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

//! Menu for selecting color.
class ColorPickerMenu extends WatchUi.Menu2 {
    function initialize(arcIndex as Number) {
        Menu2.initialize({:title => "Color"});

        addItem(new WatchUi.MenuItem("Orange-Red", null, 0, {}));
        addItem(new WatchUi.MenuItem("Light Green", null, 1, {}));
        addItem(new WatchUi.MenuItem("Light Blue", null, 2, {}));
        addItem(new WatchUi.MenuItem("Yellow", null, 3, {}));
        addItem(new WatchUi.MenuItem("Pink", null, 4, {}));
        addItem(new WatchUi.MenuItem("Cyan", null, 5, {}));
        addItem(new WatchUi.MenuItem("White", null, 6, {}));
        addItem(new WatchUi.MenuItem("Gray", null, 7, {}));
        addItem(new WatchUi.MenuItem("Orange", null, 8, {}));
        addItem(new WatchUi.MenuItem("Purple", null, 9, {}));
        addItem(new WatchUi.MenuItem("Blue", null, 10, {}));
        addItem(new WatchUi.MenuItem("Dark Green", null, 11, {}));
        addItem(new WatchUi.MenuItem("Brown", null, 12, {}));
        addItem(new WatchUi.MenuItem("Magenta", null, 13, {}));
        addItem(new WatchUi.MenuItem("Light Gray", null, 14, {}));
        addItem(new WatchUi.MenuItem("Navy Blue", null, 15, {}));
    }
}

//! Delegate for color picker.
class ColorPickerDelegate extends WatchUi.Menu2InputDelegate {
    private var mArcIndex as Number;

    function initialize(arcIndex as Number) {
        Menu2InputDelegate.initialize();
        mArcIndex = arcIndex;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var colorIndex = item.getId() as Number;
        var key = "Arc" + mArcIndex.toString() + "Color";
        Application.Properties.setValue(key, colorIndex);
        DataManager.onSettingsChanged();
        WatchUi.requestUpdate();
        WatchUi.pushView(new ArcConfigMenu(mArcIndex), new ArcConfigMenuDelegate(mArcIndex), WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

//! Menu for selecting goal.
class GoalPickerMenu extends WatchUi.Menu2 {
    function initialize(arcIndex as Number) {
        Menu2.initialize({:title => "Goal"});

        // Get current data type to determine available goals
        var dataTypeKey = "Arc" + arcIndex.toString() + "DataType";
        var dataType = Application.Properties.getValue(dataTypeKey) as Number;

        // Get available goals for this data type from DataManager
        var availableGoals = $.DataManager.getAvailableGoalsForDataType(dataType);

        // Add menu items for available goals
        for (var i = 0; i < availableGoals.size(); i++) {
            var goalIndex = availableGoals[i];
            addItem(new WatchUi.MenuItem(getGoalName(goalIndex), null, goalIndex, {}));
        }
    }
}

//! Delegate for goal picker.
class GoalPickerDelegate extends WatchUi.Menu2InputDelegate {
    private var mArcIndex as Number;

    function initialize(arcIndex as Number) {
        Menu2InputDelegate.initialize();
        mArcIndex = arcIndex;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var goalIndex = item.getId() as Number;
        var key = "Arc" + mArcIndex.toString() + "Goal";
        Application.Properties.setValue(key, goalIndex);
        $.DataManager.onSettingsChanged();
        WatchUi.requestUpdate();
        WatchUi.pushView(new ArcConfigMenu(mArcIndex), new ArcConfigMenuDelegate(mArcIndex), WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
