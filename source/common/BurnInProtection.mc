using $.GlobalVariables;

//! This module provides functionality to mitigate screen burn-in on AMOLED displays
//! by periodically shifting the position of screen elements.
module BurnInProtection {
    //! Updates the burn-in protection offsets.
    //! This function should be called periodically (e.g., once per minute on partial updates)
    //! to cycle through the offset sequence.
    function updateOffsets() as Void {
        GlobalVariables.gBurnInProtectionTick++;
        if (GlobalVariables.gBurnInProtectionTick % GlobalVariables.BURN_IN_UPDATE_INTERVAL == 0) {
            var sequenceIndex = (GlobalVariables.gBurnInProtectionTick / GlobalVariables.BURN_IN_UPDATE_INTERVAL) % GlobalVariables.BURN_IN_OFFSET_SEQUENCE.size();
            GlobalVariables.gBurnInRadiusOffset = GlobalVariables.BURN_IN_OFFSET_SEQUENCE[sequenceIndex];
        }
    }
}
