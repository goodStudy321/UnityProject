using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Phantom;
using Loong.Game;


public class JumpPathInfo
{
    public uint mPathId = 0;
    public float mJumpTime = 0f;
    public string mJumpAnim = "";
    public AnimationCurve mAnimCurve = null;

    public float mPreWaitTime = 0f;
    public string mPreAnim = "";
    public string mPreFx = "";
    public bool mPPHide = false;
    public bool mPAHide = false;

    public float mAftWaitTime = 0f;
    public string mAftAnim = "";
    public string mAftFx = "";
    public bool mAPHide = false;
    public bool mAAHide = false;
}

public class PortalFig : MonoBehaviour
{
    private static float mStartWaitTime = 2f;

    /// <summary>
    /// ���Ϳ�Id
    /// </summary>
    [HideInInspector][SerializeField]
    public uint mPortalId = 0;
    /// <summary>
    /// ���ӵ�ͼId
    /// </summary>
    [HideInInspector][SerializeField]
    public uint mLinkMapId = 0;
    /// <summary>
    /// ���Ӵ��Ϳ�Id
    /// </summary>
    [HideInInspector][SerializeField]
    public uint mLinkPortalId = 0;

    /// <summary>
    /// �Ƿ�ת
    /// </summary>
    [HideInInspector][SerializeField]
    public bool mReverse = false;
    /// <summary>
    /// �泯����
    /// </summary>
    [SerializeField]
    public PathTool.MoveOnPath.FaceType mFaceType = PathTool.MoveOnPath.FaceType.FT_NONE;
    /// <summary>
    /// ������ת���ɫ�ȼ�
    /// </summary>
    [HideInInspector][SerializeField]
    public uint mUnlockCharLv = 0;
    /// <summary>
    /// ��������Id
    /// </summary>
    [HideInInspector][SerializeField]
    public int mUnlockMissionId = 0;


    /// <summary>
    /// ��ת���߼���
    /// </summary>
    [HideInInspector][SerializeField]
    public List<uint> mJumpPaths = new List<uint>();
    /// <summary>
    /// ������Ծʱ�伯��
    /// </summary>
    [HideInInspector][SerializeField]
    public List<float> mJumpTimeList = new List<float>();
    /// <summary>
    /// �ٶ����߼���
    /// </summary>
    [HideInInspector][SerializeField]
    public List<AnimationCurve> mAnimCurves = new List<AnimationCurve>();

    /// <summary>
    /// ���߶�Ӧ��Ծ��������
    /// </summary>
    [HideInInspector][SerializeField]
    public List<string> mUseAnimNames = new List<string>();

    /// <summary>
    /// ǰ�õȴ�ʱ�伯��
    /// </summary>
    [HideInInspector][SerializeField]
    public List<float> mPreWaitTimeList = new List<float>();
    /// <summary>
    /// ǰ�õȴ���������
    /// </summary>
    [HideInInspector][SerializeField]
    public List<string> mPreAnimList = new List<string>();
    /// <summary>
    /// ǰ����Ч����
    /// </summary>
    [HideInInspector][SerializeField]
    public List<string> mPreFxList = new List<string>();
    /// <summary>
    /// ǰ�õȴ�ǰ���ؽ�ɫ
    /// </summary>
    [HideInInspector][SerializeField]
    public List<bool> mPPHideList = new List<bool>();
    /// <summary>
    /// ǰ�õȴ������ؽ�ɫ
    /// </summary>
    [HideInInspector][SerializeField]
    public List<bool> mPAHideList = new List<bool>();

    /// <summary>
    /// ���õȴ�ʱ�伯��
    /// </summary>
    [HideInInspector][SerializeField]
    public List<float> mAftWaitTimeList = new List<float>();
    /// <summary>
    /// ���õȴ���������
    /// </summary>
    [HideInInspector][SerializeField]
    public List<string> mAftAnimList = new List<string>();
    /// <summary>
    /// ������Ч����
    /// </summary>
    [HideInInspector][SerializeField]
    public List<string> mAftFxList = new List<string>();
    /// <summary>
    /// ���õȴ�ǰ���ؽ�ɫ
    /// </summary>
    [HideInInspector][SerializeField]
    public List<bool> mAPHideList = new List<bool>();
    /// <summary>
    /// ���õȴ������ؽ�ɫ
    /// </summary>
    [HideInInspector][SerializeField]
    public List<bool> mAAHideList = new List<bool>();

    /// <summary>
    /// �����ֶ���ת
    /// </summary>
    [SerializeField]
    public bool mLockManualJump = false;

    /// <summary>
    /// �ٶ�����
    /// </summary>
    //[HideInInspector][SerializeField]
    //public AnimationCurve animationCurve = new AnimationCurve(new Keyframe(0f, 0f, 0f, 1f), new Keyframe(1f, 1f, 1f, 0f));


