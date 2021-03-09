/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/9 16:36:06
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using UnityEditor.Callbacks;
using System.Collections.Generic;
using Random = UnityEngine.Random;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 编辑器进度条工具
    /// </summary>
    public static class ProgressBarUtil
    {
        #region 字段
        private static int max = 10;

        private static int count = 0;

        private static int isShowVal = -1;

        private const string isShowName = "isShow";

        public const int Pri = MenuTool.NormalPri + 10;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = EditUtil.menu + "进度条/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "进度条/";

        /// <summary>
        /// 显示进度
        /// </summary>
        public const string IsShowPath = menu + "运行显示";
        #endregion

        #region 属性

        /// <summary>
        /// 刷新阈值
        /// </summary>
        public static int Max
        {
            get { return max; }
            set { max = value; }
        }


        /// <summary>
        /// true:显示进度条
        /// </summary>
        public static bool IsShow
        {
            get
            {
                if (Application.isBatchMode)
                {
                    return false;
                }
                if (isShowVal == -1)
                {
                    isShowVal = GetIsShowVal();
                }

                return (isShowVal != 0);
            }
            set
            {
                int val = (value ? 1 : 0);
                EditPrefsTool.SetInt(typeof(ProgressBarUtil), isShowName, val);
            }
        }

        #endregion

        #region 委托事件

        [DidReloadScripts]
        private static void Reset()
        {
            isShowVal = GetIsShowVal();
        }

        private static int GetIsShowVal()
        {
            return EditPrefsTool.GetInt(typeof(ProgressBarUtil), isShowName, 1);
        }

        private static bool GetIsShow()
        {
            var val = EditPrefsTool.GetInt(typeof(ProgressBarUtil), isShowName, 1);
            if (val == 0) return false;
            return true;
        }

        [MenuItem(IsShowPath, true, Pri + 2)]
        private static bool GetMenuIsShow()
        {
            var val = GetIsShow();
            Menu.SetChecked(IsShowPath, val);
            return true;
        }

        [MenuItem(IsShowPath, false, Pri + 2)]
        private static void SetMenuIsShow()
        {
            int val = GetIsShowVal();
            val = (val == 0 ? 1 : 0);
            isShowVal = val;
            EditPrefsTool.SetInt(typeof(ProgressBarUtil), isShowName, val);
        }


        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        [MenuItem(menu + "清理 #&C", false, Pri)]
        [MenuItem(AMenu + "清理", false, Pri)]
        private static void ClearPrograss()
        {
            EditorUtility.ClearProgressBar();
        }

        [MenuItem(menu + "清理缓存", false, Pri + 1)]
        [MenuItem(AMenu + "清理缓存", false, Pri + 1)]
        private static void ClearCache()
        {
            EditPrefsTool.Delete(typeof(ProgressBarUtil), isShowName);
            UIEditTip.Log("清理缓存成功");
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 显示进度
        /// </summary>
        /// <param name="title">标题</param>
        /// <param name="msg">信息</param>
        /// <param name="pro">进度</param>
        public static void Show(string title, string msg, float pro)
        {
            if (!IsShow) return;
            if (string.IsNullOrEmpty(msg)) msg = "";
            if (string.IsNullOrEmpty(title)) title = "请稍候";
            if (count < 1)
            {
                EditorUtility.DisplayProgressBar(title, msg, pro);
            }
            ++count;
            if (count > max) count = 0;
        }

        /// <summary>
        /// 显示随机进度
        /// </summary>
        /// <param name="title"></param>
        /// <param name="msg"></param>
        public static void Show(string title, string msg)
        {
            if (!IsShow) return;
            float pro = Random.Range(0f, 1f);
            Show(title, msg, pro);
        }


        /// <summary>
        /// 清理关闭进度条
        /// </summary>
        public static void Clear()
        {
            count = 0;
            if (!IsShow) return;
            EditorUtility.ClearProgressBar();
        }

        public static void Refresh()
        {
            count = 0;
        }
        #endregion
    }
}