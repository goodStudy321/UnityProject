/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/8/15 00:00:00
 ============================================================================*/

using UnityEngine;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 三维向量信息
    /// </summary>
    [System.Serializable]
    public class VectorInfo
#if UNITY_EDITOR
        : IDrawScene, ISimple
#endif
    {
        #region 字段
        public Vector3 pos = Vector3.zero;
        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
#if UNITY_EDITOR
        /// <summary>
        /// 简单描述
        /// </summary>
        /// <returns></returns>
        public virtual string Simple()
        {
            return "";
        }

        /// <summary>
        /// 当位置发生改变
        /// </summary>
        /// <param name="obj"></param>
        public virtual void OnPosChanged()
        {

        }

        /// <summary>
        /// 场景试图内绘制
        /// </summary>
        /// <param name="obj"></param>
        public virtual void OnSceneGUI(Object obj)
        {

        }

        public virtual void OnSceneSelect(Object obj)
        {

        }

        /// <summary>
        /// 在场景中右键菜单
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="obj">游戏对象</param>
        /// <param name="lst">列表</param>
        /// <param name="index">索引</param>
        public virtual void OnSceneContext<T>(Object obj, List<T> lst, int index) where T : VectorInfo
        {
            UIEditTip.Error("请重写右键菜单");
        }

#endif
        #endregion
    }
}