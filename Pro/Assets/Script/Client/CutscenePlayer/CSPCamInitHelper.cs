using System;
using UnityEngine;
#if UNITY_EDITOR
    using UnityEditor;
    using System.IO;
#endif
//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine.SceneManagement;

using Loong.Game;
using taecg.tools.mobileFastShadow;
using SleekRender;
using Slate;

[ExecuteInEditMode]
public class CSPCamInitHelper : MonoBehaviour
{
    /// <summary>
    /// 动画渲染摄像机
    /// </summary>
    public Camera mCSPCamera;
    /// <summary>
    /// 特效摄像机
    /// </summary>
    public Camera mFxCamera;
    /// <summary>
    /// 
    /// </summary>
    public MobileFastShadow mMFShadow;
    /// <summary>
    /// 
    /// </summary>
    public SleekRenderPostProcess mSRPostProcess;
    /// <summary>
    /// Ngui根节点
    /// </summary>
    //public GameObject mUIRoot;
    /// <summary>
    /// Bloom后期控件
    /// </summary>
    //private AmplifyBloomEffect mABEPre = null;
    /// <summary>
    /// Bloom后期控件
    /// </summary>
    private DirectorGUI mDGUI = null;

    public float shakeTime = 0.5f;
    public float shakeFrequence = 90f;
    public float shakeAmplitude = 30f;
    private bool camShake = false;

    private int curEvnt = 0;


    #region AmplifyBloomEffect插件
    ///// <summary>
    ///// 
    ///// </summary>
    //public float BloomIntensity
    //{
    //    get
    //    {
    //        float retVal = 0f;
    //        if(mABEPre != null)
    //        {
    //            retVal = mABEPre.OverallIntensity;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if (mABEPre != null)
    //        {
    //            mABEPre.OverallIntensity = value;
    //        }
    //    }
    //}
    ///// <summary>
    ///// 
    ///// </summary>
    //public float BloomThreshold
    //{
    //    get
    //    {
    //        float retVal = 0f;
    //        if(mABEPre != null)
    //        {
    //            retVal = mABEPre.OverallThreshold;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if (mABEPre != null)
    //        {
    //            mABEPre.OverallThreshold = value;
    //        }
    //    }
    //}
    ///// <summary>
    ///// 
    ///// </summary>
    //public bool ApplyLensGlare
    //{
    //    get
    //    {
    //        bool retVal = false;
    //        if(mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            retVal = mABEPre.LensGlareInstance.ApplyLensGlare;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if(mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            mABEPre.LensGlareInstance.ApplyLensGlare = value;
    //        }
    //    }
    //}
    ///// <summary>
    ///// 
    ///// </summary>
    //public float LensGlareIntensity
    //{
    //    get
    //    {
    //        float retVal = 0f;
    //        if(mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            retVal = mABEPre.LensGlareInstance.Intensity;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if (mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            mABEPre.LensGlareInstance.Intensity = value;
    //        }
    //    }
    //}
    ///// <summary>
    ///// 
    ///// </summary>
    //public float LensGlareStreakScale
    //{
    //    get
    //    {
    //        float retVal = 0f;
    //        if(mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            retVal = mABEPre.LensGlareInstance.OverallStreakScale;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if (mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            mABEPre.LensGlareInstance.OverallStreakScale = value;
    //        }
    //    }
    //}
    ///// <summary>
    ///// 
    ///// </summary>
    //public Color LensGlareOverallTint
    //{
    //    get
    //    {
    //        Color retVal = Color.white;
    //        if(mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            retVal = mABEPre.LensGlareInstance.OverallTint;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if (mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            mABEPre.LensGlareInstance.OverallTint = value;
    //        }
    //    }
    //}
    ///// <summary>
    ///// 
    ///// </summary>
    //public float LensGlarePerPassDisplace
    //{
    //    get
    //    {
    //        float retVal = 0f;
    //        if(mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            retVal = mABEPre.LensGlareInstance.PerPassDisplacement;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if (mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            mABEPre.LensGlareInstance.PerPassDisplacement = value;
    //        }
    //    }
    //}
    ///// <summary>
    ///// 
    ///// </summary>
    //public int LensGlareMaxPerRayPass
    //{
    //    get
    //    {
    //        int retVal = 0;
    //        if (mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            retVal = mABEPre.LensGlareInstance.GlareMaxPassCount;
    //        }
    //        return retVal;
    //    }
    //    set
    //    {
    //        if (mABEPre != null && mABEPre.LensGlareInstance != null)
    //        {
    //            mABEPre.LensGlareInstance.GlareMaxPassCount = value;
    //        }
    //    }
    //}
    #endregion

