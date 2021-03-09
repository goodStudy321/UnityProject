using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


namespace PathTool{
	
    /// <summary>
    /// ����·���ƶ�����
    /// </summary>
	public class MoveOnPath
	{
        public enum FaceType
        {
            FT_UNKNOWN = 0,
            FT_NONE,                   /* �������� */
            FT_FORWORD,                /* �泯ǰ�� */
            FT_FORWORDXZ,              /* ֻ��xzƽ���泯ǰ�� */
            FT_MAX
        }

        /// <summary>
        /// �������
        /// </summary>
        public enum FinishType
        {
            FT_Unknown = 0,
            FT_Break,                   /* �ж� */
            FT_Suc,                     /* ��� */
            FT_Max
        }

        /// <summary>
        /// �ƶ�����
        /// </summary>
        protected Unit mActor;
        /// <summary>
        /// �ƶ�ʱ��
        /// </summary>
        protected float mMoveTime = 1f;
        /// <summary>
        /// ���泯������
        /// </summary>
        protected FaceType mFaceType = FaceType.FT_NONE;

        /// <summary>
        /// �ٶ�����
        /// </summary>
        protected AnimationCurve mSpeedCurve = null;

        /// <summary>
        /// �Ƿ��ڲ�����
        /// </summary>
        protected bool mIsPlaying = false;
        /// <summary>
        /// �Ƿ��򲥷�
        /// </summary>
        protected bool mReverse = false;
        /// <summary>
        /// ·����ɻص�
        /// </summary>
        protected Action<FinishType> mFinishCallBack = null;

        /// <summary>
        /// ��ʱ��
        /// </summary>
        protected float mTimer = 0f;


        public Unit Actor
        {
            get { return mActor; }
        }
        public bool Playing
        {
            get { return mIsPlaying; }
        }


        /// <summary>
        /// ��ʼ��
        /// </summary>
        protected virtual void Init() {}

        /// <summary>
        /// ���õ���ͷ
        /// </summary>
        protected virtual void SetToBegin() {}

        /// <summary>
        /// ���õ���β
        /// </summary>
        protected virtual void SetToEnd() {}

        /// <summary>
        /// ���õ�λ����
        /// </summary>
        /// <param name="tarPos"></param>
        protected virtual void SetUnitRot(Vector3 tarPos)
        {
            if (mFaceType == FaceType.FT_NONE)
                return;

            if (mActor == null)
                return;

            Vector3 tDir = tarPos - mActor.Position;
            if (tDir.sqrMagnitude < 0.01f)
            {
                return;
            }
            Vector3 tNorDir = tDir.normalized;

            if (mFaceType == FaceType.FT_FORWORDXZ)
            {
                float tOri = Mathf.Atan2(tNorDir.x, tNorDir.z);
                mActor.SetOrientation(tOri);
                return;
            }

            if (mFaceType == FaceType.FT_FORWORD)
            {
                mActor.UnitTrans.forward = tNorDir;
                return;
            }
        }

        /// <summary>
        /// ·���ж�
        /// </summary>
        protected virtual void PathBreak()
        {
            mIsPlaying = false;
            if(mActor != null && mActor.ActionStatus != null)
            {
                mActor.ActionStatus.ignoreGravityGlobal = false;
            }
        }

        /// <summary>
        /// ·�����
        /// </summary>
        protected virtual void PathFinish()
        {
            mIsPlaying = false;
            if (mActor != null && mActor.ActionStatus != null)
            {
                mActor.ActionStatus.ignoreGravityGlobal = false;
            }
            //mActor.mUnitMove.FollowPath = false;
            if (mFinishCallBack != null)
            {
                mFinishCallBack.Invoke(FinishType.FT_Suc);
                mFinishCallBack = null;
            }
            PathMoveMgr.instance.RemoveMoveOnPath(this);
        }


        public virtual void Update(float time)
        {
            
        }
        
        public MoveOnPath(bool reverse, FaceType ft, Unit mUnit, AnimationCurve curve = null, Action<FinishType> finCB = null)
        {
            if(mUnit == null)
            {
                iTrace.Error("LY", "Move unit is null !!!  MoveOnPath::MoveOnPath");
                return;
            }

            mReverse = reverse;
            mFaceType = ft;
            mActor = mUnit;
            mSpeedCurve = curve;
            mFinishCallBack = finCB;
        }