    /// <summary>
    /// �Ƿ����
    /// </summary>
    private bool mUnlock = false;
    /// <summary>
    /// ���봥������Unit�б�
    /// </summary>
    private List<Unit> mEnterUnits = null;

    private bool mFinInitWait = false;
    private float mTimer = 0f;


    public bool UnLock
    {
        get
        {
            return mUnlock;
        }
    }


    public void InitData(BinaryPortalFig bPortalFig)
    {
        mPortalId = bPortalFig.mPortalId;
        mLinkMapId = bPortalFig.mLinkMapId;
        mLinkPortalId = bPortalFig.mLinkPortalId;
        mReverse = bPortalFig.mReverse;
        mFaceType = (PathTool.MoveOnPath.FaceType)bPortalFig.mFaceType;
        mUnlockCharLv = bPortalFig.mUnlockCharLv;
        mUnlockMissionId = bPortalFig.mUnlockMissionId;
        mJumpPaths = new List<uint>(bPortalFig.mJumpPaths);
        mJumpTimeList = new List<float>(bPortalFig.mJumpTimeList);
        
        mAnimCurves.Clear();
        for (int a = 0; a < bPortalFig.mAnimCurves.Count; a++)
        {
            AnimationCurve tCurve = new AnimationCurve();
            SAnimationCurve tSCurve = bPortalFig.mAnimCurves[a];
            for (int b = 0; b < tSCurve.curveKey.Count; b++)
            {
                SVector4 tCK = tSCurve.curveKey[b];
                Keyframe tKF = new Keyframe(tCK.x, tCK.y, tCK.z, tCK.w);
                tCurve.AddKey(tKF);
            }
            mAnimCurves.Add(tCurve);
        }
        mUseAnimNames = new List<string>(bPortalFig.mUseAnimNames);

        mPreWaitTimeList = new List<float>(bPortalFig.mPreWaitTimeList);
        mPreAnimList = new List<string>(bPortalFig.mPreAnimList);
        mPreFxList = new List<string>(bPortalFig.mPreFxList);
        mPPHideList = new List<bool>(bPortalFig.mPPHideList);
        mPAHideList = new List<bool>(bPortalFig.mPAHideList);

        mAftWaitTimeList = new List<float>(bPortalFig.mAftWaitTimeList);
        mAftAnimList = new List<string>(bPortalFig.mAftAnimList);
        mAftFxList = new List<string>(bPortalFig.mAftFxList);
        mAPHideList = new List<bool>(bPortalFig.mAPHideList);
        mAAHideList = new List<bool>(bPortalFig.mAAHideList);

        if (mPreWaitTimeList.Count < mAnimCurves.Count)
        {
            for(int a = mPreWaitTimeList.Count; a < mAnimCurves.Count; a++)
            {
                mPreWaitTimeList.Add(0);
            }
        }
        if (mPreAnimList.Count < mAnimCurves.Count)
        {
            for (int a = mPreAnimList.Count; a < mAnimCurves.Count; a++)
            {
                mPreAnimList.Add("");
            }
        }
        if (mPreFxList.Count < mAnimCurves.Count)
        {
            for (int a = mPreFxList.Count; a < mAnimCurves.Count; a++)
            {
                mPreFxList.Add("");
            }
        }
        if (mPPHideList.Count < mAnimCurves.Count)
        {
            for (int a = mPPHideList.Count; a < mAnimCurves.Count; a++)
            {
                mPPHideList.Add(false);
            }
        }
        if (mPAHideList.Count < mAnimCurves.Count)
        {
            for (int a = mPAHideList.Count; a < mAnimCurves.Count; a++)
            {
                mPAHideList.Add(false);
            }
        }

        if (mAftWaitTimeList.Count < mAnimCurves.Count)
        {
            for (int a = mAftWaitTimeList.Count; a < mAnimCurves.Count; a++)
            {
                mAftWaitTimeList.Add(0);
            }
        }
        if (mAftAnimList.Count < mAnimCurves.Count)
        {
            for (int a = mAftAnimList.Count; a < mAnimCurves.Count; a++)
            {
                mAftAnimList.Add("");
            }
        }
        if (mAftFxList.Count < mAnimCurves.Count)
        {
            for (int a = mAftFxList.Count; a < mAnimCurves.Count; a++)
            {
                mAftFxList.Add("");
            }
        }
        if (mAPHideList.Count < mAnimCurves.Count)
        {
            for (int a = mAPHideList.Count; a < mAnimCurves.Count; a++)
            {
                mAPHideList.Add(false);
            }
        }
        if (mAAHideList.Count < mAnimCurves.Count)
        {
            for (int a = mAAHideList.Count; a < mAnimCurves.Count; a++)
            {
                mAAHideList.Add(false);
            }
        }

        mLockManualJump = bPortalFig.mLockManualJump;
    }

