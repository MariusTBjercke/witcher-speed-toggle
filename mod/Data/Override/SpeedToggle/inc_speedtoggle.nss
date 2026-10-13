//------------------------------------------------------------------------------------------------------------------------
// inc_speedtoggle.nss - shared logic for speedtoggle (step up) and speedtoggle_down (step down).
// Presets: Normal -> +15% -> +30% -> +50% -> +70%, wrapping around at both ends.
//------------------------------------------------------------------------------------------------------------------------

const string SPEEDTOGGLE_VAR = "MOD_SPEEDTOGGLE_LEVEL";
const int SPEEDTOGGLE_LEVELS = 5;

// Movement speed bonus (percent) for each preset level.
int GetPresetPercent(int nLevel)
{
    if (nLevel == 1) return 15;
    if (nLevel == 2) return 30;
    if (nLevel == 3) return 50;
    if (nLevel == 4) return 70;
    return 0;
}

// Removes only the speed effects this mod applied (permanent + supernatural),
// so speed changes from the game itself are left alone.
void RemoveSpeedToggleEffects(object oPC)
{
    int nOurSubType = GetEffectSubType(SupernaturalEffect(EffectMovementSpeedIncrease(1)));

    effect eLoop = GetFirstEffect(oPC);
    while (GetIsEffectValid(eLoop))
    {
        if (GetEffectType(eLoop) == EFFECT_TYPE_MOVEMENT_SPEED_INCREASE
            && GetEffectDurationType(eLoop) == DURATION_TYPE_PERMANENT
            && GetEffectSubType(eLoop) == nOurSubType)
        {
            RemoveEffect(oPC, eLoop);
        }
        eLoop = GetNextEffect(oPC);
    }
}

// Moves the preset by nStep (+1 or -1), applies it and shows it in the feedback line.
void StepSpeedPreset(int nStep)
{
    object oPC = GetFirstPC();
    if (!GetIsObjectValid(oPC)) return;

    int nLevel = (GetLocalInt(oPC, SPEEDTOGGLE_VAR) + nStep + SPEEDTOGGLE_LEVELS) % SPEEDTOGGLE_LEVELS;
    SetLocalInt(oPC, SPEEDTOGGLE_VAR, nLevel);

    RemoveSpeedToggleEffects(oPC);

    int nPercent = GetPresetPercent(nLevel);
    string sLabel = "Speed: Normal";
    if (nPercent > 0)
    {
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, SupernaturalEffect(EffectMovementSpeedIncrease(nPercent)), oPC);
        sLabel = "Speed: +" + IntToString(nPercent) + "%";
    }

    // Show it in the game's feedback line (floating text vanishes too quickly).
    RunClientLua("g_GuiInGame:ShowGameInfo('feedback', '" + sLabel + "')");
}
