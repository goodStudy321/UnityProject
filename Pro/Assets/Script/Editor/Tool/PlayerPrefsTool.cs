using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        6a531735-6ef3-4528-88dc-4d03120352c2
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/4/18 16:33:34
    /// BG:用户偏好设置工具
    /// </summary>
    public static class PlayerPrefsTool
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 100;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "用户偏好设置/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "用户偏好设置/";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void DeleteKey(string key)
        {
            if (string.IsNullOrEmpty(key))
            {
                return;
            }
            if (PlayerPrefs.HasKey(key))
            {
                PlayerPrefs.DeleteKey(key);
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        [MenuItem(menu + "清理登陆信息缓存", false, Pri)]
        [MenuItem(AMenu + "清理登陆信息缓存", false, Pri)]
        public static void ClearAccount()
        {
            DeleteKey("Account");
            DeleteKey("Password");
            DeleteKey("EnterRecord");
            DeleteKey("FristFeeder");


            UIEditTip.Log("清理成功");

        }
        [MenuItem(menu + "清理通知信息", false, Pri + 1)]
        [MenuItem(AMenu + "清理通知信息", false, Pri + 1)]
        public static void ClearPush()
        {
            DeleteKey("PushMgrPrefData");
        }
        #endregion
    }
}