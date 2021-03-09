using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


namespace PathTool{

    /// <summary>
    /// 路径移动数据（运行时使用）
    /// </summary>
	public class PathMoveData
    {
        /// <summary>
        /// 曲线Id
        /// </summary>
        public uint mId = 0;
        /// <summary>
        /// 路径点
        /// </summary>
        private List<Vector3> mPathPoints;
        /// <summary>
        /// 路径长度
        /// </summary>
        private float mLength = 0f;


        public uint PathId
        {
            get { return mId; }
        }


        private PathMoveData(uint pathId, List<Vector3> pathPoints, float len)
        {
            mId = pathId;
            mPathPoints = pathPoints;
            mLength = len;
        }

        /// <summary>
        /// 计算路径长度
        /// </summary>
        private void ComputeLength()
        {
            if (mPathPoints == null || mPathPoints.Count <= 0)
            {
                mLength = 0f;
                return;
            }

            float dist = 0f;
            for (int i = 0; i < mPathPoints.Count; i++)
            {
                dist += Vector3.Distance(mPathPoints[i], mPathPoints[i == mPathPoints.Count - 1 ? i : i + 1]);
            }
            mLength = dist;
        }


        public PathMoveData(uint pathId, List<Vector3> pathPoints)
        {
            mId = pathId;
            mPathPoints = pathPoints;
            ComputeLength();
        }

        public PathMoveData Clone()
        {
            PathMoveData retData = new PathMoveData(mId, mPathPoints, mLength);
            return retData;
        }

        /// <summary>
        /// 根据权重获取位置
        /// </summary>
        /// <param name="weight"></param>
        /// <returns></returns>
		public Vector3 GetPointAt(float weight)
        {
            if (weight <= 0)
            {
                return mPathPoints[0];
            }
            if (weight >= 1)
            {
                return mPathPoints[mPathPoints.Count - 1];
            }

            Vector3 a = Vector3.zero;
            Vector3 b = Vector3.zero;
            float total = 0f;
            float segmentDistance = 0f;
            for (int i = 0; i < mPathPoints.Count - 1; i++)
            {
                segmentDistance = Vector3.Distance(mPathPoints[i], mPathPoints[i + 1]) / mLength;
                if (total + segmentDistance > weight)
                {
                    a = mPathPoints[i];
                    b = mPathPoints[i + 1];
                    break;
                }
                else
                {
                    total += segmentDistance;
                }
            }
            if (segmentDistance <= 0)
            {
                return a;
            }
            weight -= total;
            return Vector3.Lerp(a, b, weight / segmentDistance);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="weight"></param>
        /// <param name="point1"></param>
        /// <param name="point2"></param>
        /// <returns></returns>
        public Vector3 GetPointAt(float weight, ref Vector3 point1, ref Vector3 point2)
        {
            if (weight <= 0)
            {
                point1 = point2 = mPathPoints[0];
                return mPathPoints[0];
            }
            if (weight >= 1)
            {
                point1 = point2 = mPathPoints[mPathPoints.Count - 1];
                return mPathPoints[mPathPoints.Count - 1];
            }

            Vector3 a = Vector3.zero;
            Vector3 b = Vector3.zero;
            float total = 0f;
            float segmentDistance = 0f;
            for (int i = 0; i < mPathPoints.Count - 1; i++)
            {
                segmentDistance = Vector3.Distance(mPathPoints[i], mPathPoints[i + 1]) / mLength;
                if (total + segmentDistance > weight)
                {
                    a = mPathPoints[i];
                    b = mPathPoints[i + 1];
                    break;
                }
                else
                {
                    total += segmentDistance;
                }
            }
            if (segmentDistance <= 0)
            {
                point1 = point2 = a;
                return a;
            }
            weight -= total;
            point1 = a;
            point2 = b;
            return Vector3.Lerp(a, b, weight / segmentDistance);
        }
    }
}