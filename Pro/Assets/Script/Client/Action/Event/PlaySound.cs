using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

/// <summary>
/// ≤•∑≈“Ù–ß
/// </summary>
public class PlaySound : GameEvent
{
    string mResName = string.Empty;
    bool mBGM = true;

    /// <summary>
    /// ≤•∑≈…˘“Ù
    /// </summary>
    /// <param name="resName"></param>
    /// <param name="isBgm"></param>
    public PlaySound(string resName, bool isBgm = false)
    {
        mResName = resName;
        mBGM = isBgm;
    }

    public override void Execute()
    {
        if (mBGM)
            Music.Instance.Play(mResName);
        else
            Audio.Instance.Play(mResName);
    }
}
