using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;
using Slate;


public class GroupActorName
{
    public ushort mReplaceIndex;
    public string mGroupName;
    public string mActorName;
    public List<string> mClips = null;
    public string postfix = "";
};


/// <summary>
/// 动画片段播放器
/// </summary>
public class CutscenePlayer
{
    /// <summary>
    /// 停止类型
    /// </summary>
    public enum StopType
    {
        ST_Unknown = 0,
        ST_Finish,                          /* 播放完成 */
        ST_Skip,                            /* 跳过 */
        ST_Error,                           /* 错误 */
        ST_Max
    }

    private enum LoadType
    {
        LT_Unknown = 0,
        LT_CutScene,                       /* 读取动画片段 */
        LT_Actor,                          /* 读取替换角色 */
        LT_Clip,                           /* 读取替换动画 */
        LT_Audio,                          /* 读取音频 */
        LT_Finish,                         /* 读取完成 */
        LT_Max
    }

    /// <summary>
    /// 动画片段Id列表
    /// </summary>
    private List<string> mCutsIdList = null;
    /// <summary>
    /// 动画片段列表
    /// </summary>
    private List<Cutscene> mCutsceneList = null;
    /// <summary>
    /// 摄像机路径
    /// </summary>
    private string mCamPath = null;

    /// <summary>
    /// 正在播放
    /// </summary>
    private bool mIsPlaying = false;
    /// <summary>
    /// 等待资源
    /// </summary>
    private bool mLoadingRes = false;
    /// <summary>
    /// 等待资源播放(当所有资源加载完成，标志为true)
    /// </summary>
    private bool mWaitingRes = false;


    /// <summary>
    /// 等待动画片段资源
    /// </summary>
    private bool mWaitingCsRes = false;
    /// <summary>
    /// 等待物体资源数量
    /// </summary>
    //private int mWaitAGOResNum = 0;
    /// <summary>
    /// 当前加载完成物体资源数量
    /// </summary>
    //private int mCurAGOResNum = 0;

    /// <summary>
    /// 当前读取替换角色索引
    /// </summary>
    private int mCurLoadAGoIndex = 0;

    /// <summary>
    /// 当前读取替代动画索引
    /// </summary>
    private int mCurLoadClipIndex = 0;


    /// <summary>
    /// 等待读取资源信息
    /// </summary>
    private List<GroupActorName> mActorResList = null;
    /// <summary>
    /// 存放资源字典
    /// </summary>
    private Dictionary<string, List<GroupActor>> m_mapActorRes = new Dictionary<string, List<GroupActor>>();

    /// <summary>
    /// 当前读取资源信息
    /// </summary>
    private GroupActorName mCurLoadInfo;
    /// <summary>
    /// 当前填充资源结构
    /// </summary>
    private GroupActor mCurFillRes;

    /// <summary>
    /// 当前读取资源状态
    /// </summary>
    private LoadType mLoadType = LoadType.LT_Unknown;
    /// <summary>
    /// 当前读取中动画序列
    /// </summary>
    private int mCurLoadCSIndex = -1;
    /// <summary>
    /// 当前播放动画序列
    /// </summary>
    private int mCurPlayIndex = -1;
    /// <summary>
    /// 播放完成回调
    /// </summary>
    private Action<StopType> mFinishCallBack;


    public bool IsWaitingCsRes
    {
        get
        {
            return mWaitingCsRes;
        }
    }
    /// <summary>
    /// 是否正在播放
    /// </summary>
    public bool IsPlaying
    {
        get { return mIsPlaying; }
    }
    /// <summary>
    /// 返回当前播放动画片段名称
    /// </summary>
    public string CurPlayCutsName
    {
        get
        {
            if(mCurPlayIndex <= 0 || mCutsIdList == null || mCurPlayIndex > mCutsIdList.Count)
            {
                return null;
            }

            return mCutsIdList[mCurPlayIndex - 1];
        }
    }
    public bool LoadingRes
    {
        get { return mLoadingRes; }
    }


    private void Init()
    {
        Reset();
    }

    private void Play()
    {
        if(mIsPlaying == true)
        {
            return;
        }

        mIsPlaying = true;
        mWaitingRes = true;
        mLoadingRes = false;
        
        mWaitingCsRes = false;

        //mWaitAGOResNum = 0;
        //mCurAGOResNum = 0;
        mCurLoadCSIndex = -1;
        mCurLoadAGoIndex = 0;
        mCurLoadClipIndex = 0;
        
        mCurPlayIndex = 0;

        m_mapActorRes.Clear();

        //CutscenePlayMgr.instance.FogHelper.SetFogEffectTypeAsMainCam();
        //LoadNextCutscene();

        mLoadType = LoadType.LT_CutScene;
        CheckLoadNextRes();
    }

