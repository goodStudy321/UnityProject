using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.8.2
    /// BG:碰撞工具
    /// </summary>
    public static class ColliderTool
    {
        #region 字段

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

        /// <summary>
        /// 设置物体上碰撞的激活状态
        /// </summary>
        /// <param name="target"></param>
        /// <param name="active"></param>
        public static void SetActive(Transform target, bool active)
        {
            if (target == null) return;
            Collider col = target.GetComponent<Collider>();
            if (col != null) col.enabled = active;
        }

        /// <summary>
        /// 设置物体包括所有子物体的激活状态
        /// </summary>
        /// <param name="target"></param>
        /// <param name="active"></param>
        public static void SetChildrenActive(Transform target, bool active)
        {
            if (target == null) return;
            Collider[] cols = target.GetComponentsInChildren<Collider>();
            if (cols == null) return;
            int length = cols.Length;
            for (int i = 0; i < length; i++)
            {
                cols[i].enabled = active;
            }
        }
        #endregion
    }
}