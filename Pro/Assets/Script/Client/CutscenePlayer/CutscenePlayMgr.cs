using UnityEngine;
using System;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using SleekRender;

using Loong.Game;
using Slate;


/// <summary>
/// 动画片段播放管理
/// </summary>
public class CutscenePlayMgr 
{
    public enum ReplaceType
    {
        RT_Unknown = 0,
        RT_AnimTrack,               /* 动作片段 */
        RT_AudioTrack,              /* 音频片段 */
        RT_Max
    }

    /// <summary>
    /// 判别类型
    /// </summary>
    public enum ConType
    {
        CT_Unknown = 0,
        CT_Sex,                     /* 性别 */
        CT_Max
    }

    /// <summary>
    /// 性别类型
    /// </summary>
    public enum SexType
    {
        ST_Unknown = -1,
        ST_Female,                  /* 女 */
        ST_Male,                    /* 男 */
        ST_Max
    }

    public static readonly CutscenePlayMgr instance = new CutscenePlayMgr();

    /// <summary>
    /// 完成播放动画名称
    /// </summary>
    private List<string> mFinPlayCutsNames = new List<string>();


    /// <summary>
    /// 是否正在播放
    /// </summary>
    private bool mPlaying = false;
    /// <summary>
    /// 是否可以跳过动画
    /// </summary>
    private bool mCanSkip = true;
    /// <summary>
    /// 开始播放时间分发
    /// </summary>
    private Action mStartPlayNotice = null;
    /// <summary>
    /// 动画渲染摄像机（默认摄像机）
    /// </summary>
    private Camera mCutsceneCam = null;
    /// <summary>
    /// 运行摄像机
    /// </summary>
    private Camera mRunCam = null;
    /// <summary>
    /// 动画结束时是否关闭摄像机
    /// </summary>
    private bool mCloseCamFin = true;
    /// <summary>
    /// 恢复摄像机参数
    /// </summary>
    private bool mReCamParamFin = true;
    /// <summary>
    /// 当动画完成打开UILoadMask
    /// </summary>
    private bool mOpenUIMaskEnd = false;
    /// <summary>
    /// 当动画完成打开UILoading
    /// </summary>
    private bool mOpenUILoadingEnd = false;

    private float oriTimeScale = 1.0f;

    /// <summary>
    /// 备份摄像机物体
    /// </summary>
    private GameObject _CopyCamObj = null;
    /// <summary>
    /// 需要保存参数摄像机
    /// </summary>
    private GameObject mOriCamObj = null;

    private SleekRenderPostProcess srPostProcess;
    private bool csSetVignette = false;
    private bool oriVignetteEnable = false;
    private float oriVignetteBeginRadius = 0f;
    private float oriVignetteExpandRadius = 0f;

    private bool csSetFog = false;
    private float oriFogStart = 0f;
    private float oriFogEnd = 0f;


    /// <summary>
    /// 动画片段播放器缓存池
    /// </summary>
    private List<CutscenePlayer> mCutsCacheList = new List<CutscenePlayer>();
    /// <summary>
    /// 播放中的动画片段
    /// </summary>
    private List<CutscenePlayer> mWorkingCutsList = new List<CutscenePlayer>();


    public bool OpenUIMask
    {
        get { return mOpenUIMaskEnd; }
        set
        {
            mOpenUIMaskEnd = value;
            DirectorCamera.openUIMaskEnd = mOpenUIMaskEnd;
        }
    }
    public bool OpenUILoading
    {
        get { return mOpenUILoadingEnd; }
        set { mOpenUILoadingEnd = value; }
    }
    public bool IsPlaying
    {
        get { return mPlaying; }
    }
    public bool CanSkip
    {
        get { return mCanSkip; }
    }
    public bool CloseCamFin
    {
        get { return mCloseCamFin; }
    }
    public Camera RenderCamera
    {
        get { return mCutsceneCam; }
        set
        {
            if (mCutsceneCam != null)
                return;

            mCutsceneCam = value;
        }
    }
    public GameObject CopyCamObj
    {
        get
        {
            if(_CopyCamObj == null)
            {
                _CopyCamObj = new GameObject("CopyCamObj");
                _CopyCamObj.SetActive(false);
                _CopyCamObj.AddComponent<Camera>().enabled = false;
                _CopyCamObj.AddComponent<AmplifyColorEffect>().enabled = false;
                _CopyCamObj.AddComponent<SleekRenderPostProcess>().enabled = false;

                GameObject.DontDestroyOnLoad(_CopyCamObj);
            }

            return _CopyCamObj;
        }
    }
    public SleekRenderPostProcess SRPostProcess
    {
        get
        {
            return srPostProcess;
        }
        set
        {
            srPostProcess = value;
        }
    }


