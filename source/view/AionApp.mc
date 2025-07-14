import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

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

    //! Called when new application settings have been received.
    //! Triggers a UI update to apply the new settings.
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

}

//! Gets a reference to the current application object.
//! @return The main application instance.
function getApp() as Aion {
    return Application.getApp() as Aion;
}
