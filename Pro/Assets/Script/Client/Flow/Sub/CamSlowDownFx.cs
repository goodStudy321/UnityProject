using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

/// <summary>
/// AU:Loong
/// TM:2015.11.20,10:52:49
/// CO:nuolan1.ActionSoso1
/// BG:相机慢镜头特效
/// </summary>
public class CamSlowDownFx : CamFxBase
{
    #region 字段
    private float originTimeScale = 1;

    private AnimationCurve scaleCurve = null;

    private float processTime;

    private float duration;

    public event Action callBack;

    #endregion

    #region 属性

    #endregion

    #region 构造方法
    public CamSlowDownFx()
    {

    }

    public CamSlowDownFx(Action callBack)
    {
        this.callBack = callBack;
    }

    #endregion

    #region 私有方法

    private void DefaultSetting()
    {
        Time.timeScale = 0.15f;
        duration = 1.5f;
    }

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法

    public override void Initialize()
    {
        if (scaleCurve != null) return;
        originTimeScale = Time.timeScale;
        //scaleCurve = Global.monoData.GetAnimationCurveValue("CSDF.curve");
        if (scaleCurve == null) { DefaultSetting(); return; }

        int length = scaleCurve.keys.Length;
        if (length == 0) DefaultSetting();
        else duration = scaleCurve.keys[length - 1].time;

    }

    public override void Execute()
    {
        if (scaleCurve == null) return;
        processTime += Time.unscaledDeltaTime * 0.2f;
        if (processTime < duration) Time.timeScale = scaleCurve.Evaluate(processTime);
        else if (callBack != null) { callBack(); }
    }

    public override void Reset()
    {
        processTime = 0;
        Time.timeScale = originTimeScale;
    }

    #endregion
}