    /// <summary>
    /// ���һ����Ծ����
    /// </summary>
    public void AddOneJumpPath()
    {
        mJumpPaths.Add(0);
        mJumpTimeList.Add(0.5f);
        mAnimCurves.Add(new AnimationCurve(new Keyframe(0f, 0f, 0f, 1f), new Keyframe(1f, 1f, 1f, 0f)));
        mUseAnimNames.Add("");

        mPreWaitTimeList.Add(0);
        mPreAnimList.Add("");
        mPreFxList.Add("");
        mAftWaitTimeList.Add(0);
        mAftAnimList.Add("");
        mAftFxList.Add("");
    }

    /// <summary>
    /// ɾ������
    /// </summary>
    /// <param name="index"></param>
    public void RemoveJumpPath(int index)
    {
        if(index < 0 || mJumpPaths.Count <= 0 || index >= mJumpPaths.Count)
        {
            return;
        }

        mJumpPaths.RemoveAt(index);
        mJumpTimeList.RemoveAt(index);
        mAnimCurves.RemoveAt(index);
    }

    /// <summary>
    /// �������������Ծ·����Ϣ
    /// </summary>
    /// <param name="index"></param>
    /// <returns></returns>
    public JumpPathInfo GetJumpPath(int index)
    {
        if (index < 0 || index >= mJumpPaths.Count)
        {
            return null;
        }

        JumpPathInfo retInfo = new JumpPathInfo();
        retInfo.mPathId = mJumpPaths[index];
        retInfo.mJumpTime = mJumpTimeList[index];
        retInfo.mAnimCurve = mAnimCurves[index];

        return retInfo;
    }

    /// <summary>
    /// ��ȡ���е���Ծ·����Ϣ
    /// </summary>
    /// <returns></returns>
    public List<JumpPathInfo> GetAllJumpPathsInfo()
    {
        if (mJumpPaths.Count <= 0)
        {
            return null;
        }

        List<JumpPathInfo> retInfoList = new List<JumpPathInfo>();
        for (int a = 0; a < mJumpPaths.Count; a++)
        {
            JumpPathInfo tInfo = new JumpPathInfo();
            tInfo.mPathId = mJumpPaths[a];
            tInfo.mJumpTime = mJumpTimeList[a];
            tInfo.mJumpAnim = mUseAnimNames[a];
            tInfo.mAnimCurve = mAnimCurves[a];

            tInfo.mPreWaitTime = mPreWaitTimeList[a];
            tInfo.mPreAnim = mPreAnimList[a];
            tInfo.mPreFx = mPreFxList[a];
            tInfo.mPPHide = mPPHideList[a];
            tInfo.mPAHide = mPAHideList[a];

            tInfo.mAftWaitTime = mAftWaitTimeList[a];
            tInfo.mAftAnim = mAftAnimList[a];
            tInfo.mAftFx = mAftFxList[a];
            tInfo.mAPHide = mAPHideList[a];
            tInfo.mAAHide = mAAHideList[a];

            retInfoList.Add(tInfo);
        }

        return retInfoList;
    }


    private void Awake()
    {
        EventMgr.Add("OnChangeExp", OpenPortalListener);
        EventMgr.Add("OnUpdateMission", OpenPortalListener);

        if(mUseAnimNames.Count <= 0 && mJumpPaths.Count > 0)
        {
            for(int a = 0; a < mJumpPaths.Count; a++)
            {
                mUseAnimNames.Add("");
            }
        }

        mFinInitWait = false;
        mTimer = 0f;
    }

    private void Start()
    {
        mEnterUnits = new List<Unit>();
        if(CheckPortalCanOpen() == false)
        {
            gameObject.SetActive(false);
            mUnlock = false;
        }
    }

    private void Update()
    {
        if(mFinInitWait == false)
        {
            mTimer += Time.deltaTime;
            if(mTimer >= mStartWaitTime)
            {
                mFinInitWait = true;
            }
        }
    }

    private void OnDestroy()
    {
        EventMgr.Remove("OnChangeExp", OpenPortalListener);
        EventMgr.Remove("OnUpdateMission", OpenPortalListener);
    }

