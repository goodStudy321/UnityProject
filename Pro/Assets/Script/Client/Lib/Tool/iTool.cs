using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System;

using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.09.23
    /// BG:通用工具方法
    /// </summary>
    public static partial class iTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion


        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 销毁对象;根据播放器状态调用适当方法
        /// </summary>
        public static void Destroy(Object obj)
        {
            if (obj == null) return;
            if (Application.isPlaying) Object.Destroy(obj);
            else Object.DestroyImmediate(obj);
        }

        /// <summary>
        /// 获得目标对象在原点对象的相对角度
        /// </summary>
        /// <param name="origin"> 原点对象 </param>
        /// <param name="target"> 目标对象 </param>
        /// <returns> 返回 target 所处位置在 origin 相对角度 </returns>
        public static float GetAngle(Transform origin, Transform target)
        {
            float angle = 0;
            float offset = origin.eulerAngles.y;
            Vector3 pos = origin.InverseTransformPoint(target.position);
            angle = Vector3.Angle(Vector3.back, pos);
            float dir = (Vector3.Dot(Vector3.up, Vector3.Cross(Vector3.back, pos)) < 0 ? 1 : -1);
            angle *= dir;
            angle -= offset + 180.0f;
            return -angle;
        }
        #endregion
    }
}