    /// <summary>
    /// 检测读取下一个资源
    /// </summary>
    private void CheckLoadNextRes()
    {
        switch(mLoadType)
        {
            case LoadType.LT_CutScene:
                {
                    LoadNextCutscene();
                }
                break;
            case LoadType.LT_Actor:
                {
                    LoadNextActorRes();
                }
                break;
            case LoadType.LT_Clip:
                {
                    LoadNextClipRes();
                }
                break;
            case LoadType.LT_Audio:
                {
                    LoadNextAudioRes();
                }
                break;
            case LoadType.LT_Finish:
                {
                    CutsceneLoadFinish();
                }
                break;
            default:
                iTrace.eError("LY", "Load type error !!! ");
                break;
        }
    }

    /// <summary>
    /// 读取动画序列并播放
    /// </summary>
    private void LoadNextCutscene()
    {
        mCurLoadCSIndex++;
        /// Id 错误 ///
        if(mCurLoadCSIndex < 0)
        {
            iTrace.Error("LY", "Load index error !!! " + mCurLoadCSIndex);
            return;
        }

        /// 已经完成读取 ///
        if(mCurLoadCSIndex >= mCutsIdList.Count)
        {
            mLoadingRes = false;
            return;
        }

        mLoadingRes = true;
        //string cutsceneName = mCutsIdList[mCurLoadIndex].ToString() + "_cs";
        string cutsceneName = mCutsIdList[mCurLoadCSIndex];
        AssetMgr.LoadPrefab(cutsceneName, FinLoadCutscene);
    }

    /// <summary>
    /// 读取cutscene完成
    /// </summary>
    /// <param name="csObj"></param>
    private void FinLoadCutscene(GameObject csObj)
    {
        if (csObj == null)
        {
            iTrace.Error("LY", "Cutscene can not be found !!! " + mCutsIdList[mCurLoadCSIndex]);
            return;
        }
        QualityMgr.instance.ChangeGoQuality(csObj);

        Cutscene playCut = csObj.GetComponent<Cutscene>();
        if (playCut == null)
        {
            iTrace.Error("LY", "Asset miss Cutscene !!! ");
            return;
        }

        mCutsceneList.Add(playCut);
        //CheckLoadActorRes();
        
        CheckLoadActorRes();
        CheckLoadNextRes();
    }

    /// <summary>
    /// 读取动画片段完成
    /// </summary>
    private void CutsceneLoadFinish()
    {
        if (mWaitingRes == true)
        {
            mWaitingRes = false;
            MoveNext();
        }
        LoadNextCutscene();
    }

    /// <summary>
    /// 检测要读取的替代主体
    /// </summary>
    private void CheckLoadActorRes()
    {
        mCurLoadAGoIndex = 0;

        mWaitingCsRes = true;
        mActorResList = null;
        string cutsceneName = mCutsIdList[mCurLoadCSIndex];
        mActorResList = CutscenePlayMgr.instance.GetCutsChangeInfo(cutsceneName);
        //LoadNextActorRes();

        if(mActorResList == null || mActorResList.Count <= 0)
        {
            mLoadType = LoadType.LT_Finish;
        }
        else
        {
            mLoadType = LoadType.LT_Actor;
        }
    }

    /// <summary>
    /// 读取下一个主体替换物
    /// </summary>
    private void LoadNextActorRes()
    {
        if (mCurLoadAGoIndex >= mActorResList.Count)
        {
            LoadActorResFinish();
            return;
        }

        mCurLoadInfo = mActorResList[mCurLoadAGoIndex];
        /// 动作片段 ///
        if(mCurLoadInfo.mReplaceIndex == 1)
        {
            AssetMgr.LoadPrefab(mCurLoadInfo.mActorName, FinLoadActorRes);
        }
        /// 音频片段 ///
        else if(mCurLoadInfo.mReplaceIndex == 2)
        {
            mCurFillRes = new GroupActor();
            mCurFillRes.mReplaceType = mActorResList[mCurLoadAGoIndex].mReplaceIndex;
            mCurFillRes.mGroupName = mActorResList[mCurLoadAGoIndex].mGroupName;
            mCurFillRes.mTrackName = mActorResList[mCurLoadAGoIndex].mActorName;
            mCurFillRes.mNewActor = null;

            string cutsceneName = mCutsIdList[mCurLoadCSIndex];
            if (m_mapActorRes.ContainsKey(cutsceneName) == false)
            {
                m_mapActorRes.Add(cutsceneName, new List<GroupActor>());
            }
            m_mapActorRes[cutsceneName].Add(mCurFillRes);
            
            mCurLoadClipIndex = 0;
            mLoadType = LoadType.LT_Audio;
            CheckLoadNextRes();
        }
    }