    void OnTriggerEnter(Collider other)
    {

        //iTrace.eLog("LY", "OnTriggerEnter : " + other.gameObject.name);

        if (mFinInitWait == false)
            return;

        if (InputMgr.instance.mOwner == null)
            return;

        if (other.transform != InputMgr.instance.mOwner.UnitTrans)
        {
            return;
        }


        if (mEnterUnits.Contains(InputMgr.instance.mOwner))
        {
            return;
        }
        mEnterUnits.Add(InputMgr.instance.mOwner);

        if (InputMgr.instance.mOwner.mNetUnitMove.NoCurveMove)
        {
            InputMgr.instance.mOwner.mNetUnitMove.NoCurveMove = false;
            return;
        }

        if (InputVectorMove.instance.MoveUnit.mUnitMove.InPathFinding == true)
        {
            return;
        }

        //if(InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.ToPortalId > 0
        //    || InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.PortalChangeScene == true)
        //{
        //    InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.PortalChangeScene = false;
        //    return;
        //}
        if (mLockManualJump == true)
            return;

        /// ��ת��ͼ ///
        if (mLinkMapId != MapPathMgr.instance.CurMapId)
        {
            if (SceneInfoManager.instance.Find(mLinkMapId) == null)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Scene id errror !!! " + mLinkMapId);
#endif
                return;
            }

            InputMgr.instance.CanInput = false;
            InputVectorMove.instance.MoveUnit.ActionStatus.ChangeIdleAction();


            //InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.ToSceneId = (int)mLinkMapId;
            //InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.ToPortalId = mLinkPortalId;

            //NetworkMgr.ReqPreEnter((int)mLinkMapId);

            InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.FindPathAndMove(
                mLinkMapId, mPortalId, mLinkPortalId, false, 0.5f, 1f, (Unit unit, AsPathfinding.PathResultType type)=> {
                    InputMgr.instance.CanInput = true;
                });
        }
        /// ��ת���Ϳ� ///
        else
        {
            if(mLinkPortalId <= 0)
            {
                return;
            }

            PortalFig toPF = MapPathMgr.instance.MapAssis.GetPortalFigById(mLinkPortalId);
            if (toPF == null)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Jump to portal miss !!! " + mLinkPortalId);
#endif
                return;
            }

            InputMgr.instance.CanInput = false;

            if(GameSceneManager.instance.EnablePrealodArea())
            {
                uint resId = MapPathMgr.instance.GetResIdByPos(toPF.transform.position);
                if (resId > 0)
                {
                    PreloadAreaMgr.Instance.Start(resId, FinishPreload);
                }
                else
                {
                    FinishPreload();
                }
            }
            else
            {
                FinishPreload();
            }
        }
    }

    void OnTriggerExit(Collider other)
    {
        if (InputMgr.instance.mOwner == null || InputMgr.instance.mOwner.UnitTrans == null)
            return;

        // ��ɫ������
        if(other.transform == InputMgr.instance.mOwner.UnitTrans)
        {
            if (mEnterUnits.Contains(InputMgr.instance.mOwner))
            {
                mEnterUnits.Remove(InputMgr.instance.mOwner);
            }
        }
    }

    private void FinishPreload()
    {
        InputMgr.instance.CanInput = false;
        Unit unit = InputMgr.instance.mOwner;
        long point = NetMove.GetPointInfo(unit.Position, unit.UnitTrans.localEulerAngles.y);
        //NetMove.RequestStopMove(point);

        unit = InputVectorMove.instance.MoveUnit;
        //unit.mNetUnitMove.RequestJump(unit, NetUnitMove.JumpType.JT_CtrlCall, toPF.transform.position, mPortalId, 0);
        unit.mUnitMove.Pathfinding.FindPathAndMove(mPortalId, mLinkPortalId, point, (Unit jumpUnit, AsPathfinding.PathResultType type) =>
        {
            InputMgr.instance.CanInput = true;
        });
    }

    /// <summary>
    /// ���ǵȼ��仯������
    /// </summary>
    private void OpenPortalListener(params object[] args)
    {
        if (mUnlock == true)
            return;
        
        if(CheckPortalCanOpen() == true)
        {
            gameObject.SetActive(true);
            mUnlock = true;
        }
    }

    /// <summary>
    /// ��⴫�Ϳڿ���
    /// </summary>
    /// <param name="charLv"></param>
    private bool CheckPortalCanOpen()
    {
        return CheckCharLvOpen() && CheckMissionIdOpen();
    }

    /// <summary>
    /// ����ɫ�ȼ��Ƿ��㹻����
    /// </summary>
    /// <returns></returns>
    private bool CheckCharLvOpen()
    {
        if (mUnlockCharLv <= 0)
            return true;

        int tCharLv = User.instance.MapData.Level;
        if (tCharLv >= mUnlockCharLv)
        {
            return true;
        }

        return false;
    }

    private bool CheckMissionIdOpen()
    {
        if (mUnlockMissionId <= 0)
            return true;
        int tMissionId = User.instance.MainMissionId;
        if (tMissionId >= mUnlockMissionId)
        {
            return true;
        }

        //         int tMissionId = User.instance.MainMission.MissionID;
        //         if(tMissionId >= mUnlockMissionId)
        //         {
        //             return true;
        //         }

        return false;
    }
}
