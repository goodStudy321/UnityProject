using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


public class AsPathfinding
{
    /// <summary>
    /// Ѱ·����
    /// </summary>
    public enum PathFindingType
    {
        PFT_UnKnown = 0,
        PFT_Normal,                 /* ����Ѱ· */
        PFT_Sample,                 /* ��Ѱ· */
        PFT_FlyShoes,               /* С��Ь */
        PFT_ChangeScene,            /* ������ת */
        PFT_Jump,                   /* ��Ծ */
        PFT_FollowPath,             /* ��·���ƶ� */
        PFT_Max
    }

    /// <summary>
    /// Ѱ·�������
    /// </summary>
    public enum PathResultType
    {
        PRT_UNKNOWN = 0,

        //PRT_NOPATH,                     /* û��·�� */

        PRT_FORBIDEN,                   /* ��ֹ */
        PRT_PATH_SUC,                   /* Ѱ·�ɹ� */
        PRT_CALL_BREAK,                 /* ���������ж� */
        PRT_PASSIVEBREAK,               /* ���������ж� */
        PRT_ERROR_BREAK,                /* ���������ж� */
        
        //PRT_SHOES_SUC,                  /* С��Ь�ɹ� */
        //PRT_CHANGE_SCENE_BREAK,         /* ת�������ж� */
        //PRT_RESTART_BREAK,              /* �ٴε����ж� */
        //PRT_SHOES_BREAK,                /* ��Ь�ж� */
        
        PRT_MAX
    }

    /// <summary>
    /// �ı��ƶ��ٶ�
    /// </summary>
    public float MoveSpeed
    {
        set
        {
            if(mPFReq != null)
            {
                mPFReq.walkSpd = value;
            }

            if (mAsPFMachine != null)
            {
                mAsPFMachine.MoveSpeed = value;
            }
        }
    }

    
    /// <summary>
    /// Ѱ·��λ
    /// </summary>
    private Unit mUnit;
    /// <summary>
    /// �Ƿ���Ѱ·״̬��
    /// </summary>
    //private bool mIsRunning = false;
    ///// <summary>
    ///// ����·��ʹ��Ĭ���ٶ�
    ///// </summary>
    //private bool mFLUseDefSpd = false;
    

    /// <summary>
    /// �ȴ�Ѱ·�ṹ
    /// </summary>
    private ReqPathFinding mPFReq = null;
    /// <summary>
    /// Ѱ·״̬��
    /// </summary>
    private AsPFBase mAsPFMachine = null;
    /// <summary>
    /// ��ҪֹͣѰ·
    /// </summary>
    private bool mNeedStopPF = false;
    private bool mStopAnim = false;

    
    //private float mChangeSceneTimer = 0f;

    /// <summary>
    /// Ѱ·��ɻص�
    /// </summary>
    //private Action<Unit,PathResultType> mPathFinishCB = null;
    /// <summary>
    /// �Ƿ����·��
    /// </summary>
    //private bool mFollowPath = false;

    private readonly bool mNeedStopAnim = true;

    /// <summary>
    /// ��ͨ����
    /// </summary>
    public Unit Vehicle
    {
        get { return mUnit; }
        set
        {
            mUnit = value;
            if(mAsPFMachine != null)
            {
                mAsPFMachine.Vehicle = mUnit;
            }
        }
    }

    
    public bool InJumping
    {
        get
        {
            if (mAsPFMachine == null)
                return false;

            return mAsPFMachine.GetCurActionState() == PFActionBase.ActionState.FS_JUMP;
        }
    }
    public bool NeedStopAnim
    {
        get
        {
            return mNeedStopAnim;
        }
    }

    /// <summary>
    /// ��������״̬
    /// </summary>
    /// <param name="prt"></param>
    public void ResetAllState(PathResultType prt)
    {
        EventMgr.Trigger("BreakChangeScene");

        if (mAsPFMachine != null)
        {
            mAsPFMachine.Break(prt);
        }
        if (mPFReq != null)
        {
            if(mPFReq.finCB != null)
            {
                mPFReq.finCB(mUnit, prt);
            }
        }

        //StopWalkAnim();
        User.instance.MissionState = false;
    }

