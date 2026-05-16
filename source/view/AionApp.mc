import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

using $.DataManager;

//! Main application class for the watch face.
//! Handles application lifecycle events such as startup, shutdown, and settings changes.
class Aion extends Application.AppBase {

    //! Constructor for the application.
    function initialize() {
        AppBase.initialize();
    }

    //! onStart() is called on application start up.
    //! @param state The application state dictionary.
    function onStart(state as Dictionary or Null) as Void {
    }

    //! onStop() is called when your application is exiting.
    //! @param state The application state dictionary.
    function onStop(state as Dictionary or Null) as Void {
    }

    //! Return the initial view of your application here.
    //! @return An array containing the main view for the watch face.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new AionView() ];
    }

    //! Returns the settings view and delegate for on-device settings.
    //! This allows users to configure the watch face directly on the device.
    //! @return An array containing the settings menu and its input delegate.
    function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new AionSettingsMenu(), new AionSettingsMenuDelegate()];
    }

    //! Called when new application settings have been received.
    //! Re-reads arc configurations and triggers a UI update.
    function onSettingsChanged() as Void {
        DataManager.onSettingsChanged();
        WatchUi.requestUpdate();
    }

}

//! Gets a reference to the current application object.
//! @return The main application instance.
function getApp() as Aion {
    return Application.getApp() as Aion;
}
