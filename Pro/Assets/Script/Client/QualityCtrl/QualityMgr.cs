#define TEST_NEWAB

using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine.SceneManagement;

using UnityStandardAssets.CinematicEffects;
using Loong.Game;
using SleekRender;



public class MatLoadingCont
{
    public GameObject mUnitObj = null;
    public Renderer mRen = null;
    public Material[] mChangeMats = null;
    public int[] mCheckInds = null;
    public bool mSceneMat = false;

    public float mLimitTimer = -1f;
    public bool mNeedTimeLimit = false;
    public List<String> mNeedMatNames = new List<string>();

    public void Init(Renderer renderer, GameObject unitObj, bool sceneMat)
    {
        mRen = renderer;
        mUnitObj = unitObj;
        //mChangeMats = mRen.materials;
        mChangeMats = mRen.sharedMaterials;
        mCheckInds = new int[mChangeMats.Length];
        for (int a = 0; a < mCheckInds.Length; a++)
        {
            mCheckInds[a] = 0;
        }
        mSceneMat = sceneMat;

        mLimitTimer = QualityMgr.LOAD_ONE_MAT_LIMIT * mChangeMats.Length;
        mNeedTimeLimit = false;
        if (mLimitTimer > 0)
        {
            mNeedTimeLimit = true;
        }
        mNeedMatNames.Clear();
    }

    public void Reset()
    {
        mRen = null;
        mChangeMats = null;
        mCheckInds = null;
        mSceneMat = false;
        mLimitTimer = -1f;
        mNeedTimeLimit = false;
        mNeedMatNames.Clear();
    }

    public void AddNeedMatName(string matName)
    {
        if(mNeedMatNames.Contains(matName) == false)
        {
            mNeedMatNames.Add(matName);
        }
    }

    public void Update(float dTime)
    {
        if(mNeedTimeLimit == true)
        {
            mLimitTimer -= dTime;
            if(mLimitTimer <= 0)
            {
                RecycleSelf();
            }
        }
    }

    public void LoadMatFin(string matName, int matInd, bool showLog, UnityEngine.Object obj)
    {
        if(mNeedMatNames.Contains(matName) == false && obj != null)
        {
            iTrace.Error("LY", "Change quality load mat component has destoryed !!! " + matName);
            return;
        }

        Material tMat = null;

        /// 返回AB包 ///
        if (obj != null && obj is AssetBundle)
        {
            AssetBundle tAB = obj as AssetBundle;
            string[] allPath = tAB.GetAllAssetNames();
            if(allPath == null)
            {
                return;
            }
            else
            {
                for(int a = 0; a < allPath.Length; a++)
                {
                    string tPName = allPath[a];
                    tPName = tPName.ToLower();
                    string tMName = matName.ToLower();
                    if(tPName.Contains(tMName))
                    {
                        tMat = tAB.LoadAsset(allPath[a]) as Material;
                        if(tMat == null)
                        {
                            iTrace.Error("LY", "Object is not Material !!! ");
                            return;
                        }

                        if (mSceneMat == false)
                        {
                            string abName = tAB.name.Replace(".ab", "");
                            AssetMgr.Instance.SetPersist(abName);
                        }
                    }
                }
            }
        }
        else
        {
            if (obj == null || obj is Material == false)
            {
                if (showLog == true)
                {
                    if (mSceneMat == true)
                    {
                        QualityMgr.instance.AddMissMatName(matName);
                    }
                    else
                    {
                        iTrace.Error("LY", "Can not find quality material !!!  :  " + matName);
                    }
                }
                mCheckInds[matInd] = 1;
                if (CheckLoadFin() == true)
                {
                    if (mRen == null)
                    {
#if GAME_DEBUG
                        iTrace.Warning("LY", "Change quality object is null !!! ");
#endif
                    }
                    else
                    {
                        //mRen.materials = mChangeMats;
                        mRen.sharedMaterials = mChangeMats;
#if UNITY_EDITOR
                        if (mSceneMat == false)
                        {
                            ShaderTool.ResetGbj(mRen.gameObject);
                        }
#endif
                        //if (mUnitObj != null)
                        //{
                        //    UnitMgr.instance.SetSelfAssetPst(mUnitObj);
                        //}
                    }
                    RecycleSelf();
                }
                return;
            }

            tMat = obj as Material;
            if (mSceneMat == false)
            {
                AssetMgr.Instance.SetPersist(tMat.name, Suffix.Mat);
            }
        }

        //Material tMat = obj as Material;
        if (tMat != null)
        {
            mChangeMats[matInd] = tMat;
            //if (mSceneMat == false)
            //{
            //    //AssetMgr.Instance.SetPersist(tMat.name);
            //    AssetMgr.Instance.SetPersist(tMat.name, Suffix.Mat);
            //}
        }
        mCheckInds[matInd] = 1;

        if (mSceneMat == true)
        {
            QualityMgr.instance.CheckAddLoadedMat(matName, tMat);
        }

        if (CheckLoadFin() == true)
        {
            if(mRen == null)
            {
#if GAME_DEBUG
                iTrace.eWarning("LY", "Change quality object is null !!! ");
#endif
            }
            else
            {
                //mRen.materials = mChangeMats;
                mRen.sharedMaterials = mChangeMats;
#if UNITY_EDITOR
                if (mSceneMat == false)
                {
                    ShaderTool.ResetGbj(mRen.gameObject);
                }
#endif
                //if(mUnitObj != null)
                //{
                //    UnitMgr.instance.SetSelfAssetPst(mUnitObj);
                //}
            }
            RecycleSelf();
        }
    }

    private bool CheckLoadFin()
    {
        for(int a = 0; a < mCheckInds.Length; a++)
        {
            if(mCheckInds[a] == 0)
            {
                return false;
            }
        }

        return true;
    }

    /// <summary>
    /// 回收容器
    /// </summary>
    private void RecycleSelf()
    {
        if(mSceneMat == true)
        {
            QualityMgr.instance.RemoveSceneMLC(this);
        }
        else
        {
            QualityMgr.instance.RemoveUnitMLC(this);
        }
    }
}


/// <summary>
/// 游戏质量管理器
/// </summary>
public class QualityMgr : IModule
{
    /// <summary>
    /// 读取一个材质的极限时间
    /// </summary>
    public static float LOAD_ONE_MAT_LIMIT = 5f;

    /// <summary>
    /// 品质保存字段名称
    /// </summary>
    public static string QUALITY_SAVE_NAME = "quality_save";