    public AsPathfinding(Unit unit, bool needStopAnim = true)
    {
        mUnit = unit;
        mNeedStopAnim = needStopAnim;
    }

    /// <summary>
    /// ϸ�ڰ�Ѱ·����
    /// </summary>
    /// <param name="pfType"></param>
    /// <param name="mapId"></param>
    /// <param name="startPosition"></param>
    /// <param name="endPosition"></param>
    /// <param name="mSpd"></param>
    /// <param name="stopDis"></param>
    /// <param name="finCB"></param>
    public void FindPathAndMoveDetail(uint mapId, Vector3 startPosition, Vector3 endPosition,
        float mSpd = -1.0f, float stopDis = -1, Action<Unit, PathResultType> finCB = null)
    {
        ReqPathFinding tPFReq = new ReqPathFinding
        {
            mPFType = PathFindingType.PFT_Normal,
            mapId = mapId,
            startPos = startPosition,
            endPos = endPosition,
            walkSpd = mSpd,
            stopDis = stopDis,
            finCB = finCB
        };

        FindPathAndMove(tPFReq);
    }

    /// <summary>
    /// Ѱ·����
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="startPosition"></param>
    /// <param name="endPosition"></param>
    /// <param name="mSpd"></param>
    /// <param name="finCB"></param>
    public void FindPathAndMove(PathFindingType pfType, uint mapId, Vector3 startPosition, Vector3 endPosition, 
        float mSpd = -1.0f, float stopDis = -1, Action<Unit,PathResultType> finCB = null)
    {
        ReqPathFinding tPFReq = new ReqPathFinding
        {
            mPFType = pfType,
            mapId = mapId,
            startPos = startPosition,
            endPos = endPosition,
            walkSpd = mSpd,
            stopDis = stopDis,
            finCB = finCB
        };

        FindPathAndMove(tPFReq);
    }

    /// <summary>
    /// Ѱ·����Ծʹ��
    /// </summary>
    /// <param name="pfType"></param>
    /// <param name="fromPF"></param>
    /// <param name="toPF"></param>
    /// <param name="finCB"></param>
    public void FindPathAndMove(uint fromPF, uint toPF, long jumpDes, Action<Unit, PathResultType> finCB = null)
    {
        ReqPathFinding tPFReq = new ReqPathFinding
        {
            mPFType = PathFindingType.PFT_Jump,
            jumpDes = jumpDes,
            fromPortalId = fromPF,
            toPortalId = toPF,
            finCB = finCB
        };

        FindPathAndMove(tPFReq);
    }

    /// <summary>
    /// Ѱ·��ת������ʹ��
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="toPorId"></param>
    /// <param name="showTip"></param>
    /// <param name="pTime"></param>
    /// <param name="afTime"></param>
    /// <param name="finCB"></param>
    public void FindPathAndMove(uint mapId, uint fromId, uint toPorId, bool showTip, float pTime = 0f, float afTime = 0f, Action<Unit, PathResultType> finCB = null)
    {
        ReqPathFinding tPFReq = new ReqPathFinding
        {
            mPFType = PathFindingType.PFT_ChangeScene,
            mapId = mapId,
            fromPortalId = fromId,
            toPortalId = toPorId,
            showCSTip = showTip,
            preTime = pTime,
            afterTime = afTime,
            finCB = finCB
        };

        FindPathAndMove(tPFReq);
    }

    /// <summary>
    /// Ѱ·��С��Ьʹ��
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="toPorId"></param>
    /// <param name="showTip"></param>
    /// <param name="pTime"></param>
    /// <param name="afTime"></param>
    /// <param name="finCB"></param>
    public void FindPathFlyShoes(int sceneId, Vector3 desPos, float dis, bool showTip, float pTime = 0f, float afTime = 0f, Action<Unit, PathResultType> finCB = null)
    {
        ReqPathFinding tPFReq = new ReqPathFinding
        {
            mPFType = PathFindingType.PFT_FlyShoes,
            mapId = (uint)sceneId,
            endPos = desPos,
            walkSpd = -1f,
            stopDis = dis,
            showCSTip = showTip,
            preTime = pTime,
            afterTime = afTime,
            finCB = finCB
        };

        FindPathAndMove(tPFReq);
    }

