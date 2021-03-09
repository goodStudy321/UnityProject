using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.4.12
    /// BG:上下文菜单扩展工具
    /// </summary>
    public static class ExGenericMenu
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
        /// 添加一个不可用的上下文菜单
        /// </summary>
        /// <param name="menu">菜单</param>
        /// <param name="name">菜单名</param>
        public static void AddDisableItem(this GenericMenu menu, string name)
        {
            menu.AddDisabledItem(new GUIContent(name));
        }

        /// <summary>
        /// 添加一个可用的上下文菜单
        /// </summary>
        /// <param name="menu">菜单</param>
        /// <param name="name">菜单名</param>
        /// <param name="on">选择</param>
        /// <param name="func">菜单点击方法</param>
        public static void AddItem(this GenericMenu menu, string name, bool on, GenericMenu.MenuFunction func)
        {
            menu.AddItem(new GUIContent(name), on, func);
        }

        /// <summary>
        /// 添加一个可用的上下文菜单并可传递一个参数
        /// </summary>
        /// <param name="menu">菜单</param>
        /// <param name="name">菜单名</param>
        /// <param name="on">选择</param>
        /// <param name="func2">菜单点击方法</param>
        /// <param name="data">参数</param>
        /// 
        public static void AddItem(this GenericMenu menu, string name, bool on, GenericMenu.MenuFunction2 func2, object data)
        {
            menu.AddItem(new GUIContent(name), on, func2, data);
        }

        #endregion
    }
}