    /// <summary>
    /// 禁止场景节点质量转换
    /// </summary>
    private static bool BLOCK_SCENENODE_CHANGE = false;
    /// <summary>
    /// 禁止场景材质质量转换
    /// </summary>
    private static bool BLOCK_SCENEMAT_CHANGE = false;
    /// <summary>
    /// 禁止角色材质质量转换
    /// </summary>
    private static bool BLOCK_CHARMAT_CHANGE = false;
    /// <summary>
    /// 禁止摄像机控件质量转换
    /// </summary>
    private static bool BLOCK_CAMEFF_CHANGE = false;
    /// <summary>
    /// 禁止动画质量转换
    /// </summary>
    private static bool BLOCK_ANIM_CHANGE = false;


    /// <summary>
    /// 总品质类型(越大越高)
    /// </summary>
    public enum TotalQualityType
    {
        TQT_Unknown = -1,
        TQT_PSM,                    /*省电模式*/
        TQT_1,
        TQT_2,
        TQT_3,
        //TQT_4,
        TQT_Max
    }

    /// <summary>
    /// 材质品质类型
    /// </summary>
    public enum MatQualityType
    {
        MQT_Unknown = 0,
        MQT_Low,
        MQT_High,
        MQT_Max
    }

    public enum SceneQualityType
    {
        SQT_Unknown = 0,
        SQT_Low,
        SQT_Middle,
        SQT_High,
        SQT_Max
    }

    /// <summary>
    /// 摄像机品质类型
    /// </summary>
    public enum CamQualityType
    {
        CQT_Unknown = 0,
        CQT_1,
        CQT_2,
        CQT_3,
        //CQT_4,
        CQT_Max
    }

    /// <summary>
    /// 动画质量类型
    /// </summary>
    public enum AnimQualityType
    {
        AQT_Unknown = 0,
        AQT_1,
        AQT_2,
        AQT_3,
        //AQT_4,
        AQT_Max
    }


    public static readonly QualityMgr instance = new QualityMgr();

    /// <summary>
    /// 当前总品质类型
    /// </summary>
    private TotalQualityType mCurTQT = TotalQualityType.TQT_Unknown;
    /// <summary>
    /// 当前材质品质类型
    /// </summary>
    private MatQualityType mCurMQT = MatQualityType.MQT_Unknown;
    /// <summary>
    /// 当前场景质量类型
    /// </summary>
    private SceneQualityType mCurSQT = SceneQualityType.SQT_Unknown;
    /// <summary>
    /// 当前摄像机质量类型
    /// </summary>
    private CamQualityType mCurCQT = CamQualityType.CQT_Unknown;
    /// <summary>
    /// 当前过场动画质量类型
    /// </summary>
    private AnimQualityType mCurAQT = AnimQualityType.AQT_Unknown;

    /// <summary>
    /// 质量保存索引(当索引>0，使用索引值质量设置)
    /// </summary>
    private int mSaveQualityIndex = 0;
    /// <summary>
    /// 最大质量索引
    /// </summary>
    private int mMaxQua = 1;
    /// <summary>
    /// 当前质量怪物显示数量(-1为没有限制)
    /// </summary>
    private int mShowEvilNum = -1;
    /// <summary>
    /// 怪物数量显示控制标准
    /// </summary>
    private List<int> mEvilShowRefer = new List<int>();
    /// <summary>
    /// 当前质量角色显示数量
    /// </summary>
    private int mShowPlayerNum = 2;


    /// <summary>
    /// 加载材质容器
    /// </summary>
    private List<MatLoadingCont> mMLCPool = new List<MatLoadingCont>();
    /// <summary>
    /// 场景物体材质转换容器
    /// </summary>
    private List<MatLoadingCont> mSceneObjMLC = new List<MatLoadingCont>();
    /// <summary>
    /// 单位物体材质转换容器
    /// </summary>
    private List<MatLoadingCont> mUnitObjMLC = new List<MatLoadingCont>();
    /// <summary>
    /// 本次转换已经读取的材质字典
    /// </summary>
    private Dictionary<string, Material> m_mapSceneObjMat = new Dictionary<string, Material>();

    /// <summary>
    /// 准备卸载材质
    /// </summary>
    private Dictionary<string, Material> m_mapUnloadMat = new Dictionary<string, Material>();


    private int mMapId = -1;
    private bool hasSceneMat = false;
    private bool settingMat = false;
    private List<string> missMatNames = new List<string>();


    /// <summary>
    /// 原始品质类型
    /// </summary>
    private TotalQualityType mOriTQT = TotalQualityType.TQT_Unknown;
    /// <summary>
    /// 原始屏蔽特效
    /// </summary>
    private bool mOriShieldEff = false;
    /// <summary>
    /// 原始显示玩家角色数量
    /// </summary>
    private int mOriPlayerShowNum = 4;
    /// <summary>
    /// 原始目标帧率
    /// </summary>
    private int mOriFPS = 30;
    /// <summary>
    /// 原始屏幕亮度
    /// </summary>
    private float mOriBrightness = 1f;

    /// <summary>
    /// 使用省电模式
    /// </summary>
    private bool usePowerSaveMode = false;
    /// <summary>
    /// 进入省电模式等待时间
    /// </summary>
    private float mEnterPSMTime = 300f;
    /// <summary>
    /// 是否使用省电模式
    /// </summary>
    private bool mUsePSM = false;
    /// <summary>
    /// 手动进入省电模式
    /// </summary>
    private bool mManualEnterPSM = false;

    private bool mNeedSetQuaAgain = false;
    /// <summary>
    /// 计时器
    /// </summary>
    private float mTimer = 0f;


    /// <summary>
    /// 显示控制器
    /// </summary>
    private QualityDisplayCtrl mDisplayCtrl = null;


    public int MaxQuality
    {
        get { return mMaxQua; }
    }
    public TotalQualityType TotalQuality
    {
        get { return mCurTQT; }
    }
    public MatQualityType MatQuality
    {
        get { return mCurMQT; }
    }
    public SceneQualityType SceneQuality
    {
        get { return mCurSQT; }
    }
    public CamQualityType CamQuality
    {
        get { return mCurCQT; }
    }
    public AnimQualityType AnimQuality
    {
        get { return mCurAQT; }
    }
    public int SaveQualityIndex
    {
        get { return mSaveQualityIndex; }
        set
        {
            mSaveQualityIndex = value;
        }
    }
    public int ShowEvilNum
    {
        get { return mShowEvilNum; }
        set
        {
            mShowEvilNum = value;
        }
    }
    public bool UsePowerSaveMode
    {
        get { return usePowerSaveMode; }
    }
    public QualityDisplayCtrl DisplayCtrl
    {
        get { return mDisplayCtrl; }
    }


    public int GetTotalQua()
    {
        return (int)mCurTQT;
    }


    private QualityMgr()
    {

    }

    public void Init()
    {
        Initialize();
    }