    private void Init()
    {
        EventMgr.Add("CheckAndOpenUIMask", CheckAndOpenUIMask);
        EventMgr.Add("CheckAndOpenUILoading", CheckAndOpenUILoading);
        EventMgr.Add("EventSkipCutScene", EventSkipCutScene);
    }

    /// <summary>
    /// 获取一个动画片段播放器
    /// </summary>
    /// <returns></returns>
    private CutscenePlayer GetCutsPlayer()
    {
        if(mCutsCacheList == null)
        {
            mCutsCacheList = new List<CutscenePlayer>();
        }

        CutscenePlayer retPlayer = null;
        if(mCutsCacheList.Count <= 0)
        {
            retPlayer = new CutscenePlayer();
        }
        else
        {
            retPlayer = mCutsCacheList[0];
            mCutsCacheList.RemoveAt(0);
            retPlayer.Reset();
        }

        return retPlayer;
    }

    /// <summary>
    /// 回收动画片段播放器
    /// </summary>
    /// <param name="cutsPlayer"></param>
    private void RecycleCutsPlayer(CutscenePlayer cutsPlayer)
    {
        if (cutsPlayer == null)
            return;

        mCutsCacheList.Add(cutsPlayer);
    }


    public CutscenePlayMgr()
    {
        //iTrace.Log("LY", "Create CutscenePlayMgr !!! ");
        Init();
    }

    private void Reflection<T>(ref T current, T target)
    {
        Type t = current.GetType();
        string name = string.Empty;
        foreach (FieldInfo fi in t.GetFields())
        {
            name = fi.Name;
            object obj = fi.GetValue(target);
            fi.SetValue(current, obj);
        }
    }

    /// <summary>
    /// 复制参数到摄像机
    /// </summary>
    private void CopyValueToCamera()
    {
        if (mRunCam == null)
        {
            mRunCam = DirectorCamera.current.cam;
            if(mRunCam == null)
            {
                iTrace.Error("LY", "mCutsceneCam is null !!! ");
                return;
            }
        }

        if(CheckMainCam(mRunCam) == true)
        {
            return;
        }

        AmplifyColorEffect amplifyColorEffect = mRunCam.GetComponent<AmplifyColorEffect>();
        if (amplifyColorEffect != null)
        {
            if(CameraMgr.camPostprocessing != null && CameraMgr.camPostprocessing.CTCObj != null)
            {
                AmplifyColorEffect sourseACE = CameraMgr.camPostprocessing.CTCObj.GetComponent<AmplifyColorEffect>();
                if (sourseACE != null)
                {
                    Reflection<AmplifyColorEffect>(ref amplifyColorEffect, sourseACE);
                }
            }
        }

        SleekRenderPostProcess tSRPP = mRunCam.GetComponent<SleekRenderPostProcess>();
        if (tSRPP != null && CameraMgr.camPostprocessing != null && CameraMgr.camPostprocessing.CTCObj != null)
        {
            SleekRenderPostProcess tCSRPP = CameraMgr.camPostprocessing.CTCObj.GetComponent<SleekRenderPostProcess>();
            if (tCSRPP != null)
            {
                tSRPP.settings = tCSRPP.settings;
            }
        }
    }

    /// <summary>
    /// 是否运行主摄像机
    /// </summary>
    /// <returns></returns>
    public bool CheckMainCam(Camera checkCam)
    {
        if(checkCam == null)
        {
            return false;
        }

        if(checkCam == CameraMgr.Main)
        {
            return true;
        }

        return false;
    }

