/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/31 18:12:19
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// MonoUtil
    /// </summary>
    public static class ScriptUtil
    {
        #region 字段
        public const int Pri = MenuTool.NormalPri + 50;

        public const string Menu = MenuTool.Loong + "脚本工具/";

        public const string AMenu = MenuTool.ALoong + "脚本工具/";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Search(GameObject go, Type mono, List<Object> objs)
        {
            if (go == null) return;
            if (objs == null) return;
            if (mono == null) return;

            var t = go.GetComponentsInChildren(mono, true);
            if (t == null) return;
            int length = t.Length;
            for (int i = 0; i < length; i++)
            {
                objs.Add(t[i]);
            }
        }

        /// <summary>
        /// 在选择的资源中搜索引用指定脚本列表
        /// </summary>
        /// <param name="mono">脚本</param>
        /// <returns></returns>
        public static List<Object> SearchSelect(Type mono)
        {
            if (mono == null) return null;
            var arr = SelectUtil.Prefab();
            if (arr == null) return null;
            float len = arr.Count;
            var lst = new List<Object>();
            var title = "查找脚本中···";
            for (int i = 0; i < len; i++)
            {
                var go = arr[i];
                ProgressBarUtil.Show(title, go.name, i / len);
                Search(go, mono, lst);
            }
            ProgressBarUtil.Clear();
            return lst;
        }

        public static List<Object> SearchSelect(string typeName)
        {
            var asm = Assembly.GetAssembly(typeof(Main));
            var type = asm.GetType(typeName);
            if (type == null)
            {
                asm = Assembly.GetAssembly(typeof(UIPanel));
                type = asm.GetType(typeName);

            }
            if (type == null)
            {
                UIEditTip.Error("无:{0}的类型", typeName);
                return null;
            }
            return SearchSelect(type);
        }
        #endregion
    }
}