    private bool mFirstClick = false;
    //private float mPressTimer = 0f;
    private float mTipShowTimer = 0f;
    // -1: 隐藏所有角色节点
    //  0: 显示女性角色节点
    //  1: 显示男性角色节点
    private int mEventIndex = -1;

    /// <summary>
    /// 显示UI特效索引
    /// 0：关闭特效窗口
    /// 1：显示特效1
    /// </summary>
    private int mUIEffIndex = 0;


    public SleekRenderPostProcess SRPostProcess
    {
        get
        {
            if (mSRPostProcess == null)
                return null;

            return mSRPostProcess;
        }
    }
    public DirectorGUI DGUI
    {
        get { return mDGUI; }
    }

    public float SceneFogStart
    {
        set
        {
            CutscenePlayMgr.instance.SaveSceneFogParm();
            RenderSettings.fogStartDistance = value;
        }
        get
        {
            return RenderSettings.fogStartDistance;
        }
    }
    public float SceneFogEnd
    {
        set
        {
            CutscenePlayMgr.instance.SaveSceneFogParm();
            RenderSettings.fogEndDistance = value;
        }
        get
        {
            return RenderSettings.fogEndDistance;
        }
    }


    public int EnableBloom
    {
        get
        {
            if (mSRPostProcess == null || mSRPostProcess.settings == null)
            {
                return 0;
            }

            if (mSRPostProcess.settings.bloomEnabled == false)
                return 0;

            return 1;
        }
        set
        {
            SetBloomEnable(value > 0 ? true : false);
        }
    }
    public int EnableVignette
    {
        get
        {
            if (mSRPostProcess == null || mSRPostProcess.settings == null)
            {
                return 0;
            }

            if (mSRPostProcess.settings.vignetteEnabled == false)
                return 0;

            return 1;
        }
        set
        {
            CutscenePlayMgr.instance.SaveVignetteParm(
                mSRPostProcess.settings.vignetteEnabled, mSRPostProcess.settings.vignetteBeginRadius, mSRPostProcess.settings.vignetteExpandRadius);

            SetVignetteEnable(value > 0 ? true : false);
        }
    }
    public float VignetteBeginRadius
    {
        get
        {
            if (mSRPostProcess == null || mSRPostProcess.settings == null)
            {
                return 0;
            }
            return mSRPostProcess.settings.vignetteBeginRadius;
        }
        set
        {
            if (mSRPostProcess == null || mSRPostProcess.settings == null)
            {
                iTrace.eError("LY", "SleekRenderPostProcess is miss !!! ");
                return;
            }
            CutscenePlayMgr.instance.SaveVignetteParm(
                mSRPostProcess.settings.vignetteEnabled, mSRPostProcess.settings.vignetteBeginRadius, mSRPostProcess.settings.vignetteExpandRadius);

            mSRPostProcess.settings.vignetteBeginRadius = value;
        }
    }
    public float VignetteExpandRadius
    {
        get
        {
            if (mSRPostProcess == null || mSRPostProcess.settings == null)
            {
                return 0;
            }
            return mSRPostProcess.settings.vignetteExpandRadius;
        }
        set
        {
            if (mSRPostProcess == null || mSRPostProcess.settings == null)
            {
                iTrace.eError("LY", "SleekRenderPostProcess is miss !!! ");
                return;
            }
            CutscenePlayMgr.instance.SaveVignetteParm(
                mSRPostProcess.settings.vignetteEnabled, mSRPostProcess.settings.vignetteBeginRadius, mSRPostProcess.settings.vignetteExpandRadius);

            mSRPostProcess.settings.vignetteExpandRadius = value;
        }
    }
    public int TriggerEvnt
    {
        get { return curEvnt; }
        set
        {
            bool isNew = false;
            if (curEvnt != value)
            {
                isNew = true;
            }
            curEvnt = value;

            if(isNew == false)
            {
                return;
            }

            IdRes tIR = IdResManager.instance.Find((uint)curEvnt);
            if(tIR == null)
            {
                return;
            }

            string resName = tIR.resName;
            if (tIR.entStr == "PlaySound")
            {
                /// 性别判断 ///
                if(tIR.type == 1)
                {
                    int curSex = User.instance.MapData.Sex;
                    if (tIR.respfList.list != null && tIR.respfList.list.Count > 0 && curSex < tIR.respfList.list.Count)
                    {
                        resName = resName + tIR.respfList.list[curSex];
                    }
                }

                Audio.Instance.Play(resName);
            }

            if (isNew == true && tIR.triggerEnt > 0)
            {
                EventMgr.Trigger("TriggerIdRes", tIR.entStr, curEvnt);
            }
        }
    }