    public void Initialize()
    {
        GlobalData tGD = GlobalDataManager.instance.Find(154);
        if (tGD != null)
        {
            bool usePre = false;
            if (tGD.num1 == "1")
            {
                usePre = true;
            }
            UIEffectBindingMgr.instance.SetGlobalData(usePre, tGD.num3);
        }

        /// 怪物控制显示数量 ///
        mEvilShowRefer.Clear();
        tGD = GlobalDataManager.instance.Find(172);
        if(tGD != null)
        {
            if (int.Parse(tGD.num1) <= 0)
            {
                mEvilShowRefer.Add(4);
                mEvilShowRefer.Add(10);
                mEvilShowRefer.Add(-1);
                mEvilShowRefer.Add(-1);
            }
            else
            {
                List<uint> tShowNums = tGD.num2.list;
                for(int a = 0; a < tShowNums.Count; a++)
                {
                    if(tShowNums[a] >= 100)
                    {
                        mEvilShowRefer.Add(-1);
                    }
                    else
                    {
                        mEvilShowRefer.Add((int)tShowNums[a]);
                    }
                }
            }
        }
        else
        {
            mEvilShowRefer.Add(4);
            mEvilShowRefer.Add(10);
            mEvilShowRefer.Add(-1);
            mEvilShowRefer.Add(-1);
        }

        mMapId = -1;

        mCurTQT = TotalQualityType.TQT_Unknown;
        mCurMQT = MatQualityType.MQT_Unknown;
        mCurSQT = SceneQualityType.SQT_Unknown;
        mCurCQT = CamQualityType.CQT_Unknown;
        mCurAQT = AnimQualityType.AQT_Unknown;

        InitTotalQualityByDevice();

        mDisplayCtrl = new QualityDisplayCtrl();

        GlobalData tData = GlobalDataManager.instance.Find(117);
        if (tData != null)
        {
            if (string.IsNullOrEmpty(tData.num1) == false)
            {
                if (int.Parse(tData.num1) <= 0)
                {
                    mUsePSM = false;
                }
                else
                {
                    mUsePSM = true;
                }
            }
            if(string.IsNullOrEmpty(tData.num3) == false)
            {
                float.TryParse(tData.num3, out mEnterPSMTime);
            }
        }
        mTimer = 0f;

        EventMgr.Add(EventKey.OnChangeScene, FinChangeScene);
        EventMgr.Add("EventChangeAnimQuality", EventChangeAnimQuality);
        
        //EventMgr.Add("BreakPowerSaveMode", ResetPSMTimer);
        UICamera.onClick += ResetPSMTimer;
    }

    public void Clear(bool reconnect = false)
    {
        if (reconnect) return;
        mMapId = -1;

        mDisplayCtrl.Clear();
        CutscenePlayMgr.instance.ClearPlayedCutsNames();
    }

    public void Dispose()
    {
        mDisplayCtrl.Dispose();
    }

    public void BegChgScene()
    {

    }

    public void EndChgScene()
    {

    }

    /// <summary>
    /// 根据保存数据初始化等级
    /// </summary>
    //private void InitTotalQualityBySave()
    //{
    //    if (mCurTQT == TotalQualityType.TQT_Unknown)
    //    {
    //        int tCurTQT = PlayerPrefs.GetInt(QUALITY_SAVE_NAME, 0);
    //        ChangeQuality((TotalQualityType)tCurTQT);
    //    }
    //}

    /// <summary>
    /// 根据设备初始化等级
    /// </summary>
    private void InitTotalQualityByDevice()
    {
        //#if UNITY_EDITOR || UNITY_IOS
#if UNITY_EDITOR
        //mCurTQT = TotalQualityType.TQT_1;
        //ChangeQuality(TotalQualityType.TQT_2);
        ChangeQuality(TotalQualityType.TQT_3);
        mMaxQua = 1;
#else

        if(mCurTQT == TotalQualityType.TQT_Unknown)
        {
            string mName = Device.Instance.Model;

            //iTrace.Log("LY", "================================  Device  : " + mName);

            MobileInfo mInfo = null;
            List<MobileInfo> mInfoList = MobileInfoManager.instance.GetList();
            for(int a = 0; a < mInfoList.Count; a++)
            {
                if(mInfoList[a].motype == mName)
                {
                    mInfo = mInfoList[a];
                }
            }

            TotalQualityType tType = TotalQualityType.TQT_1;
            mMaxQua = 1;

            if(mSaveQualityIndex > 0)
            {
                if(mSaveQualityIndex >= (int)TotalQualityType.TQT_Max)
                {
                    tType = TotalQualityType.TQT_3;
                }
                else
                {
                    tType = (TotalQualityType)mSaveQualityIndex;
                }

                if (mInfo != null)
                {
                    mMaxQua = (int)mInfo.quility;
                }
                else
                {
                    mMaxQua = mSaveQualityIndex;
                }
            }
            else
            {
                if (mInfo != null)
                {
                    tType = (TotalQualityType)mInfo.quility;
                    mMaxQua = (int)mInfo.quility;
                    if (tType >= TotalQualityType.TQT_Max)
                    {
                        tType = TotalQualityType.TQT_3;
                        mMaxQua = (int)TotalQualityType.TQT_3;
                    }
                }
                else
                {
#if UNITY_IOS
                    tType = TotalQualityType.TQT_3;
                    mMaxQua = 3;
#endif
                }
            }

            iTrace.Log("LY", "================================  Game Quality  : " + tType);

            ChangeQuality(tType);
            //mMaxQua = 3;
        }

        /// 临时改动，高版本 ///
        //ChangeQuality(TotalQualityType.TQT_3);
        //mMaxQua = 3;
#endif

        if (mMaxQua <= 1)
        {
            CameraMgr.UseSceneRT = true;
            UIMgr.CreateRTCom();
        }
        else
        {
            CameraMgr.UseSceneRT = false;
        }
    }

    public void Update(float dTime)
    {
        if (mSceneObjMLC != null)
        {
            for (int a = 0; a < mSceneObjMLC.Count; a++)
            {
                mSceneObjMLC[a].Update(dTime);
            }
        }
        if (mUnitObjMLC != null)
        {
            for (int a = 0; a < mUnitObjMLC.Count; a++)
            {
                mUnitObjMLC[a].Update(dTime);
            }
        }

        if (mDisplayCtrl != null)
        {
            mDisplayCtrl.Update(dTime);
        }

        if (mUsePSM == true && mTimer < mEnterPSMTime)
        {
            mTimer += dTime;
            if (mTimer >= mEnterPSMTime)
            {
                EnterPowerSaveMode();
            }
        }

        OnPSMTextUpdate();
    }

    public void ResetPSMTimer(GameObject go)
    {
        if(go == null)
        {
            mTimer = 0f;
            ExitPowerSaveMode();
        }
        else
        {
            if (UITool.On == true)
            {
                mTimer = 0f;
                ExitPowerSaveMode();
            }
        }
    }