    /// <summary>
    /// 复制摄像机原始参数
    /// </summary>
    /// <param name="camObj"></param>
    public void CopyCamOriParam(GameObject oriCamObj)
    {
        if (oriCamObj == null)
        {
            iTrace.Error("LY", "Copy original camera miss !!! ");
            return;
        }

        Camera oriCam = oriCamObj.GetAddComponent<Camera>();
        if (oriCam == null)
            return;
        Camera cpCam = CopyCamObj.GetAddComponent<Camera>();
        //Reflection<Camera>(ref cpCam, oriCam);
        cpCam.clearFlags = oriCam.clearFlags;
        cpCam.backgroundColor = oriCam.backgroundColor;
        cpCam.cullingMask = oriCam.cullingMask;
        cpCam.fieldOfView = oriCam.fieldOfView;
        cpCam.nearClipPlane = oriCam.nearClipPlane;
        cpCam.farClipPlane = oriCam.farClipPlane;
        cpCam.depth = oriCam.depth;
        cpCam.useOcclusionCulling = oriCam.useOcclusionCulling;
        cpCam.allowHDR = oriCam.allowHDR;
        cpCam.allowMSAA = oriCam.allowMSAA;

        AmplifyColorEffect oriACE = oriCamObj.GetAddComponent<AmplifyColorEffect>();
        if (oriACE == null)
            return;
        AmplifyColorEffect cpACE = CopyCamObj.GetAddComponent<AmplifyColorEffect>();
        Reflection<AmplifyColorEffect>(ref cpACE, oriACE);
    }

    /// <summary>
    /// 恢复摄像机参数
    /// </summary>
    /// <param name="rCamObj"></param>
    public void RecoverCamParam(GameObject rCamObj)
    {
        if (_CopyCamObj == null)
            return;

        if (rCamObj == null)
        {
            return;
        }

        Camera rCam = rCamObj.GetAddComponent<Camera>();
        if (rCam == null)
            return;
        Camera cpCam = CopyCamObj.GetAddComponent<Camera>();
        //Reflection<Camera>(ref rCam, cpCam);
        rCam.clearFlags = cpCam.clearFlags;
        rCam.backgroundColor = cpCam.backgroundColor;
        rCam.cullingMask = cpCam.cullingMask;
        rCam.fieldOfView = cpCam.fieldOfView;
        rCam.nearClipPlane = cpCam.nearClipPlane;
        rCam.farClipPlane = cpCam.farClipPlane;
        rCam.depth = cpCam.depth;
        rCam.useOcclusionCulling = cpCam.useOcclusionCulling;
        rCam.allowHDR = cpCam.allowHDR;
        rCam.allowMSAA = cpCam.allowMSAA;

        AmplifyColorEffect rACE = rCamObj.GetAddComponent<AmplifyColorEffect>();
        if (rACE == null)
            return;
        AmplifyColorEffect cyACE = CopyCamObj.GetAddComponent<AmplifyColorEffect>();
        Reflection<AmplifyColorEffect>(ref rACE, cyACE);
    }

    /// <summary>
    /// 播放指定动画片段
    /// </summary>
    /// <param name="cutId"></param>
    /// <param name="finishCB"></param>
    public void PlayCutscene(string cutName, Camera myCam, bool closeCamFin = true, bool reParam = true, bool canSkip = true, Action<CutscenePlayer.StopType> finishCB = null, bool openLoadingEnd = false)
    {
        if (Global.Mode == PlayMode.Local)
        {
            finishCB(CutscenePlayer.StopType.ST_Finish);
            return;
        }

        if(HasCutsPlayed(cutName) == true)
        {
            if(finishCB != null)
            {
                finishCB(CutscenePlayer.StopType.ST_Finish);
            }
            return;
        }

        /// 测试 ///
        //myCam = CameraMgr.Main;
        
        string camPath = null;
        bool renCam = false;
        if (myCam != null && myCam != mCutsceneCam)
        {
            mRunCam = myCam;
            renCam = false;
            mOriCamObj = myCam.gameObject;
            CopyCamOriParam(mOriCamObj);
            DirectorCamera.mChangeCamParent = true;
            camPath = myCam.name;
            mCloseCamFin = closeCamFin;
            mReCamParamFin = reParam;
        }
        else
        {
            mRunCam = mCutsceneCam;
            renCam = true;
            mOriCamObj = null;
            DirectorCamera.mChangeCamParent = false;
            camPath = null;
            mCloseCamFin = true;
            mReCamParamFin = true;
        }
        DirectorCamera.closeCamFin = mCloseCamFin;

        mCanSkip = canSkip;

        InputMgr.instance.JoyStickControlMdl = false;
        for(int a = 0; a < mWorkingCutsList.Count; a++)
        {
            if(cutName == mWorkingCutsList[a].CurPlayCutsName)
            {
                iTrace.Warning("LY", "Cutscene is playing !!! " + cutName);
                return;
            }
        }

        DirectorCamera.renderCamera = mRunCam;
        DirectorCamera.isDefaultRenCam = renCam;
        DirectorCamera.isMainCam = CheckMainCam(mRunCam);
        mOpenUILoadingEnd = openLoadingEnd;

        CopyValueToCamera();

        oriTimeScale = Time.timeScale;
        CutscenePlayer tPlayer = GetCutsPlayer();
        tPlayer.Play(cutName, finishCB, camPath);
        mWorkingCutsList.Add(tPlayer);
        
        mPlaying = true;
        EventMgr.Trigger(EventKey.StartPlayAnim);

        CameraMgr.SetSceneRtToCurCam(DirectorCamera.renderCamera, renCam);

        //if (mCanSkip == true)
        //{
        //    UIMgr.Open("UICGTipWnd", (uiName) =>
        //            {
        //                if (CutscenePlayMgr.instance.IsPlaying == false)
        //                {
        //                    UIMgr.Close("UICGTipWnd");
        //                }
        //            });
        //}
    }