    public int PlayCameraShake
    {
        get { return camShake ? 1 : 0; }
        set
        {
            if(value >= 1)
            {
                if (camShake == false)
                {
                    StartCSCamShake();
                }
            }
            else
            {
                if (camShake == true)
                {
                    StopCSCamShake();
                }
            }
        }
    }

    public int TriggerEventIndex
    {
        set
        {
            mEventIndex = value;
            string eventName = "";
            switch(mEventIndex)
            {
                case -1:
                    {
                        eventName = "HideAllCharNode";
                    }
                    break;
                case 0:
                    {
                        eventName = "ShowFemaleNode";
                    }
                    break;
                case 1:
                    {
                        eventName = "ShowMaleNode";
                    }
                    break;
                default:
                    break;
            }

            EventMgr.Trigger(eventName);
        }
        get
        {
            return mEventIndex;
        }
    }

    public int ShowUIEff
    {
        get { return mUIEffIndex; }
        set
        {
            switch (value)
            {
                case 0:
                    {
                        //UIMgr.Close("AnimeFxWnd");
                        EventMgr.Trigger("StopAnimeEff", 0);
                    }
                    return;
                case 1:
                    {
                        EventMgr.Trigger("PlayAnimeEff", 1);
                    }
                    break;
                default:
                    {
                        //UIMgr.Close("AnimeFxWnd");
                        EventMgr.Trigger("StopAnimeEff", 0);
                    }
                    break;
            }
        }
    }

    public void InitSetResComp()
    {
        CutscenePlayMgr.instance.RenderCamera = mCSPCamera;
        MapHelper.instance.MFShadow = mMFShadow;
        PJShadowMgr.Instance.FSShadow = mMFShadow;
    }

    public void SetBloomEnable(bool enable)
    {
        if (mSRPostProcess == null || mSRPostProcess.settings == null)
        {
            iTrace.eError("LY", "SleekRenderPostProcess is miss !!! ");
            return;
        }

        mSRPostProcess.settings.bloomEnabled = enable;
    }

    public void SetVignetteEnable(bool enable)
    {
        if (mSRPostProcess == null || mSRPostProcess.settings == null)
        {
            iTrace.eError("LY", "SleekRenderPostProcess is miss !!! ");
            return;
        }

        mSRPostProcess.settings.vignetteEnabled = enable;
    }

    private void Awake()
    {
#if UNITY_EDITOR
        if (!Application.isPlaying) return;
#endif
        //#if CS_HOTFIX_ENABLE
        //#else
        //        if (mCSPCamera == null)
        //        {
        //            //iTrace.Error("LY", " CSPCamera render camera miss !!! ");
        //            return;
        //        }
        //        InitSetResComp();

        //        if (mFxCamera == null)
        //        {
        //            //iTrace.Error("Ly", "Fx camera miss !!! ");
        //            return;
        //        }
        //#endif

        sW = Screen.width;
        sH = Screen.height;
        texX = sW / 2 - 256;
        texY = sH - 150;
        //textSizeS = tipSize / 750;
        //tipSize = sH * textSizeS;

        //tipStyle = new GUIStyle();
        //tipStyle.normal.textColor = Color.white;
        //tipStyle.richText = true;
        //LoadFont();
    }

    private void Start()
    {
        AssetMgr.Instance.Load("black_mask.png", FinLoadBgTex);
        AssetMgr.Instance.Load("psm_tips.png", FinLoadTextTex);
    }

