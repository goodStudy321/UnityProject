using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:资源处理器设置
    /// </summary>
    public class AssetProcessorSetting : EditWinBase
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
        /// 打开资源处理器设置窗口
        /// </summary>
        [MenuItem(AssetProcessor.menu + "设置", false, MenuTool.AssetPri + 7)]
        [MenuItem(AssetProcessor.AMenu + "设置", false, MenuTool.AssetPri + 7)]
        public static void Open()
        {
            WinUtil.Open<AssetProcessorSetting, AssetProcessorView>("资源处理器", 600, 800);
        }
        #endregion
    }

}