    /// <summary>
    /// 播放指定动画片段序列
    /// </summary>
    /// <param name="cutIds"></param>
    /// <param name="finishCB"></param>
    public void PlayCutscene(List<string> cutNames, Camera myCam, bool closeCamFin = true, bool reParam = true, bool canSkip = true, Action<CutscenePlayer.StopType> finishCB = null, bool openLoadingEnd = false)
    {
        if (Global.Mode == PlayMode.Local)
        {
            finishCB(CutscenePlayer.StopType.ST_Finish);
            return;
        }

        for(int a = 0; a < cutNames.Count; a++)
        {
            if (HasCutsPlayed(cutNames[a]) == true)
            {
                if (finishCB != null)
                {
                    finishCB(CutscenePlayer.StopType.ST_Finish);
                }
                return;
            }
        }

        string camPath = null;
        bool renCam = false;
        if (myCam != null && myCam != mCutsceneCam)
        {
            mRunCam = myCam;
            renCam = false;
            mOriCamObj = myCam.gameObject;
            CopyCamOriParam(mOriCamObj);
            DirectorCamera.mChangeCamParent = true;
            camPath = myCam.name;
            mCloseCamFin = closeCamFin;
            mReCamParamFin = reParam;
        }
        else
        {
            mRunCam = mCutsceneCam;
            renCam = true;
            mOriCamObj = null;
            DirectorCamera.mChangeCamParent = false;
            camPath = null;
            mCloseCamFin = true;
            mReCamParamFin = true;
        }
        DirectorCamera.closeCamFin = mCloseCamFin;

        mCanSkip = canSkip;

        DirectorCamera.renderCamera = mRunCam;
        DirectorCamera.isDefaultRenCam = renCam;
        DirectorCamera.isMainCam = CheckMainCam(mRunCam);
        mOpenUILoadingEnd = openLoadingEnd;

        CopyValueToCamera();

        oriTimeScale = Time.timeScale;
        CutscenePlayer tPlayer = GetCutsPlayer();
        tPlayer.Play(cutNames, finishCB, camPath);
        mWorkingCutsList.Add(tPlayer);

        mPlaying = true;
        EventMgr.Trigger(EventKey.StartPlayAnim);

        //if (mCanSkip == true)
        //{
        //    UIMgr.Open("UICGTipWnd", (uiName) =>
        //            {
        //                if (CutscenePlayMgr.instance.IsPlaying == false)
        //                {
        //                    UIMgr.Close("UICGTipWnd");
        //                }
        //            });
        //}
    }

    /// <summary>
    /// 跳过动画片段
    /// </summary>
    /// <param name="cutName"></param>
    public void SkipCutscene(string cutName = null)
    {
        if(mWorkingCutsList == null || mWorkingCutsList.Count <= 0)
        {
            return;
        }

        /// 全部跳过 ///
        if(string.IsNullOrEmpty(cutName) == true)
        {
            for (int a = 0; a < mWorkingCutsList.Count; a++)
            {
                mWorkingCutsList[a].Skip();
            }
        }
        /// 指定名称跳过 ///
        else
        {
            for (int a = 0; a < mWorkingCutsList.Count; a++)
            {
                if (cutName == mWorkingCutsList[a].CurPlayCutsName)
                {
                    mWorkingCutsList[a].Skip();
                    break;
                }
            }
        }

        DirectorCamera.Disable();
        if(mReCamParamFin == true && mOriCamObj != null)
        {
            RecoverCamParam(mOriCamObj);
        }
        mOriCamObj = null;
        mRunCam = null;
    }

