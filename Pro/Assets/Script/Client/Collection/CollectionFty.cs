using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        51bad880-b11d-47c8-ae25-0932368ce90e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/12 15:07:37
    /// BG:采集物创建工厂
    /// </summary>
    public static class CollectionFty
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
        /// 创建采集
        /// </summary>
        /// <param name="info">配置信息</param>
        /// <param name="go"></param>
        /// <param name="uid"></param>
        /// <returns></returns>
        public static CollectionBase Create(CollectionInfo info, GameObject go, long uid = 0)
        {
            if (info == null)
            {
                iTrace.Error("Loong", "创建采集物类型时,配置信息为空");
                return null;
            }
            if (go == null)
            {
                iTrace.Error("Loong", "创建采集物时,游戏对象为空");
                return null;
            }
            if (uid == 0) uid = GuidTool.GenDateLong();
            Collection collect = ObjPool.Instance.Get<Collection>();
            collect.Go = go;
            collect.UID = uid;
            collect.Info = info;
            return collect;
        }
        #endregion
    }
}