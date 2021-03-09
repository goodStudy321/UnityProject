using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        75c7b096-28b3-43d1-b1ee-5a22fa273d23
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/4 12:14:37
    /// BG:属性监听创建工厂
    /// </summary>
    public static class UnitPropLsnrFty
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
        /// 创建属性监听
        /// </summary>
        /// <param name="info"></param>
        /// <param name="owner"></param>
        /// <returns></returns>
        public static UnitPropLsnr Create(UnitPropertyInfo info)
        {
            if (info == null) return null;
            switch (info.propertyType)
            {
                case ListenerPropertyType.Hp: return new UnitHpPropLsnr(info);
                default: return null;
            }
        }
        #endregion
    }
}