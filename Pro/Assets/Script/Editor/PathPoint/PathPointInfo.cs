using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        31b46cce-fa5e-47e6-9782-84ed94c027e0
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/4/10 16:11:13
    /// BG:路径点信息
    /// </summary>
    [Serializable]
    public class PathPointInfo : VectorInfo
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段

        /// <summary>
        /// 到达此点需要的时间
        /// </summary>
        public float duration = 0;

        /// <summary>
        /// 到达此点后停顿时间
        /// </summary>
        public float delay = 0;
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Draw(Object obj, IList lst, int idx)
        {
            UIEditLayout.Vector3Field("当前点:", ref pos, obj);
            UIEditLayout.FloatField("到达此点需要的时间/秒:", ref duration, obj);
            UIEditLayout.FloatField("到达此点后停顿时间/秒:", ref delay, obj);

        }

        public void Read(PathInfo.PointInfo pointInfo)
        {
            PathInfo.Vector3 point1 = pointInfo.point;
            float factor = 0.01f;
            float x = point1.x * factor;
            float y = point1.y * factor;
            float z = point1.z * factor;
            pos.Set(x, y, z);

            duration = (float)pointInfo.duration;
            delay = (float)pointInfo.delay;
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            int x = (int)(pos.x * 100);
            int y = (int)(pos.y * 100);
            int z = (int)(pos.z * 100);
            sb.Append(x).Append("|");
            sb.Append(y).Append("|");
            sb.Append(z);
            sb.Append(",").Append(duration);
            sb.Append(",").Append(delay);
            return sb.ToString();
        }
        #endregion
    }
}