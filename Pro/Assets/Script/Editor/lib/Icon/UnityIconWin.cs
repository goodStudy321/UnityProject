using System;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        e371fff2-0903-43f1-8f48-1db1ef2d3241
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/5/17 15:53:50
    /// BG:Unity内置图标窗口
    /// </summary>
    public class UnityIconWin : EditWinBase
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
        /// 打开内置图标窗口
        /// </summary>
        public static void Open()
        {
            WinUtil.Open<UnityIconWin, UnityIconView>("内置图标", 600, Screen.currentResolution.height);
        }
        #endregion
    }
}