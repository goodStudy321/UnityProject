using UnityEngine;
using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using Object = UnityEngine.Object;
using Loong.Game;


namespace PathTool{
	
    /// <summary>
    /// 路径移动管理器
    /// </summary>
	public class PathMoveMgr 
	{
        public static readonly PathMoveMgr instance = new PathMoveMgr();

        /// <summary>
        /// 曲线数据
        /// </summary>
        private Dictionary<uint, PathMoveData> m_mapPathData = new Dictionary<uint, PathMoveData>();
        /// <summary>
        /// 移动中的曲线
        /// </summary>
        private List<MoveOnPath> mRunningPathList = new List<MoveOnPath>();


        private void Init()
        {
            //iTrace.Log("LY", "Create PathMoveMgr !!!");
        }

        //private void FillPathData(BezierPathSaveData bezierData)
        //{
        //    if (bezierData == null)
        //        return;

        //    for (int a = 0; a < bezierData.mPathDataList.Count; a++)
        //    {
        //        BezierRecord tRec = bezierData.mPathDataList[a];
        //        if(m_mapPathData.ContainsKey(tRec.mId) == true)
        //        {
        //            iTrace.Error("LY", "Path id has existed !!! " + tRec.mId);
        //            continue;
        //        }
                
        //        PathMoveData pmData = new PathMoveData(tRec.mId, tRec.mSampledPoint);
        //        m_mapPathData.Add(pmData.PathId, pmData);
        //    }
        //}

        private void FillBinaryPathData(BezierPathBinaryData bezierData)
        {
            if (bezierData == null)
                return;

            for (int a = 0; a < bezierData.mPathDataList.Count; a++)
            {
                BinaryBezierRecord tRec = bezierData.mPathDataList[a];
                if (m_mapPathData.ContainsKey(tRec.mId) == true)
                {
#if UNITY_EDITOR
                    iTrace.Error("LY", "Path id has existed !!! " + tRec.mId);
#endif
                    continue;
                }

                List<Vector3> tSPList = new List<Vector3>();
                for(int b = 0; b < tRec.mSampledPoint.Count; b++)
                {
                    tSPList.Add(tRec.mSampledPoint[b].GetVector3());
                }
                PathMoveData pmData = new PathMoveData(tRec.mId, tSPList);
                m_mapPathData.Add(pmData.PathId, pmData);
            }
        }

        public bool CheckRemoveInPathUnit(Unit actor)
        {
            for (int a = 0; a < mRunningPathList.Count; a++)
            {
                if (mRunningPathList[a].Actor == actor)
                {
                    RemoveMoveOnPath(mRunningPathList[a]);
                    return true;
                }
            }

            return false;
        }

        public bool IsUnitInPathMove(Unit actor)
        {
            for(int a = 0; a < mRunningPathList.Count; a++)
            {
                if(mRunningPathList[a].Actor == actor && mRunningPathList[a].Playing == true)
                {
                    return true;
                }
            }

            return false;
        }

        private void LoadDataCb(Object gbj)
        {
            if (gbj == null)
            {
#if UNITY_EDITOR
                iTrace.Log("LY", "Can not load BezierPathData.bytes !!! ");
#endif
                return;
            }

            //BezierPathSaveData bezierData = gbj as BezierPathSaveData;
            //FillPathData(bezierData);

            TextAsset bezierData = gbj as TextAsset;
            //MemoryStream mStream = new MemoryStream(bezierData.bytes);
            //BinaryFormatter bf = new BinaryFormatter();
            ////反序列化
            //BezierPathBinaryData loadData = (BezierPathBinaryData)bf.Deserialize(mStream);
            //mStream.Dispose();

            BezierPathBinaryData loadData = new BezierPathBinaryData();
            loadData.Read(bezierData.bytes);

            FillBinaryPathData(loadData);
        }


        public PathMoveMgr()
        {
            Init();
        }

        public void LoadData()
        {
            /// 读取bundle ///
            //string prefabName = "BezierPathData.asset";
            string prefabName = "BezierPathData.bytes";
            AssetMgr.Instance.Add(prefabName, LoadDataCb);
        }

        public void Clear()
        {
            mRunningPathList.Clear();
        }

        /// <summary>
        /// 根据Id获取曲线
        /// </summary>
        /// <param name="pathId"></param>
        public PathMoveData GetPathData(uint pathId)
        {
            if(m_mapPathData == null || m_mapPathData.ContainsKey(pathId) == false)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Can not find path move data !!! " + pathId);
#endif
                return null;
            }

            return m_mapPathData[pathId].Clone();
        }

        public void Update(float dTime)
        {
            for(int a = 0; a < mRunningPathList.Count; a++)
            {
                mRunningPathList[a].Update(dTime);
            }
        }

        /// <summary>
        /// 播放移动路径
        /// </summary>
        /// <param name="pathId"></param>
        /// <param name="moveUnit"></param>
        public bool RunPathMove(uint pathId, float playTime, bool reverse, MoveOnPath.FaceType ft,
            Unit moveUnit, AnimationCurve curve = null, Action<MoveOnPath.FinishType> finCB = null)
        {
            if(IsUnitInPathMove(moveUnit) == true)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Unit is in move !!!");
#endif
                return false;
            }

            PathMoveData pData = GetPathData(pathId);
            if(pData == null)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Can not find move path : " + pathId);
#endif
                return false;
            }

            MoveOnPathNorm tPath = new MoveOnPathNorm(pData, playTime, reverse, ft, moveUnit, curve, finCB);
            mRunningPathList.Add(tPath);
            return tPath.Play();
        }

        /// <summary>
        /// 播放指定点路径
        /// </summary>
        /// <param name="pathId"></param>
        /// <param name="reverse"></param>
        /// <param name="moveUnit"></param>
        /// <param name="finCB"></param>
        public bool RunSpecifyPath(ushort pathId, bool reverse, MoveOnPath.FaceType ft, Unit moveUnit, Action<MoveOnPath.FinishType> finCB = null)
        {
            if (IsUnitInPathMove(moveUnit) == true)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Unit is in move !!!");
#endif
                return false;
            }

            PathInfo tInfo = PathInfoManager.instance.Find(pathId);
            if (tInfo == null)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "PathMoveMgr::RunSpecifyPath  Can not find path : " + pathId);
#endif
                return false;
            }

            MoveOnPathSpecify tPath = new MoveOnPathSpecify(tInfo, reverse, ft, moveUnit, null, finCB);
            mRunningPathList.Add(tPath);

            return tPath.Play();
        }

        /// <summary>
        /// 曲线移动完成
        /// </summary>
        /// <param name="mop"></param>
        public void RemoveMoveOnPath(MoveOnPath mop)
        {
            if(mRunningPathList.Contains(mop))
            {
                mRunningPathList.Remove(mop);
                iTrace.eLog("LY", "Path move finish ! ");
            }
        }
    }
}