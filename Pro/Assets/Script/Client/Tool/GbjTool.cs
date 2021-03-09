using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2013.6.3
    /// BG:游戏对象工具
    /// </summary>
    public static class GbjTool
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
        /// 克隆游戏对象
        /// </summary>
        /// <param name="obj"></param>
        /// <returns></returns>
        public static GameObject Clone(Object obj)
        {
            if (obj == null) return null;
            GameObject go = GameObject.Instantiate(obj) as GameObject;
            go.name = obj.name;
            return go;
        }

        /// <summary>
        /// 克隆游戏对象并且立即销毁
        /// </summary>
        /// <param name="obj"></param>
        public static void CloneAndDestroy(Object obj)
        {
            iTrace.Log("Loong", "克隆并且销毁:" + obj.name);
            GameObject go = GameObject.Instantiate(obj) as GameObject;
            iTool.Destroy(go);
        }
        #endregion
    }
}