    /// <summary>
    /// 获取已经加载的材质
    /// </summary>
    /// <param name="matName"></param>
    /// <returns></returns>
    public Material GetMatHasLoaded(string matName)
    {
        if (m_mapSceneObjMat.ContainsKey(matName) == true)
        {
            return m_mapSceneObjMat[matName];
        }

        return null;
    }

    /// <summary>
    /// 检测添加已近读取的材质
    /// </summary>
    /// <param name="matName"></param>
    /// <param name="mat"></param>
    /// <returns></returns>
    public void CheckAddLoadedMat(string matName, Material mat)
    {
        if (m_mapSceneObjMat.ContainsKey(matName) == false)
        {
            m_mapSceneObjMat.Add(matName, mat);
        }
    }

    /// <summary>
    /// 转换场景到当前设定材质材质
    /// </summary>
    public void ChangeSceneToCurQuality()
    {
        m_mapSceneObjMat.Clear();
        m_mapUnloadMat.Clear();
        SetAllQualityToCur();
    }


    /// <summary>
    /// 读取场景完成
    /// </summary>
    private void FinChangeScene(params object[] args)
    {
        int tScene = (int)args[0];
        SceneInfo tInfo = SceneInfoManager.instance.Find((uint)tScene);
        if (tInfo == null)
        {
            iTrace.Error("LY", "Can not find scene info !!! " + tScene);
            return;
        }

        if (mMapId == (int)tInfo.mapId)
        {
            return;
        }

        mMapId = (int)tInfo.mapId;
        iTrace.eLog("LY", "Will be change scene quality !!! ");
        //ChangeQuality(mCurTQT);
        m_mapSceneObjMat.Clear();
        m_mapUnloadMat.Clear();
        SetAllQualityToCur();
    }

    /// <summary>
    /// 获取加载容器
    /// </summary>
    /// <returns></returns>
    private MatLoadingCont GetMLC()
    {
        MatLoadingCont retCont = null;
        if (mMLCPool.Count > 0)
        {
            retCont = mMLCPool[mMLCPool.Count - 1];
            mMLCPool.RemoveAt(mMLCPool.Count - 1);
        }
        else
        {
            retCont = new MatLoadingCont();
        }
        retCont.Reset();

        return retCont;
    }

    /// <summary>
    /// 回收容器
    /// </summary>
    private void RecycleMLC(MatLoadingCont matCont)
    {
        mMLCPool.Add(matCont);
    }

    private void AddUnloadMat(string matName, Material mat)
    {
        if (m_mapUnloadMat.ContainsKey(matName) == false)
        {
            m_mapUnloadMat.Add(matName, mat);
        }
    }

    /// <summary>
    /// 卸载替换的材质
    /// </summary>
    private void UnloadCacheMat()
    {
        //var em = m_mapUnloadMat.GetEnumerator();
        //while (em.MoveNext())
        //{
        //    AssetMgr.Instance.Unload(em.Current.Key);
        //    if(em.Current.Value != null)
        //    {
        //        GameObject.DestroyImmediate(em.Current.Value);
        //    }
        //}

        m_mapUnloadMat.Clear();
    }