    /// <summary>
    /// 完成读取替换角色资源
    /// </summary>
    /// <param name="actor"></param>
    private void FinLoadActorRes(GameObject actor)
    {
        if (actor == null)
        {
            iTrace.Error("LY", "Change actor can not be found !!! " + mCurLoadInfo.mActorName);
            return;
        }
        QualityMgr.instance.ChangeGoQuality(actor);

        actor.transform.SetParent(mCutsceneList[mCurLoadCSIndex].gameObject.transform, true);

        mCurFillRes = new GroupActor();
        mCurFillRes.mReplaceType = mActorResList[mCurLoadAGoIndex].mReplaceIndex;
        mCurFillRes.mGroupName = mActorResList[mCurLoadAGoIndex].mGroupName;
        mCurFillRes.mTrackName = "";
        mCurFillRes.mNewActor = actor;

        string cutsceneName = mCutsIdList[mCurLoadCSIndex];
        if (m_mapActorRes.ContainsKey(cutsceneName) == false)
        {
            m_mapActorRes.Add(cutsceneName, new List<GroupActor>());
        }
        m_mapActorRes[cutsceneName].Add(mCurFillRes);

        //mCurLoadAGoIndex++;
        mCurLoadClipIndex = 0;
        mLoadType = LoadType.LT_Clip;
        CheckLoadNextRes();

        //LoadNextActorRes();
    }

    /// <summary>
    /// 读取动画替换资源完成
    /// </summary>
    private void LoadActorResFinish()
    {
        mWaitingCsRes = false;
        //CutsceneLoadFinish();
        mLoadType = LoadType.LT_Finish;
        CheckLoadNextRes();
    }

    /// <summary>
    /// 读取下一条动画片段
    /// </summary>
    private void LoadNextClipRes()
    {
        if(mCurLoadClipIndex >= mCurLoadInfo.mClips.Count)
        {
            LoadClipResFinish();
            return;
        }

        AssetMgr.Instance.Load(mCurLoadInfo.mClips[mCurLoadClipIndex], ".anim", FinLoadClipRes);
    }

    /// <summary>
    /// 读取下一条音频片段
    /// </summary>
    private void LoadNextAudioRes()
    {
        if (mCurLoadClipIndex >= mCurLoadInfo.mClips.Count)
        {
            LoadClipResFinish();
            return;
        }

        string tPostfix = ".mp3";
        if(string.IsNullOrEmpty(mCurLoadInfo.postfix) == false)
        {
            tPostfix = mCurLoadInfo.postfix;
        }

        AssetMgr.Instance.Load(mCurLoadInfo.mClips[mCurLoadClipIndex], tPostfix, FinLoadAudioRes);
    }

    /// <summary>
    /// 完成读取动画片段
    /// </summary>
    /// <param name="obj"></param>
    private void FinLoadClipRes(System.Object obj)
    {
        AnimationClip lClip = obj as AnimationClip;
        if(lClip == null)
        {
            iTrace.Error("LY", "AnimationClip load error !!! " + mActorResList[mCurLoadAGoIndex].mClips[mCurLoadClipIndex]);
            return;
        }

        if(mCurFillRes.mACList == null)
        {
            mCurFillRes.mACList = new List<AnimationClip>();
        }
        mCurFillRes.mACList.Add(lClip);
        mCurLoadClipIndex++;
        CheckLoadNextRes();
    }

    /// <summary>
    /// 完成读取音频片段
    /// </summary>
    /// <param name="obj"></param>
    private void FinLoadAudioRes(System.Object obj)
    {
        AudioClip lClip = obj as AudioClip;
        if (lClip == null)
        {
            iTrace.Error("LY", "AudioClip load error !!! " + mActorResList[mCurLoadAGoIndex].mClips[mCurLoadClipIndex]);
            return;
        }

        if (mCurFillRes.mSCList == null)
        {
            mCurFillRes.mSCList = new List<AudioClip>();
        }
        mCurFillRes.mSCList.Add(lClip);
        mCurLoadClipIndex++;
        CheckLoadNextRes();
    }

    /// <summary>
    /// 完成读取当前替换actor动画片段
    /// </summary>
    private void LoadClipResFinish()
    {
        mCurLoadAGoIndex++;
        mLoadType = LoadType.LT_Actor;
        CheckLoadNextRes();
    }