    /// <summary>
    /// 移除动画片段播放器
    /// </summary>
    /// <param name="cutsPlayer"></param>
    public void RemoveCutscenePlayer(CutscenePlayer cutsPlayer)
    {
        if(mWorkingCutsList.Contains(cutsPlayer) == true)
        {
            mWorkingCutsList.Remove(cutsPlayer);
            RecycleCutsPlayer(cutsPlayer);
        }
        else
        {
            return;
        }

        /// 动画播放管理器恢复空闲 ///
        if(mWorkingCutsList.Count <= 0)
        {
            mPlaying = false;
            UIMgr.Close("AnimeFxWnd");
            Time.timeScale = oriTimeScale;
            if (mCutsceneCam != null)
            {
                CoolMotionBlur tBlur = mCutsceneCam.GetAddComponent<CoolMotionBlur>();
                if(tBlur != null)
                {
                    tBlur.enabled = false;
                }
            }

            //DirectorCamera.Disable();
            if (mReCamParamFin == true && mOriCamObj != null)
            {
                RecoverCamParam(mOriCamObj);
            }
            mOriCamObj = null;

            if (mRunCam != null && mRunCam != mCutsceneCam)
            {

            }
            else
            {
                CameraMgr.SetSceneRtToCurCam(CameraMgr.Main, false);
            }
            mRunCam = null;

            RecoverSceneFogParm();
            RecoverVignetteParm();
            if(RenderCamera != null)
            {
                RenderCamera.transform.localPosition = Vector3.zero;
            }
            //UIMgr.Close("UICGTipWnd");
            DirectorGUI.StopTips();
            EventMgr.Trigger(EventKey.AllAnimFinish);
        }
    }

    /// <summary>
    /// 注册开始播放动画时间
    /// </summary>
    /// <param name="evnt"></param>
    public void RegisterEventAtStart(Action evnt)
    {
        mStartPlayNotice += evnt;
    }

    public void UnregisterEventAtStart(Action evnt)
    {
        mStartPlayNotice -= evnt;
    }

    public void ExcuteEventAtStart()
    {
        iTrace.Log("LY", "Start Play Cut Scene !!! ");

        if (mStartPlayNotice != null)
        {
            mStartPlayNotice();
        }
    }

    public void CheckAndOpenUIMask(params object[] args)
    {
        if(mOpenUIMaskEnd && Application.isPlaying == true)
        {
            UIMgr.Open(UIName.UIMask, (uiName) =>
            {
                if(mOpenUIMaskEnd == false)
                {
                    UIMgr.Close(UIName.UIMask);
                }
                //mOpenUIMaskEnd = false;
            });
        }
    }

    /// <summary>
    /// 检查是否需要打开loading画面
    /// </summary>
    public void CheckAndOpenUILoading(params object[] args)
    {
        if(mOpenUILoadingEnd == true && Application.isPlaying == true)
        {
            UIMgr.Open(UIName.UILoading, (uiName) =>
            {
                if(mOpenUILoadingEnd == false)
                {
                    UIMgr.Close(UIName.UILoading);
                }
                mOpenUILoadingEnd = false;
            });
        }
    }

    public void EventSkipCutScene(params object[] args)
    {
        SkipCutscene();
    }


    public int GetGameConVal(int conType)
    {
        return GetGameConVal((ConType)conType);
    }

    public int GetGameConVal(ConType cType)
    {
        int retVal = -1;
        switch(cType)
        {
            case ConType.CT_Sex:
                {
                    retVal = User.instance.MapData.Sex;
                }
                break;
            default:
                iTrace.Error("LY", "ConType error : " + cType);
                break;
        }

        return retVal;
    }