    private void Update()
    {
        //if(Input.GetMouseButtonUp(0))
        //{
        //    //UIMgr.Close("UICGTipWnd");
        //    mPress = false;
        //    mPressTimer = 0f;
        //}

        //if(Input.GetKeyDown(KeyCode.Alpha5))
        //{
        //    CutscenePlayMgr.instance.PlayCutscene("Camera_Bamboo05");
        //}

        if (Input.GetKeyDown(KeyCode.Alpha6))
        {
            QualityMgr.instance.ChangeAndResetQuality(QualityMgr.TotalQualityType.TQT_1);
        }
        if (Input.GetKeyDown(KeyCode.Alpha7))
        {
            QualityMgr.instance.ChangeAndResetQuality(QualityMgr.TotalQualityType.TQT_2);
        }
        if (Input.GetKeyDown(KeyCode.Alpha8))
        {
            QualityMgr.instance.ChangeAndResetQuality(QualityMgr.TotalQualityType.TQT_3);
        }
        //if (Input.GetKeyDown(KeyCode.Alpha9))
        //{
        //    QualityMgr.instance.ChangeAndResetQuality(QualityMgr.TotalQualityType.TQT_4);
        //}
        //if (Input.GetKeyDown(KeyCode.Alpha0))
        //{
        //    //ShaderTool.ResetScene(SceneManager.GetActiveScene());
        //    //QualityMgr.instance.ChangeUnitMatQuality();

        //    EventMgr.Trigger("OpenScreenShotMask", true);
        //}
        if (Input.GetKeyDown(KeyCode.Minus))
        {
            QualityMgr.instance.EnterPowerSaveMode();
        }
        if (Input.GetKeyDown(KeyCode.Equals))
        {
            QualityMgr.instance.ExitPowerSaveMode();
        }

        if (Input.GetKeyDown(KeyCode.PageUp))
        {
            CameraMgr.FollowChildNode("Bip001 Main");
        }
        if (Input.GetKeyDown(KeyCode.PageDown))
        {
            CameraMgr.ResetOriFollow();
        }


        /// 监测动画跳过功能 ///
        if (CutscenePlayMgr.instance.IsPlaying == true)
        {
            if (CutscenePlayMgr.instance.CanSkip == false)
            {
                return;
            }

            if (mFirstClick == true)
            {
                if (Input.GetMouseButtonDown(0))
                {
                    CutscenePlayMgr.instance.SkipCutscene();

                    //UIMgr.Close("UICGTipWnd");
                    DirectorGUI.StopTips();
                    mFirstClick = false;
                    mTipShowTimer = 0f;
                    return;
                }

                if (mTipShowTimer > 0f)
                {
                    mTipShowTimer -= Time.deltaTime;
                    if (mTipShowTimer <= 0f)
                    {
                        //UIMgr.Close("UICGTipWnd");
                        DirectorGUI.StopTips();
                        mFirstClick = false;
                        mTipShowTimer = 0f;
                    }
                }
            }

            if (Input.GetMouseButtonDown(0))
            {
                //UIMgr.Open("UICGTipWnd", (uiName) =>
                //{
                //    if (CutscenePlayMgr.instance.IsPlaying == false)
                //    {
                //        UIMgr.Close("UICGTipWnd");
                //    }
                //});
                DirectorGUI.ShowTips();
                mFirstClick = true;
                //mPressTimer = 2f;
                mTipShowTimer = 4f;
            }
        }
    }

    /// <summary>
    /// 
    /// </summary>
    private void StartCSCamShake()
    {
        if (mCSPCamera == null)
            return;

        CameraMgr.CameraShake.AddCameraShakeEffWithObj(shakeTime, shakeFrequence, shakeAmplitude, mCSPCamera.gameObject);
        camShake = true;
    }

    /// <summary>
    /// 
    /// </summary>
    private void StopCSCamShake()
    {
        if (mCSPCamera == null)
            return;

        CameraMgr.CameraShake.RemoveCameraShakeByObj(mCSPCamera.gameObject);
        mCSPCamera.transform.localPosition = Vector3.zero;
        camShake = false;
    }