    private void CheckResetShader()
    {
        if (mSceneObjMLC.Count <= 0 && hasSceneMat == true && settingMat == false)
        {
            UnloadCacheMat();

            m_mapSceneObjMat.Clear();
            PrintMissMatName();
#if UNITY_EDITOR
            ShaderTool.ResetScene(SceneManager.GetActiveScene());
            UnityEngine.Debug.Log("==============================================    Reset scene shader ");
#endif
            hasSceneMat = false;
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="matCont"></param>
    public void RemoveSceneMLC(MatLoadingCont matCont)
    {
        if (mSceneObjMLC.Contains(matCont) == true)
        {
            mSceneObjMLC.Remove(matCont);
            RecycleMLC(matCont);
        }

        CheckResetShader();
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="matCont"></param>
    public void RemoveUnitMLC(MatLoadingCont matCont)
    {
        if (mUnitObjMLC.Contains(matCont) == true)
        {
            mUnitObjMLC.Remove(matCont);
            RecycleMLC(matCont);
        }
    }

    public void ChangeQuaByIndex(int quaIndex)
    {
        if(quaIndex == 0)
        {
            mManualEnterPSM = true;
            EnterPowerSaveMode();
            UnitMgr.instance.ResetTtlAndCfn();
            return;
        }

        mManualEnterPSM = false;
        if(usePowerSaveMode == true)
        {
            ExitPowerSaveMode();
            mNeedSetQuaAgain = true;
        }
        ChangeAndResetQuality((TotalQualityType)quaIndex);
        UnitMgr.instance.ResetTtlAndCfn();
    }


    public void ChangeQualityByIndex(int quaIndex)
    {
        ChangeQuality((TotalQualityType)quaIndex);
    }

    /// <summary>
    /// 转换品质
    /// </summary>
    /// <param name="qt"></param>
    public void ChangeQuality(TotalQualityType tqt)
    {
        if (tqt <= TotalQualityType.TQT_Unknown)
        {
            mCurTQT = TotalQualityType.TQT_1;
        }
        else if (tqt >= TotalQualityType.TQT_Max)
        {
            mCurTQT = TotalQualityType.TQT_3;
        }
        else
        {
            mCurTQT = tqt;
        }

        switch (mCurTQT)
        {
            case TotalQualityType.TQT_PSM:
                {
                    if(usePowerSaveMode == false)
                    {
                        mCurMQT = MatQualityType.MQT_Low;
                    }
                    mCurSQT = SceneQualityType.SQT_Low;
                    mCurCQT = CamQualityType.CQT_1;
                    mCurAQT = AnimQualityType.AQT_1;

                    mShowEvilNum = 4;
                    mShowPlayerNum = 0;
                }
                break;
            case TotalQualityType.TQT_1:
                {
                    if (usePowerSaveMode == false)
                    {
                        mCurMQT = MatQualityType.MQT_Low;
                    }
                    mCurSQT = SceneQualityType.SQT_Low;
                    mCurCQT = CamQualityType.CQT_1;
                    mCurAQT = AnimQualityType.AQT_1;

                    mShowEvilNum = 10;
                    mShowPlayerNum = 2;
                }
                break;
            case TotalQualityType.TQT_2:
                {
                    if (usePowerSaveMode == false)
                    {
                        mCurMQT = MatQualityType.MQT_Low;
                    }
                    mCurSQT = SceneQualityType.SQT_Middle;
                    mCurCQT = CamQualityType.CQT_2;
                    mCurAQT = AnimQualityType.AQT_2;

                    mShowEvilNum = -1;
                    mShowPlayerNum = 6;
                }
                break;
            case TotalQualityType.TQT_3:
                {
                    if (usePowerSaveMode == false)
                    {
                        mCurMQT = MatQualityType.MQT_High;
                    }
                    mCurSQT = SceneQualityType.SQT_High;
                    mCurCQT = CamQualityType.CQT_3;
                    mCurAQT = AnimQualityType.AQT_3;

                    mShowEvilNum = -1;
                    mShowPlayerNum = 8;
                }
                break;
            //case TotalQualityType.TQT_4:
            //    {
            //        mCurMQT = MatQualityType.MQT_High;
            //        mCurSQT = SceneQualityType.SQT_High;
            //        mCurCQT = CamQualityType.CQT_4;
            //        mCurAQT = AnimQualityType.AQT_4;
            //    }
            //    break;
            default:
                {
                    iTrace.eError("LY", "Total quality type error !!! ");

                    if (usePowerSaveMode == false)
                    {
                        mCurMQT = MatQualityType.MQT_Low;
                    }
                    mCurSQT = SceneQualityType.SQT_Low;
                    mCurCQT = CamQualityType.CQT_1;
                    mCurAQT = AnimQualityType.AQT_1;

                    mShowEvilNum = 10;
                    mShowPlayerNum = 2;
                }
                break;
        }

        AmplifyColorEffect.QualityLv = (int)mCurAQT;
        CoolMotionBlur.QualityLv = (int)mCurAQT;

        //SetAllQualityToCur();
    }

    /// <summary>
    /// 设置相应效果到指定状态
    /// </summary>
    private void SetAllQualityToCur()
    {
        ChangeSceneQuality();
        ChangeSceneMatQuality();
        ChangeUnitMatQuality();
        ChangeCamQuality();

        mDisplayCtrl.CheckEvilShowState();
        EventMgr.Trigger("RequestClipPlayerNum", mShowPlayerNum);
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="tqt"></param>
    public void ChangeAndResetQuality(TotalQualityType tqt)
    {
        if (mCurTQT == tqt && mNeedSetQuaAgain == false)
            return;
        
        ChangeQuality(tqt);
        SetAllQualityToCur();
        mNeedSetQuaAgain = false;
    }

    /// <summary>
    /// 转换所有单位材质
    /// </summary>
    public void ChangeUnitMatQuality()
    {
        if (BLOCK_CHARMAT_CHANGE == true || usePowerSaveMode == true)
        {
            return;
        }

        List<Unit> checkUnits = UnitMgr.instance.UnitList;
        for (int a = 0; a < checkUnits.Count; a++)
        {
            if (checkUnits[a].UnitTrans != null && checkUnits[a].UnitTrans.gameObject != null)
            {
                ChangeGoQuality(checkUnits[a].UnitTrans.gameObject);
            }
        }
    }

    private void ChangeGoMat(GameObject go, MatQualityType matType, bool sceneMat)
    {
        Renderer[] rens = go.GetComponentsInChildren<Renderer>(true);
        if (rens == null)
            return;

        bool need = false;
        for (int a = 0; a < rens.Length; a++)
        {
            if (ChangeRendererMat(rens[a], go, matType, sceneMat) == true
                && need == false)
            {
                need = true;
            }
        }

#if UNITY_EDITOR
        if (need == false)
        {
            ShaderTool.ResetGbj(go);
        }
#endif

    }

    private bool ChangeRendererMat(Renderer ren, GameObject go, MatQualityType matType, bool sceneMat)
    {
        if (ren == null)
        {
            return false;
        }

        //Material[] tMats = ren.materials;
        Material[] tMats = ren.sharedMaterials;
        if (tMats == null || tMats.Length <= 0)
            return false;

        switch (matType)
        {
            /// 低转高 ///
            case MatQualityType.MQT_High:
                {
                    bool tNeed = false;
                    for (int i = 0; i < tMats.Length; i++)
                    {
                        if (tMats[i] != null && tMats[i].name.Contains("_low") == true)
                        {
                            tNeed = true;
                        }
                    }
                    if (tNeed == false)
                    {
                        return false;
                    }

                    MatLoadingCont tMLC = GetMLC();
                    tMLC.Init(ren, go, sceneMat);
                    if (sceneMat == true)
                    {
                        mSceneObjMLC.Add(tMLC);
                        hasSceneMat = true;
                    }
                    else
                    {
                        mUnitObjMLC.Add(tMLC);
                    }

                    for (int a = 0; a < tMats.Length; a++)
                    {
                        int matInd = a;
                        if (tMats[a] == null)
                        {
                            tMLC.LoadMatFin("Object name : " + ren.name, matInd, true, null);
                        }
                        else
                        {
                            string matName = tMats[a].name.Replace(" (Instance)", "");
                            if (matName.Contains("_low"))
                            {
                                //iTrace.eLog("LY", "Replace low mat :    " + matName);
                                matName = matName.Replace("_low", "_Height");
                                tMLC.AddNeedMatName(matName);

                                if (sceneMat == true && m_mapSceneObjMat.ContainsKey(matName) == true)
                                {
                                    tMLC.LoadMatFin(matName, matInd, true, m_mapSceneObjMat[matName]);
                                }
                                else
                                {
                                    string abName = "";
#if TEST_NEWAB
                                    //if (matName == "Zhizhu_T_Height")
                                    //{
                                    abName = matName.Replace("_Height", "_mat");
                                    abName = abName.ToLower();
                                    //}
#else
                                    //else
                                    //{
                                    abName = matName + ".mat";
                                    //}
#endif
                                    //AddUnloadMat(abName, tMats[a]);

                                    AssetMgr.Instance.Load(abName, (UnityEngine.Object obj) =>
                                    {
                                        /// 等待时间很长，已经被销毁(通常是读取不到相应材质) ///
                                        if (tMLC == null || mMLCPool.Contains(tMLC) == true)
                                        {
                                            iTrace.Error("LY", "Change quality load mat component has destoryed !!! " + abName);
                                            return;
                                        }

                                        tMLC.LoadMatFin(matName, matInd, true, obj);
                                    });
                                }
                            }
                            else
                            {
                                tMLC.LoadMatFin(matName, matInd, false, null);
                            }
                        }
                    }
                }
                break;
            /// 高转低 ///
            case MatQualityType.MQT_Low:
                {
                    bool tNeed = false;
                    for (int i = 0; i < tMats.Length; i++)
                    {
                        if (tMats[i] != null && tMats[i].name.Contains("_Height") == true)
                        {
                            tNeed = true;
                        }
                    }
                    if (tNeed == false)
                    {
                        return false;
                    }

                    MatLoadingCont tMLC = GetMLC();
                    tMLC.Init(ren, go, sceneMat);
                    if (sceneMat == true)
                    {
                        mSceneObjMLC.Add(tMLC);
                    }
                    else
                    {
                        mUnitObjMLC.Add(tMLC);
                    }
                    hasSceneMat = true;

                    for (int a = 0; a < tMats.Length; a++)
                    {
                        int matInd = a;
                        if (tMats[a] == null)
                        {
                            tMLC.LoadMatFin("Object name : " + ren.name, matInd, true, null);
                        }
                        else
                        {
                            string matName = tMats[a].name.Replace(" (Instance)", "");
                            if (matName.Contains("_Height"))
                            {
                                //iTrace.eLog("LY", "Replace low mat :    " + matName);
                                matName = matName.Replace("_Height", "_low");
                                tMLC.AddNeedMatName(matName);

                                if (sceneMat == true && m_mapSceneObjMat.ContainsKey(matName) == true)
                                {
                                    tMLC.LoadMatFin(matName, matInd, true, m_mapSceneObjMat[matName]);
                                }
                                else
                                {
                                    string abName = "";
#if TEST_NEWAB
                                    //if (matName == "Zhizhu_T_low")
                                    //{
                                    abName = matName.Replace("_low", "_mat");
                                    abName = abName.ToLower();
                                    //}
#else
                                    //else
                                    //{
                                    abName = matName + ".mat";
                                    //}
#endif
                                    //AddUnloadMat(matName, tMats[a]);

                                    AssetMgr.Instance.Load(abName, (UnityEngine.Object obj) =>
                                    {
                                        /// 等待时间很长，已经被销毁(通常是读取不到相应材质) ///
                                        if (tMLC == null || mMLCPool.Contains(tMLC) == true)
                                        {
                                            iTrace.Error("LY", "Change quality load mat component has destoryed !!! " + abName);
                                            return;
                                        }

                                        tMLC.LoadMatFin(matName, matInd, true, obj);
                                    });
                                }
                            }
                            else
                            {
                                tMLC.LoadMatFin(matName, matInd, false, null);
                            }
                        }
                    }
                }
                break;
            default:
                break;
        }

        return true;
    }

    /// <summary>
    /// 转换场景中物体材质品质
    /// </summary>
    /// <param name="qt"></param>
    private void ChangeSceneMatQuality()
    {
        if (BLOCK_SCENEMAT_CHANGE == true || usePowerSaveMode == true)
        {
            return;
        }

        GameObject[] allSceneObjs = SceneManager.GetActiveScene().GetRootGameObjects();
        if (allSceneObjs == null || allSceneObjs.Length <= 0)
            return;

        missMatNames.Clear();
        hasSceneMat = false;

        settingMat = true;
        for (int a = 0; a < allSceneObjs.Length; a++)
        {
            ChangeGoMat(allSceneObjs[a], mCurMQT, true);
        }
        settingMat = false;
        CheckResetShader();



    }

    /// <summary>
    /// 场景节点质量设置
    /// </summary>
    /// <param name="sqt"></param>
    public void ChangeSceneQuality()
    {
        if (BLOCK_SCENENODE_CHANGE == true)
        {
            return;
        }

        GameObject tSceneRoot = GameObject.Find("Scene_Object");
        if (tSceneRoot == null)
        {
            tSceneRoot = GameObject.Find("Scene_object");
        }
        if (tSceneRoot == null)
        {
            tSceneRoot = GameObject.Find("scene_object");
        }
        if (tSceneRoot == null)
        {
            tSceneRoot = GameObject.Find("scene_Object");
        }
        if (tSceneRoot == null)
        {
            iTrace.eLog("LY", "Scene_Object miss !!! ");
            return;
        }
        
        List<GameObject> tAll = new List<GameObject>();
        List<GameObject> tMP = new List<GameObject>();
        List<GameObject> tLP = new List<GameObject>();

        for (int a = 0; a < tSceneRoot.transform.childCount; a++)
        {
            GameObject tObj = tSceneRoot.transform.GetChild(a).gameObject;
            if (tObj.name == "All")
            {
                tAll.Add(tObj);
            }
            else if (tObj.name == "MP")
            {
                tMP.Add(tObj);
            }
            else if (tObj.name == "LP")
            {
                tLP.Add(tObj);
            }

            for(int b = 0; b < tObj.transform.childCount; b++)
            {
                GameObject tCObj = tObj.transform.GetChild(b).gameObject;
                if(tCObj.name == "All")
                {
                    tAll.Add(tCObj);
                }
                else if (tCObj.name == "MP")
                {
                    tMP.Add(tCObj);
                }
                else if (tCObj.name == "LP")
                {
                    tLP.Add(tCObj);
                }
            }
        }

        switch (mCurSQT)
        {
            case SceneQualityType.SQT_Low:
                {
                    if (tAll != null)
                    {
                        for(int a = 0; a < tAll.Count; a++)
                        {
                            tAll[a].SetActive(true);
                        }
                    }
                    if (tMP != null)
                    {
                        for (int a = 0; a < tMP.Count; a++)
                        {
                            tMP[a].SetActive(false);
                        }
                    }
                    if (tLP != null)
                    {
                        for (int a = 0; a < tLP.Count; a++)
                        {
                            tLP[a].SetActive(false);
                        }
                    }
                }
                break;
            case SceneQualityType.SQT_Middle:
                {
                    if (tAll != null)
                    {
                        for (int a = 0; a < tAll.Count; a++)
                        {
                            tAll[a].SetActive(true);
                        }
                    }
                    if (tMP != null)
                    {
                        for (int a = 0; a < tMP.Count; a++)
                        {
                            tMP[a].SetActive(false);
                        }
                    }
                    if (tLP != null)
                    {
                        for (int a = 0; a < tLP.Count; a++)
                        {
                            tLP[a].SetActive(true);
                        }
                    }
                }
                break;
            case SceneQualityType.SQT_High:
                {
                    if (tAll != null)
                    {
                        for (int a = 0; a < tAll.Count; a++)
                        {
                            tAll[a].SetActive(true);
                        }
                    }
                    if (tMP != null)
                    {
                        for (int a = 0; a < tMP.Count; a++)
                        {
                            tMP[a].SetActive(true);
                        }
                    }
                    if (tLP != null)
                    {
                        for (int a = 0; a < tLP.Count; a++)
                        {
                            tLP[a].SetActive(true);
                        }
                    }
                }
                break;
            default:
                break;
        }
    }

    /// <summary>
    /// 摄像机品质设置
    /// </summary>
    /// <param name="cqt"></param>
    public void ChangeCamQuality()
    {
        if (BLOCK_CAMEFF_CHANGE == true)
        {
            return;
        }

        GameObject camObj = CameraMgr.Main.gameObject;
        AmplifyColorEffect mainACE = camObj.GetComponent<AmplifyColorEffect>();
        SleekRenderPostProcess mSRPP = camObj.GetComponent<SleekRenderPostProcess>();

        switch (mCurCQT)
        {
            case CamQualityType.CQT_1:
                {
                    if (mainACE != null)
                    {
                        mainACE.enabled = false;
                    }
                    if (mSRPP != null && mSRPP.settings != null)
                    {
                        SleekRenderPostProcess.BlockEffect = true;
                        mSRPP.enabled = false;

                        //mSRPP.settings.bloomEnabled = false;
                        ////mSRPP.settings.vignetteEnabled = true;
                    }
                }
                break;
            case CamQualityType.CQT_2:
                {
                    if (mainACE != null)
                    {
                        mainACE.enabled = true;
                    }
                    if (mSRPP != null && mSRPP.settings != null)
                    {
                        SleekRenderPostProcess.BlockEffect = true;
                        mSRPP.enabled = false;

                        //mSRPP.settings.bloomEnabled = true;
                        ////mSRPP.settings.vignetteEnabled = false;
                    }
                }
                break;
            case CamQualityType.CQT_3:
                {
                    if (mainACE != null)
                    {
                        mainACE.enabled = true;
                    }
                    if (mSRPP != null && mSRPP.settings != null)
                    {
                        SleekRenderPostProcess.BlockEffect = false;
                        mSRPP.enabled = true;

                        //mSRPP.settings.bloomEnabled = true;
                        ////mSRPP.settings.vignetteEnabled = false;
                    }
                }
                break;
            //case CamQualityType.CQT_4:
            //    {
            //        if (mainACE != null)
            //        {
            //            mainACE.enabled = true;
            //        }
            //        if (mSRPP != null)
            //        {
            //            SleekRenderPostProcess.BlockEffect = false;
            //            mSRPP.enabled = true;
            //        }
            //    }
            //    break;
            default:
                break;
        }
    }

    /// <summary>
    /// 改变动画质量设置
    /// </summary>
    /// <param name="aqt"></param>
    public void ChangeAnimQuality(GameObject camObj)
    {
        if (BLOCK_ANIM_CHANGE == true)
        {
            return;
        }

        AmplifyColorEffect mainACE = camObj.GetComponent<AmplifyColorEffect>();
        SleekRenderPostProcess mSRPP = camObj.GetComponent<SleekRenderPostProcess>();

        switch (mCurAQT)
        {
            case AnimQualityType.AQT_1:
                {
                    if (mainACE != null)
                    {
                        mainACE.enabled = false;
                    }
                    if (mSRPP != null && mSRPP.settings != null)
                    {
                        SleekRenderPostProcess.BlockEffect = true;
                        mSRPP.enabled = false;

                        //mSRPP.settings.bloomEnabled = false;
                        ////mSRPP.settings.vignetteEnabled = true;
                    }
                }
                break;
            case AnimQualityType.AQT_2:
                {
                    if (mainACE != null)
                    {
                        mainACE.enabled = true;
                    }
                    if (mSRPP != null && mSRPP.settings != null)
                    {
                        SleekRenderPostProcess.BlockEffect = true;
                        mSRPP.enabled = false;

                        //mSRPP.settings.bloomEnabled = true;
                        ////mSRPP.settings.vignetteEnabled = false;
                    }
                }
                break;
            case AnimQualityType.AQT_3:
                {
                    if (mainACE != null)
                    {
                        mainACE.enabled = true;
                    }
                    if (mSRPP != null && mSRPP.settings != null)
                    {
                        SleekRenderPostProcess.BlockEffect = false;
                        mSRPP.enabled = true;

                        //mSRPP.settings.bloomEnabled = true;
                        ////mSRPP.settings.vignetteEnabled = false;
                    }
                }
                break;
            //case AnimQualityType.AQT_4:
            //    {
            //        if (mainACE != null)
            //        {
            //            mainACE.enabled = true;
            //        }
            //        if (mSRPP != null)
            //        {
            //            SleekRenderPostProcess.BlockEffect = false;
            //            mSRPP.enabled = true;
            //        }
            //    }
            //    break;
            default:
                break;
        }
    }

    /// <summary>
    /// 改变传入物体品质
    /// </summary>
    /// <param name="go"></param>
    /// <returns></returns>
    public bool ChangeGoQuality(GameObject go)
    {
#if UNITY_EDITOR
        if (AssetMgr.Mode == LoadResMode.Asset)
        {
            return false;
        }
#endif
        if (BLOCK_CHARMAT_CHANGE == true)
        {
            return true;
        }

        if (mCurMQT <= MatQualityType.MQT_Unknown || mCurMQT >= MatQualityType.MQT_Max)
        {
            return false;
        }

        if (go == null)
        {
            iTrace.Error("LY", "Change quality gameObject is null !!! ");
            return false;
        }

        ChangeGoMat(go, mCurMQT, false);
        return true;
    }

    public void EventChangeAnimQuality(params object[] args)
    {
        if (args == null || args.Length <= 0 || args[0] == null)
        {
            return;
        }

        if (args[0] is GameObject)
        {
            GameObject changeObj = args[0] as GameObject;
            ChangeAnimQuality(changeObj);
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="matName"></param>
    public void AddMissMatName(string matName)
    {
        if (missMatNames.Contains(matName) == false)
        {
            missMatNames.Add(matName);
        }
    }

    /// <summary>
    /// 打印丢失材质名称
    /// </summary>
    private void PrintMissMatName()
    {
        for (int a = 0; a < missMatNames.Count; a++)
        {
            iTrace.Error("LY", "Can not find quality material !!!  :  " + missMatNames[a]);
        }
    }

    /// <summary>
    /// 获取屏幕亮度
    /// </summary>
    /// <returns></returns>
    private float GetSystemBrightness()
    {
#if UNITY_EDITOR
        return 1;
#elif UNITY_ANDROID
        AndroidJavaObject Activity = new AndroidJavaClass("com.unity3d.player.UnityPlayer").GetStatic<AndroidJavaObject>("currentActivity");
        AndroidJavaObject ContentResolver = Activity.Call<AndroidJavaObject>("getContentResolver");
        AndroidJavaClass SystemSetting = new AndroidJavaClass("android.provider.Settings$System");
        float brightness = SystemSetting.CallStatic<int>("getInt", ContentResolver, "screen_brightness") / 256.0f;

        return brightness;
#elif UNITY_IOS || UNITY_IPHONE
        return 1;
#else
        return 1;
#endif
    }

    /// <summary>
    /// 获取应用亮度
    /// </summary>
    /// <returns></returns>
    private float GetActiveBrightness()
    {
#if UNITY_EDITOR
        return 1;
#elif UNITY_ANDROID
        AndroidJavaObject Activity = new AndroidJavaClass("com.unity3d.player.UnityPlayer").GetStatic<AndroidJavaObject>("currentActivity"); 
        AndroidJavaObject Window = Activity.Call<AndroidJavaObject>("getWindow"); 
        AndroidJavaObject Attributes = Window.Call<AndroidJavaObject>("getAttributes"); 
        float brightness = Attributes.Get<float>("screenBrightness");

        return brightness;
#elif UNITY_IOS || UNITY_IPHONE
        return 1;
#else
        return 1;
#endif
    }

    /// <summary>
    /// 设置屏幕亮度
    /// </summary>
    /// <param name="brightness"></param>
    private void SetActiveBrightness(float brightness)
    {
#if UNITY_EDITOR

#elif UNITY_ANDROID
        try
        {
            AndroidJavaObject Activity = null;
            Activity = new AndroidJavaClass("com.unity3d.player.UnityPlayer").GetStatic<AndroidJavaObject>("currentActivity");
            Activity.Call("runOnUiThread", new AndroidJavaRunnable(() =>
            {
                AndroidJavaObject Window = null, Attributes = null;
                Window = Activity.Call<AndroidJavaObject>("getWindow");
                Attributes = Window.Call<AndroidJavaObject>("getAttributes");
                Attributes.Set("screenBrightness", brightness);
                Window.Call("setAttributes", Attributes);
            }));
        }
        catch (Exception exc)
        {
            iTrace.Error("LY", "SetApplicationBrightness : " + exc.Message);
        }
#elif UNITY_IOS || UNITY_IPHONE
        
#else
        
#endif
    }

    /// <summary>
    /// 进入省电模式
    /// </summary>
    public void EnterPowerSaveMode()
    {
        if (mUsePSM == false || usePowerSaveMode == true)
        {
            return;
        }

        /// 记录原始设定 ///
        mOriTQT = mCurTQT;
        mOriShieldEff = ShowEffectMgr.instance.IsShieldEff;
        mOriPlayerShowNum = SettingMgr.instance.MaxShowNum;
        mOriFPS = Application.targetFrameRate;
        mOriBrightness = GetActiveBrightness();
        if(mOriBrightness < 0)
        {
            mOriBrightness = GetSystemBrightness();
        }
        usePowerSaveMode = true;

        /// 转换到低质量（包括材质、屏蔽怪物数量、屏蔽玩家数量） ///
        ChangeAndResetQuality(TotalQualityType.TQT_PSM);
        /// 屏蔽特效 ///
        ShowEffectMgr.instance.IsShieldEff = true;

        Application.targetFrameRate = 15;
        if(mOriBrightness > 0.3f)
        {
            SetActiveBrightness(0.3f);
        }
    }

    /// <summary>
    /// 退出省电模式
    /// </summary>
    public void ExitPowerSaveMode()
    {
        if (mUsePSM == false || usePowerSaveMode == false || mManualEnterPSM == true)
        {
            return;
        }
        
        ChangeAndResetQuality(mOriTQT);
        ShowEffectMgr.instance.IsShieldEff = mOriShieldEff;

        usePowerSaveMode = false;

        EventMgr.Trigger("RequestClipPlayerNum", mOriPlayerShowNum);
        Application.targetFrameRate = mOriFPS;
        SetActiveBrightness(mOriBrightness);
    }

    private static int scaleWidth = 0;
    private static int scaleHeight = 0;

    public static int ScaleWidth
    {
        get { return scaleWidth; }
    }
    public static int ScaleHeight
    {
        get { return scaleHeight; }
    }

    public static void SetDesignContentScale()
    {
        //if (scaleWidth == 0 && scaleHeight == 0)
        {
            //int width = Screen.currentResolution.width;
            //int height = Screen.currentResolution.height;
            int width = Screen.width;
            int height = Screen.height;

            //记录原始像素,以修复iOS不能准确识别分辨率并设置刘海属性
            User.instance.oriScreenWd = width;
            User.instance.oriScreenHt = height;


            if (App.IsDebug)
            {
                iTrace.Log("LY", "Ori aspect = " + width + " x " + height);
                UnityEngine.Debug.LogWarning(" LY :   Ori aspect = " + width + " x " + height);
            }

            int designWidth = 1334;
            int designHeight = 750;
            float s1 = (float)designWidth / (float)designHeight;
            float s2 = (float)width / (float)height;
            if (s1 < s2)
            {
                designWidth = (int)Mathf.FloorToInt(designHeight * s2);
            }
            else if (s1 > s2)
            {
                designHeight = (int)Mathf.FloorToInt(designWidth / s2);
            }
            float contentScale = (float)designWidth / (float)width;
            if (contentScale < 1.0f)
            {
                scaleWidth = designWidth;
                scaleHeight = designHeight;
            }
        }
        if (scaleWidth > 0 && scaleHeight > 0)
        {
            if (scaleWidth % 2 == 0)
            {
                scaleWidth += 1;
            }
            else
            {
                scaleWidth -= 1;
            }
            //Screen.SetResolution(scaleWidth, scaleHeight, true);
        }
        else
        {
            scaleWidth = Screen.width;
            scaleHeight = Screen.height;
        }
        CameraMgr.CheckAndGetShowRT();

        if (App.IsDebug)
        {
            iTrace.Log("LY", "Real aspect = " + scaleWidth + " x " + scaleHeight);
            UnityEngine.Debug.LogWarning(" LY :   Real aspect = " + scaleWidth + " x " + scaleHeight);
        }

        Global.Main.StartCoroutine(YieldScreen());
        
    }

    /// <summary>
    /// 设置分辨率后再刷新有关使用Screen获取高度/宽度的功能
    /// </summary>
    /// <returns></returns>
    private static IEnumerator YieldScreen()
    {
        for (int i = 0; i < 2; i++)
        {
            yield return null;
        }
        JoyStickCtrl.instance.SetRange();
        iTrace.ResetBtn();
    }

    //// LY add begin ////
    //// 闪烁提示文字 ////
    private bool showPSMText = false;

    /// <summary>
    /// 低电量模式UI提示
    /// </summary>
    /// <param name="dTime"></param>
    private void OnPSMTextUpdate()
    {


        if (mUsePSM == false || usePowerSaveMode == false || mManualEnterPSM == true)
        {
            if (showPSMText == true)
            {
                if(HotfixCheckMgr.Instance.cspCamInitHelper != null)
                {
                    HotfixCheckMgr.Instance.cspCamInitHelper.ShowPSMText = false;
                }
                showPSMText = false;
            }
            return;
        }

        if (showPSMText == false)
        {
            if (HotfixCheckMgr.Instance.cspCamInitHelper != null)
            {
                HotfixCheckMgr.Instance.cspCamInitHelper.ShowPSMText = true;
            }
            showPSMText = true;
        }
    }

    /// <summary>
    /// 根据机型品质获取特效名字
    /// </summary>
    /// <param name="effectName">默认特效名字</param>
    /// <returns></returns>
    public string GetQuaEffName(string effectName)
    {
        if (!effectName.Contains("_low"))
            return effectName;
        string effName = effectName;
        if (TotalQuality > TotalQualityType.TQT_1)
            effName = effName.Remove(effName.Length - 4);
        return effName;
    }

    public void LocalChanged()
    {
        //TODO
    }
}