        public virtual bool Play()
        {
            if(mActor == null)
            {
                PathMoveMgr.instance.RemoveMoveOnPath(this);
                return false;
            }

            if (mActor.ActionStatus != null)
            {
                mActor.ActionStatus.ignoreGravityGlobal = true;
            }

            if (mIsPlaying == true)
            {
                iTrace.Log("LY", "Path is playing !!! ");
                return true;
            }

            mTimer = 0.0f;
            mIsPlaying = true;
            SetToBegin();

            return true;
        }

        /// <summary>
        /// Sample the tween at the specified factor.
        /// </summary>
        public float Sample(float factor)
        {
            if (mSpeedCurve == null)
                return factor;

            // Calculate the sampling value
            float val = Mathf.Clamp01(factor);
            return mSpeedCurve.Evaluate(val);
        }
    }


    /// <summary>
    /// ƽ���ƶ�·��
    /// </summary>
	public class MoveOnPathNorm : MoveOnPath
    {
        /// <summary>
        /// �ƶ�·��
        /// </summary>
        private PathMoveData mMoveData;

        
        /// <summary>
        /// ���õ���ͷ
        /// </summary>
        protected override void SetToBegin()
        {
            if (mActor == null)
                return;

            if (mReverse == false)
                mActor.Position = mMoveData.GetPointAt(0);
            else
                mActor.Position = mMoveData.GetPointAt(1);
        }

        /// <summary>
        /// ���õ���β
        /// </summary>
        protected override void SetToEnd()
        {
            if (mActor == null)
                return;

            if (mReverse == false)
                mActor.Position = mMoveData.GetPointAt(1);
            else
                mActor.Position = mMoveData.GetPointAt(0);
        }


        public MoveOnPathNorm(PathMoveData pathData, float playTime, bool reverse, FaceType ft,
            Unit mUnit, AnimationCurve curve = null, Action<FinishType> finCB = null) : base(reverse, ft, mUnit, curve, finCB)
        {
            if (pathData == null || mUnit == null)
            {
                iTrace.Error("LY", "Path data is null or Move unit is null !!!  MoveOnPath::MoveOnPath");
                return;
            }

            mMoveData = pathData;
            mMoveTime = playTime;

            Init();
        }

        public override void Update(float time)
        {
            if (mIsPlaying == false)
            {
                return;
            }

            if (mMoveTime <= 0)
            {
                if(mReverse == true)
                {
                    mActor.Position = mMoveData.GetPointAt(0);
                }
                else
                {
                    mActor.Position = mMoveData.GetPointAt(1);
                }

                PathFinish();
                return;
            }

            mTimer += time;
            float timeWeight = mTimer / mMoveTime;
            if (mSpeedCurve != null)
            {
                timeWeight = Sample(timeWeight);
            }

            float moveWeight = timeWeight;
            if (mReverse == true)
            {
                moveWeight = 1.0f - moveWeight;
            }

            Vector3 pointB = Vector3.zero, pointE = Vector3.zero;
            Vector3 newPos = mMoveData.GetPointAt(moveWeight, ref pointB, ref pointE);
            mActor.Position = newPos;

            if(mReverse == false)
            {
                SetUnitRot(pointE);
            }
            else
            {
                SetUnitRot(pointB);
            }

            if(mTimer >= mMoveTime)
            {
                if (mReverse == true)
                {
                    mActor.Position = mMoveData.GetPointAt(0);
                }
                else
                {
                    mActor.Position = mMoveData.GetPointAt(1);
                }

                PathFinish();
            }
        }

        //public override bool Play()
        //{
        //    if (base.Play() == false)
        //        return false;

        //    return base.Play();
        //}
    }


    /// <summary>
    /// ƽ���ƶ�·��
    /// </summary>
	public class MoveOnPathSpecify : MoveOnPath
    {
        private float mDis = 0.2f;
        /// <summary>
        /// ·������
        /// </summary>
        private PathInfo mPathInfo;
        /// <summary>
        /// ·�����б�
        /// </summary>
        private List<FigPathPotInfo> mPathPoint = new List<FigPathPotInfo>();

        /// <summary>
        /// ��һ��Ŀ�����Ϣ
        /// </summary>
        private FigPathPotInfo mNextPos;
        /// <summary>
        /// �ƶ��ٶ�
        /// </summary>
        private float mMoveSpeed = 1.0f;
        /// <summary>
        /// �ȴ�ʱ��
        /// </summary>
        private float mWaitTime = 0f;
        /// <summary>
        /// �Ƿ��ڵȴ���
        /// </summary>
        private bool mInWait = false;


        /// <summary>
        /// ��ǰ·��������
        /// </summary>
        private int mPointIndex;