    public List<GroupActorName> GetCutsChangeInfo(string cutsName)
    {
        List<GroupActorName> retList = new List<GroupActorName>();
        List<CutsRes> resList = CutsResManager.instance.GetList();
        for (int a = 0; a < resList.Count; a++)
        {
            CutsRes checkCutsRes = resList[a];
            if (checkCutsRes != null && checkCutsRes.cutsName == cutsName)
            {
                int tCon1Val = GetGameConVal(checkCutsRes.conType1);
                if(checkCutsRes.conVal1 == tCon1Val)
                {
                    List<CutsRes.groupRes> tGroupRes = checkCutsRes.resList.list;
                    List<CutsRes.clips> tClips = checkCutsRes.trackClips.list;
                    for (int b = 0; b < tGroupRes.Count; b++)
                    {
                        GroupActorName tGAN = new GroupActorName();
                        tGAN.mReplaceIndex = checkCutsRes.replType;
                        tGAN.mGroupName = tGroupRes[b].groupName;
                        tGAN.mActorName = tGroupRes[b].actorName;
                        tGAN.mClips = new List<string>();
                        for (int c = 0; c < tClips[b].list.Count; c++)
                        {
                            tGAN.mClips.Add(tClips[b].list[c]);
                        }
                        tGAN.postfix = checkCutsRes.postfix;

                        retList.Add(tGAN);
                    }
                }
            }
        }

        return retList;
        
        //List<CutsRes> resList = CutsResManager.instance.GetList();
        //CutsRes tComRes = null;
        //for(int a = 0; a < resList.Count; a++)
        //{
        //    if(resList[a].cutsName == cutsName)
        //    {
        //        tComRes = resList[a];
        //        break;
        //    }
        //}
        //if(tComRes == null)
        //{
        //    return null;
        //}
        
        //int tCon1Val = GetGameConVal(tComRes.conType1);
        //tComRes = null;
        //for (int a = 0; a < resList.Count; a++)
        //{
        //    if(resList[a].cutsName == cutsName && resList[a].conVal1 == tCon1Val)
        //    {
        //        tComRes = resList[a];
        //        break;
        //    }
        //}

        //if(tComRes == null)
        //{
        //    iTrace.Error("LY", "Can not find cutscene resource !!! ");
        //    return null;
        //}

        //List<GroupActorName> retList = new List<GroupActorName>();
        //List<CutsRes.groupRes> tGroupRes = tComRes.resList.list;
        //List<CutsRes.clips> tClips = tComRes.trackClips.list;
        //for (int a = 0; a < tGroupRes.Count; a++)
        //{
        //    GroupActorName tGAN = new GroupActorName();
        //    tGAN.mGroupName = tGroupRes[a].groupName;
        //    tGAN.mActorName = tGroupRes[a].actorName;

        //    tGAN.mClips = new List<string>();
        //    for(int b = 0; b < tClips[a].list.Count; b++)
        //    {
        //        tGAN.mClips.Add(tClips[a].list[b]);
        //    }

        //    retList.Add(tGAN);
        //}

        //return retList;
    }

    public void SaveVignetteParm(bool oriEnable, float oriBR, float oriER)
    {
        if(csSetVignette == false)
        {
            oriVignetteEnable = oriEnable;
            oriVignetteBeginRadius = oriBR;
            oriVignetteExpandRadius = oriER;
            csSetVignette = true;
        }
    }

    public void RecoverVignetteParm()
    {
        if(csSetVignette == true)
        {
            csSetVignette = false;
        }

        if(srPostProcess != null && srPostProcess.settings != null)
        {
            srPostProcess.settings.vignetteEnabled = oriVignetteEnable;
            srPostProcess.settings.vignetteBeginRadius = oriVignetteBeginRadius;
            srPostProcess.settings.vignetteExpandRadius = oriVignetteExpandRadius;
        }
    }

    public void SaveSceneFogParm()
    {
        if (csSetFog == false)
        {
            csSetFog = true;
            oriFogStart = RenderSettings.fogStartDistance;
            oriFogEnd = RenderSettings.fogEndDistance;
        }
    }

    public void RecoverSceneFogParm()
    {
        if(csSetFog == true)
        {
            RenderSettings.fogStartDistance = oriFogStart;
            RenderSettings.fogEndDistance = oriFogEnd;
            csSetFog = false;
        }
    }

    /// <summary>
    /// 检查动画是否已经播放过
    /// </summary>
    /// <param name="cutsName"></param>
    /// <returns></returns>
    public bool HasCutsPlayed(string cutsName)
    {
        if (cutsName == "Character_Create_male" || cutsName == "Character_Create_female" 
            || cutsName == "Camera_Hijacking01" || cutsName == "Camera_FB_Hijackingback_L")
            return false;

        if(mFinPlayCutsNames.Contains(cutsName) == true)
        {
            return true;
        }

        mFinPlayCutsNames.Add(cutsName);
        return false;
    }

    /// <summary>
    /// 清空已经播放动画记录
    /// </summary>
    public void ClearPlayedCutsNames()
    {
        mFinPlayCutsNames.Clear();
    }
}
