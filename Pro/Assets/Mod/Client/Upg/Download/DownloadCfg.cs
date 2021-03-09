using System;
using System.Collections;
using System.Collections.Generic;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.3
    /// BG:下载配置
    /// </summary>
    public static class DownloadCfg
    {
        #region 字段

        private static bool useCarrier = false;
        #endregion

        #region 属性

        /// <summary>
        /// 使用数据流量
        /// </summary>
        public static bool UseCarrier
        {
            get { return useCarrier; }
            set { useCarrier = value; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}