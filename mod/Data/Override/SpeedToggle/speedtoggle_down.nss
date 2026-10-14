//------------------------------------------------------------------------------------------------------------------------
// speedtoggle_down.nss - steps Geralt's movement speed preset down (wraps to +90% below Normal).
// Bound to a hotkey by System\Scripts\testtools.lua (default: B).
//------------------------------------------------------------------------------------------------------------------------

#include "inc_speedtoggle"

void main()
{
    StepSpeedPreset(-1);
}
