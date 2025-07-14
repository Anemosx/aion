import Toybox.Graphics;
import Toybox.WatchUi;

using $.PolarDraw;
using $.ClockDraw;
using $.DataDraw;
using $.AionIcons;
using $.GlobalVariables;
using $.BurnInProtection;
using $.LayoutManager;
using $.DataManager;

//! The primary view for the watch face, responsible for managing the rendering pipeline and
//! handling the display's lifecycle events (show, hide, enter/exit sleep).
class AionView extends WatchUi.WatchFace {
    //! Constructor. Initializes the watch face view.
    function initialize() {
        WatchFace.initialize();
    }

    //! Configure the layout of the watch face and load resources.
    //! @param dc Device context
    function onLayout(dc as Dc) as Void {
        LayoutManager.initialize(dc);
        AionIcons.loadIcons();
        DataManager.initializeData();
    }

    //! Called when this View is brought to the foreground. Stub for future use.
    function onShow() as Void {
        AionIcons.loadIcons();
    }

    //! Called for every screen update. This is where the drawing happens.
    //! @param dc Device context
    function onUpdate(dc as Dc) as Void {
        BurnInProtection.updateOffsets();

        // Fallback to re-initialize layout if it was not done before.
        if (GlobalVariables.gUi[:deviceWidth] == null) {
            LayoutManager.initialize(dc);
        }

        DataManager.updateAllData();

        // Draw the layout defined in the resources
        View.onUpdate(dc);
        PolarDraw.drawData(dc);
        ClockDraw.drawClock(dc);
        DataDraw.drawData(dc);
        PolarDraw.drawBattery(dc);
        PolarDraw.drawRecoveryMarker(dc);
    }

    //! Called when this View is removed from the screen. Can be used to release resources.
    function onHide() as Void {
        AionIcons.releaseIcons();
    }

    //! The user has just looked at their watch. Request a full screen update.
    function onExitSleep() as Void {
        GlobalVariables.gIsAwake = true;
        WatchUi.requestUpdate();
    }

    //! The watch is entering sleep mode. No explicit action needed here,
    //! as the system handles reducing update frequency.
    function onEnterSleep() as Void {
        GlobalVariables.gIsAwake = false;
        WatchUi.requestUpdate();
    }
}