    /// <summary>
    /// 加载字库
    /// </summary>
//    private void LoadFont()
//    {
//        mDGUI = GetComponent<DirectorGUI>();
//        if(mDGUI == null)
//        {
//#if UNITY_EDITOR
//            iTrace.Log("LY", "Can not get DirectorGUI !!! ");
//#endif
//            return;
//        }

//        AssetMgr.Instance.Load("Font_W7.TTF", FinLoadFont);
//    }

//    private void FinLoadFont(UnityEngine.Object obj)
//    {
//        if (obj == null || obj is Font == false)
//        {
//#if UNITY_EDITOR
//            iTrace.Error("LY", "Can not find Font_W7.TTF !!! ");
//#endif
//            return;
//        }

//        Font subFont = obj as Font;
//        mDGUI.subtitlesFont = subFont;
//        mDGUI.overlayTextFont = subFont;
//        tipStyle.font = subFont;
//    }


    //// LY add begin ////
    //// 闪烁提示文字 ////

    private bool showPSMText = false;
    //private float mTipsTimer = 0f;
    //private float reverse = 1f;

    private int sW = 0;
    private int sH = 0;
    private int texX = 0;
    private int texY = 0;
    private Color mDCol = Color.white;
    //private float textSizeS = 1;
    //private GUIStyle tipStyle { get; set; }

    //private string tipText = "进入省电模式，操作游戏自动恢复";
    //private Color tipColor = Color.white;
    //private float tipSize = 28;
    //private TextAnchor tipAnchor = TextAnchor.MiddleCenter;
    //private Vector2 tipPos = new Vector2(0f, 100f);

    private Texture mPSMTex = null;
    private Texture mBgTex = null;

    public bool ShowPSMText
    {
        set { showPSMText = value; }
    }

    /// <summary>
    /// 低电量模式UI提示
    /// </summary>
    /// <param name="dTime"></param>
    private void OnPSMTextUpdate()
    {
        if (showPSMText == false)
        {
            return;
        }

        if (mBgTex != null)
        {
            mDCol.a = 0.3f;
            GUI.color = mDCol;
            GUI.DrawTexture(new Rect(-2, -2, sW + 2, sH + 2), mBgTex, ScaleMode.StretchToFill);
        }

        if (mPSMTex != null)
        {
            mDCol.a = 1f;
            GUI.color = mDCol;
            GUI.DrawTexture(new Rect(texX, texY, 512, 42), mPSMTex);
        }   

        //if (tipStyle.font == null)
        //{
        //    return;
        //}

        //mTipsTimer += reverse * Time.deltaTime;
        //if (mTipsTimer >= 1)
        //{
        //    mTipsTimer = 1f;
        //    reverse *= -1;
        //}
        //else if (mTipsTimer <= 0)
        //{
        //    mTipsTimer = 0f;
        //    reverse *= -1;
        //}
        //float alpha = mTipsTimer;

        //tipStyle.alignment = tipAnchor;
        //var rect = Rect.MinMaxRect(20, 10, Screen.width - 20, Screen.height - 10);
        //tipPos.y *= -1;
        //rect.center += tipPos;
        //var finalText = string.Format("<size={0}>{1}</size>", tipSize, tipText);
        ////shadow
        ////GUI.color = new Color(0, 0, 0, alpha);
        //GUI.color = new Color(0, 0, 0, 1);
        //GUI.Label(rect, finalText, tipStyle);
        //rect.center += new Vector2(2, -2);
        ////text
        ////tipColor.a = alpha;
        //GUI.color = tipColor;
        //GUI.Label(rect, finalText, tipStyle);
        GUI.color = Color.white;
    }



    private void FinLoadBgTex(UnityEngine.Object obj)
    {
        if (obj == null || obj is Texture == false)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "Can not load PSMBg texture !!! ");
#endif
            return;
        }

        mBgTex = obj as Texture;
        AssetMgr.Instance.SetPersist("black_mask.png");
        DontDestroyOnLoad(mBgTex);
    }

    private void FinLoadTextTex(UnityEngine.Object obj)
    {
        if (obj == null || obj is Texture == false)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "Can not load PSMBg texture !!! ");
#endif
            return;
        }

        mPSMTex = obj as Texture;
        AssetMgr.Instance.SetPersist("psm_tips.png");
        DontDestroyOnLoad(mPSMTex);
    }

    void OnGUI()
    {
        OnPSMTextUpdate();
    }
}