    /// <summary>
    /// Ѱ·����
    /// </summary>
    /// <param name="pfReq"></param>
    public void FindPathAndMove(ReqPathFinding pfReq)
    {
        if (pfReq == null)
        {
            iTrace.Error("LY", "Path finding request struct is null !!! ");
            return;
        }

        if(mPFReq != null)
        {
            if (mPFReq.finCB != null)
            {
                mPFReq.finCB(mUnit, PathResultType.PRT_CALL_BREAK);
            }
            mPFReq = null;
        }

        mPFReq = pfReq;
        //CheckPathFindingState();
    }

    /// <summary>
    /// ����·������
    /// </summary>
    /// <param name=""></param>
    /// <param name="finCB"></param>
    public void FallowPath(Vector3 startPosition, List<FigPathPotInfo> pathList, bool useDefSpd = false, float mSpd = 1.0f, Action<Unit, PathResultType> finCB = null)
    {
        ReqPathFinding tPFReq = new ReqPathFinding
        {
            mPFType = PathFindingType.PFT_FollowPath,
            mapId = 0,
            startPos = startPosition,
            endPos = Vector3.zero,
            walkSpd = mSpd,
            stopDis = 0,
            finCB = finCB,

            flUseDefSpd = useDefSpd,
            pathInfo = pathList
        };

        FindPathAndMove(tPFReq);
        //InsertFindFallowPath(startPosition, pathList);
    }

    public bool PathFinish()
    {
        if(mAsPFMachine == null && mPFReq == null)
        {
            return true;
        }

        return false;
    }

    
    public bool InPathFinding()
    {
        if(mAsPFMachine != null || mPFReq != null)
        {
            return true;
        }

        return false;
    }

    public void ClearCurAsPFMachine()
    {
        if(mAsPFMachine != null)
        {
            mAsPFMachine.Clear();
            ObjPool.Instance.Add(mAsPFMachine);
        }
        mAsPFMachine = null;
    }

    /// <summary>
    /// ���ݻ��洴��Ѱ·״̬
    /// </summary>
    public AsPFBase CreatePFMachine()
    {
        if(mPFReq == null)
        {
            return null;
        }

        AsPFBase retMac = null;

        switch (mPFReq.mPFType)
        {
            case PathFindingType.PFT_Normal:
                {
                    //retMac = new AsPFNormal(mUnit, mPFReq, OverPathFinding);
                    AsPFNormal asPFNormal = ObjPool.Instance.Get<AsPFNormal>();
                    asPFNormal.SetInitVal(mUnit, mPFReq, OverPathFinding);
                    retMac = asPFNormal;

                }
                break;
            case PathFindingType.PFT_Sample:
                {
                    //retMac = new AsPFSample(mUnit, mPFReq, OverPathFinding);
                    AsPFSample asPFSample = ObjPool.Instance.Get<AsPFSample>();
                    asPFSample.SetInitVal(mUnit, mPFReq, OverPathFinding);
                    retMac = asPFSample;
                }
                break;
            case PathFindingType.PFT_FlyShoes:
                {
                    //retMac = new AsPFFlyShoes(mUnit, mPFReq, OverPathFinding);
                    AsPFFlyShoes asPFFlyShoes = ObjPool.Instance.Get<AsPFFlyShoes>();
                    asPFFlyShoes.SetInitVal(mUnit, mPFReq, OverPathFinding);
                    retMac = asPFFlyShoes;
                }
                break;
            case PathFindingType.PFT_ChangeScene:
                {
                    //retMac = new AsPFChangeScene(mUnit, mPFReq, OverPathFinding);
                    AsPFChangeScene asPFChangeScene = ObjPool.Instance.Get<AsPFChangeScene>();
                    asPFChangeScene.SetInitVal(mUnit, mPFReq, OverPathFinding);
                    retMac = asPFChangeScene;
                }
                break;
            case PathFindingType.PFT_Jump:
                {
                    //retMac = new AsPFJump(mUnit, mPFReq, OverPathFinding);
                    AsPFJump asPFJump = ObjPool.Instance.Get<AsPFJump>();
                    asPFJump.SetInitVal(mUnit, mPFReq, OverPathFinding);
                    retMac = asPFJump;
                }
                break;
            case PathFindingType.PFT_FollowPath:
                {
                    //retMac = new AsPFFollowPath(mUnit, mPFReq, OverPathFinding);
                    AsPFFollowPath asPFFollowPath = ObjPool.Instance.Get<AsPFFollowPath>();
                    asPFFollowPath.SetInitVal(mUnit, mPFReq, OverPathFinding);
                    retMac = asPFFollowPath;
                }
                break;
            default:
                break;
        }

        mPFReq = null;
        //if (retMac != null)
        //{
        //    retMac.Start();
        //}
        return retMac;
    }