    /// <summary>
    /// 播放下一条序列
    /// </summary>
    private void MoveNext()
    {
        if (mIsPlaying == false)
        {
            iTrace.Error("LY", "Ah!!!  Playing is false ?????????");
            return;
        }

        /// 已经播放完成 ///
        if(mCurPlayIndex >= mCutsIdList.Count)
        {
            Finish();
            return;
        }
        
        /// cutscene未读取完成 ///
        if (mCurPlayIndex >= mCutsceneList.Count)
        {
            mWaitingRes = true;
            return;
        }
        
        Cutscene tCut = mCutsceneList[mCurPlayIndex];
        if (tCut == null)
        {
            iTrace.Error("LY", "Cutscene is null in Cutscene Player !!! ");
            return;
        }

        /// 播放动画片段开始，分发事件 ///
        if(mCurPlayIndex == 0)
        {
            CutscenePlayMgr.instance.ExcuteEventAtStart();
        }

        List<GroupActor> tRA = null;
        if (m_mapActorRes.ContainsKey(mCutsIdList[mCurPlayIndex]))
        {
            tRA = m_mapActorRes[mCutsIdList[mCurPlayIndex]];
        }

        //Transform tTrans = tCut.transform.Find("Fog_Light");
        //if(tTrans != null)
        //{
        //    if (CutscenePlayMgr.instance.FogHelper != null)
        //    {
        //        CutscenePlayMgr.instance.FogHelper.SetFogLight(tTrans.gameObject);
        //    }
        //}
        
        tCut.Play(MoveNext, tRA, mCamPath);
        mCurPlayIndex++;
    }

    private void Finish()
    {
        mIsPlaying = false;
        if (mFinishCallBack != null)
        {
            mFinishCallBack.Invoke(StopType.ST_Finish);
            mFinishCallBack = null;
        }

        Dispose();
    }

    private void Dispose()
    {
        mLoadingRes = false;
        mWaitingRes = false;

        //mCutsIdList.Clear();
        mActorResList = null;


        Dictionary<string, List<GroupActor>>.Enumerator iter = m_mapActorRes.GetEnumerator();
        while (iter.MoveNext())
        {
            List<GroupActor> tGA = iter.Current.Value;
            for(int a = 0; a < tGA.Count; a++)
            {
                if(tGA[a].mNewActor != null)
                {
                    GameObject.DestroyImmediate(tGA[a].mNewActor);
                }
            }
        }
        m_mapActorRes.Clear();

        for (int a = mCutsceneList.Count - 1; a >= 0; a--)
        {
            MonoBehaviour.Destroy(mCutsceneList[a].gameObject);
        }
        mCutsceneList.Clear();

        if(mCutsIdList != null)
        {
            for (int a = 0; a < mCutsIdList.Count; a++)
            {
                AssetMgr.Instance.Unload(mCutsIdList[a]);
            }
            mCutsIdList.Clear();
        }

        CutscenePlayMgr.instance.RemoveCutscenePlayer(this);
    }


    public CutscenePlayer()
    {
        Init();
    }

    public void Reset()
    {
        if(mCutsIdList == null)
        {
            mCutsIdList = new List<string>();
        }
        else
        {
            mCutsIdList.Clear();
        }

        if(mCutsceneList == null)
        {
            mCutsceneList = new List<Cutscene>();
        }
        else
        {
            mCutsceneList.Clear();
        }

        mIsPlaying = false;
        mLoadingRes = false;
        mWaitingRes = false;
        mWaitingCsRes = false;

        mCurLoadCSIndex = -1;
        mCurLoadAGoIndex = -1;
        mCurPlayIndex = -1;

        mActorResList = null;
        m_mapActorRes.Clear();
    }

    /// <summary>
    /// 播放一条动画轨迹
    /// </summary>
    /// <param name="cutsId"></param>
    /// <param name="finCB"></param>
    public void Play(string cutsName, Action<StopType> finCB = null, string camPath = null)
    {
        if(mIsPlaying == true)
        {
            iTrace.Error("LY", "Cutscene player is playing !!! ");
        }

        mCamPath = camPath;
        mCutsIdList.Add(cutsName);
        mFinishCallBack = finCB;

        Play();
    }

    /// <summary>
    /// 播放一组动画轨迹
    /// </summary>
    /// <param name="playCuts"></param>
    public void Play(List<string> cutsNames, Action<StopType> finCB = null, string camPath = null)
    {
        if (mIsPlaying == true)
        {
            iTrace.Error("LY", "Cutscene player is playing !!! ");
        }

        mCamPath = camPath;
        mCutsIdList.AddRange(cutsNames);
        mFinishCallBack = finCB;

        Play();
    }

    /// <summary>
    /// 跳过动画片段
    /// </summary>
    public void Skip()
    {
        if(mIsPlaying == false)
        {
            return;
        }

        for(int a = 0; a < mCutsceneList.Count; a++)
        {
            if (mCutsceneList[a] != null)
            {
                mCutsceneList[a].SkipAll();
            }
        }

        mIsPlaying = false;
        if (mFinishCallBack != null)
        {
            mFinishCallBack.Invoke(StopType.ST_Finish);
            mFinishCallBack = null;
        }

        Dispose();
    }
}