        /// <summary>
        /// �����ƶ��ٶ�
        /// </summary>
        /// <param name="nextPos"></param>
        /// <param name="time"></param>
        /// <returns></returns>
        private float CalSpeed(Vector3 nextPos, float time)
        {
            return Vector3.Distance(mActor.Position, nextPos) / time;
        }
        
        private void WalkUpdate(float time)
        {
            if (Vector3.Distance(mActor.Position, mNextPos.mPoint) < mDis)
            {
                /// �������� ///
                SetUnitRot(mNextPos.mPoint);
                mActor.Position = mNextPos.mPoint;

                if(mNextPos.mDelay > 0)
                {
                    mWaitTime = mNextPos.mDelay;
                    mInWait = true;
                    mTimer = 0f;
                }
                else
                {
                    mPointIndex++;
                    ChangeIndexPos();
                }
                return;
            }

            /// �ı�λ�� ///
            mActor.Position = Vector3.MoveTowards(mActor.Position, mNextPos.mPoint, time * mMoveSpeed);
            /// �������� ///
            SetUnitRot(mNextPos.mPoint);
        }

        private void WaitUpdate(float time)
        {
            mTimer += time;
            if(mTimer >= mWaitTime)
            {
                mPointIndex++;
                ChangeIndexPos();
                mInWait = false;
            }
        }
        
        private void ChangeIndexPos()
        {
            if(mPointIndex < 0 || mPointIndex >= mPathPoint.Count)
            {
                return;
            }

            if (mReverse == false)
            {
                mNextPos = mPathPoint[mPointIndex];
            }
            else
            {
                mNextPos = mPathPoint[mPathPoint.Count - mPointIndex - 1];
            }

            if(mNextPos.mDuration > 0)
            {
                mMoveSpeed = CalSpeed(mNextPos.mPoint, mNextPos.mDuration);
            }
            else if(mNextPos.mDuration == 0)
            {
                mMoveSpeed = mActor.MoveSpeed;
            }
            else
            {
                /// �������� ///
                SetUnitRot(mNextPos.mPoint);
                mActor.Position = mNextPos.mPoint;

                if (mNextPos.mDelay > 0)
                {
                    mWaitTime = mNextPos.mDelay;
                    mInWait = true;
                    mTimer = 0f;
                }
                else
                {
                    mPointIndex++;
                    ChangeIndexPos();
                }
            }
        }


        protected override void Init()
        {
            base.Init();

            mPathPoint.Clear();
            FigPathPotInfo tFPInfo = null;
            for (int a = 0; a < mPathInfo.points.list.Count; a++)
            {
                PathInfo.PointInfo tPInfo = mPathInfo.points.list[a];
                tFPInfo = new FigPathPotInfo();
                tFPInfo.mPoint = new Vector3(tPInfo.point.x * 0.01f, tPInfo.point.y * 0.01f, tPInfo.point.z * 0.01f);
                tFPInfo.mDuration = (float)tPInfo.duration;
                tFPInfo.mDelay = (float)tPInfo.delay;

                mPathPoint.Add(tFPInfo);
            }
        }

        /// <summary>
        /// ���õ���ͷ
        /// </summary>
        protected override void SetToBegin()
        {
            
        }

        /// <summary>
        /// ���õ���β
        /// </summary>
        protected override void SetToEnd()
        {
            
        }


        public MoveOnPathSpecify(PathInfo pathInfo, bool reverse, FaceType ft,
            Unit mUnit, AnimationCurve curve = null, Action<FinishType> finCB = null) : base(reverse, ft, mUnit, curve, finCB)
        {
            mPathInfo = pathInfo;
            Init();
        }

        public override void Update(float time)
        {
            if (mIsPlaying == false)
            {
                return;
            }

            if(mPointIndex >= mPathPoint.Count)
            {
                PathFinish();
                return;
            }

            if(mInWait == false)
            {
                WalkUpdate(time);
            }
            else
            {
                WaitUpdate(time);
            }
        }
        
        public override bool Play()
        {
            if (base.Play() == false)
                return false;

            mInWait = false;
            mPointIndex = 0;
            ChangeIndexPos();

            Vector3 tLastPot, tLastButOnePot;
            if(mPathPoint.Count <= 1)
            {
                tLastPot = mPathPoint[0].mPoint;
                tLastButOnePot = mActor.Position;
            }
            else
            {
                tLastPot = mPathPoint[mPathPoint.Count - 1].mPoint;
                tLastButOnePot = mPathPoint[mPathPoint.Count - 2].mPoint;
            }
            
            NetMove.RequestChangePosDir(mActor, tLastPot);

            return true;
        }
    }
}