    /// <summary>
    /// ���Ѱ·״̬���Ƿ���Ҫ��ϡ�����
    /// </summary>
    /// <returns></returns>
    public void CheckPathFindingState()
    {
        if(mNeedStopPF == true)
        {
            StopPathFinding(mStopAnim);
            mNeedStopPF = false;
            mStopAnim = false;
        }

        if (mPFReq != null)
        {
            if(mAsPFMachine != null)
            {
                if(mAsPFMachine.CanBreakState() == true)
                {
                    mAsPFMachine.Break(PathResultType.PRT_CALL_BREAK);
                    ClearCurAsPFMachine();
                    mAsPFMachine = CreatePFMachine();
                    if(mAsPFMachine != null)
                    {
                        mAsPFMachine.Start();
                    }
                }
            }
            else
            {
                ClearCurAsPFMachine();
                mAsPFMachine = CreatePFMachine();
                if (mAsPFMachine != null)
                {
                    CameraMgr.ClearPullCam();
                    mAsPFMachine.Start();
                }
            }
        }
    }

    /// <summary>
    /// Ѱ·״̬������
    /// </summary>
    public void OverPathFinding()
    {
        //mAsPFMachine = null;
        ClearCurAsPFMachine();
    }
    
    /// <summary>
    /// �ƶ�
    /// </summary>
    public void Move()
    {
        CheckPathFindingState();
        if(mAsPFMachine != null)
        {
            float tDTime = Time.deltaTime;
            mAsPFMachine.Update(tDTime);
        }
    }

    /// <summary>
    /// ֹͣѰ·
    /// </summary>
    public void StopPathFinding(bool bStopAnim)
    {
#if UNITY_EDITOR
        Debug.Log("---------------------       AsPathfinding stop !!!");
#endif

        if (mAsPFMachine != null)
        {
            if(mAsPFMachine.CanBreakState() == true)
            {
                mAsPFMachine.Break(PathResultType.PRT_CALL_BREAK);
            }
            else
            {
                mNeedStopPF = true;
                mStopAnim = bStopAnim;
            }
        }

        if(mPFReq != null)
        {
            if(mPFReq.finCB != null)
            {
                mPFReq.finCB(mUnit, PathResultType.PRT_CALL_BREAK);
            }
            mPFReq = null;
        }
    }

    /// <summary>
    /// ǿ���ж�Ѱ·״̬
    /// </summary>
    /// <param name="bStopAnim"></param>
    public void ForceStopPathFinding(bool bStopAnim)
    {
        if (mAsPFMachine != null)
        {
            mAsPFMachine.Break(PathResultType.PRT_CALL_BREAK);
        }

        if (mPFReq != null)
        {
            if (mPFReq.finCB != null)
            {
                mPFReq.finCB(mUnit, PathResultType.PRT_CALL_BREAK);
            }
            mPFReq = null;
        }
    }
}
	
