/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/9/29 11:05:33
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{

    /// <summary>
    /// 编辑器窗口工具
    /// </summary>
    public static partial class WinUtil
    {
        #region 字段
        /// <summary>
        /// 最大宽度
        /// </summary>
        public static int MaxWidth
        {
            get { return Screen.currentResolution.width; }
        }

        /// <summary>
        /// 最大高度
        /// </summary>
        public static int MaxHeight
        {
            get { return Screen.currentResolution.height - 50; }
        }
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
        /// 检查是否能打开
        /// </summary>
        /// <returns></returns>
        public static bool OpenCheck()
        {
            if (EditorApplication.isCompiling)
            {
                UIEditTip.Warning("等待编译结束后\n再打开"); return false;
            }
            return true;
        }

        /// <summary>
        /// 打开指定类型窗口,长宽和屏幕分辨率一致
        /// </summary>
        /// <typeparam name="T"></typeparam>
        public static void Open<T>() where T : EditWinBase
        {
            Resolution rs = Screen.currentResolution;
            Open<T>(rs.width, rs.height);
        }

        /// <summary>
        /// 打开指定类型窗口
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="width">宽度</param>
        /// <param name="height">高度</param>
        public static void Open<T>(int width, int height) where T : EditWinBase
        {
            if (!OpenCheck()) return;
            T t = EditorWindow.GetWindow<T>();
            t.autoRepaintOnSceneChange = true;
            t.SetSize(width, height);
            t.Init();
        }

        /// <summary>
        /// 获取制定类型的资源
        /// </summary>
        /// <typeparam name="TChild">子视图</typeparam>
        /// <typeparam name="TParent">父窗口</typeparam>
        /// <returns></returns>
        public static TChild Get<TChild, TParent>() where TChild : ScriptableObject where TParent : EditWinBase
        {
            return AssetDataUtil.Get<TChild>(typeof(TParent).Name);
        }

        /// <summary>
        /// 获取一个具有T2视图的T1窗口
        /// </summary>
        public static T1 Get<T1, T2>(string title) where T1 : EditWinBase where T2 : EditViewBase
        {
            T2 t2 = AssetDataUtil.Get<T2>();
            if (t2 == null) return null;
            T1 t1 = EditorWindow.GetWindow<T1>();
            t1.SetTitle(title);
            t1.autoRepaintOnSceneChange = true;
            t1.Add<T2>(t2);
            t1.Init();
            t1.Open<T2>();
            return t1;
        }

        /// <summary>
        /// 打开一个具有T2视图的T1窗口
        /// </summary>
        public static T1 Open<T1, T2>(string title, int width, int height) where T1 : EditWinBase where T2 : EditViewBase
        {
            T1 t1 = Get<T1, T2>(title);
            if (t1 == null)
            {
                UIEditTip.Warning("打开窗口失败,重新打开试试");
            }
            else
            {
                t1.SetSize(width, height);
                t1.Show();
            }
            return t1;
        }

        /// <summary>
        /// 获取有效尺寸
        /// </summary>
        /// <param name="width">宽度</param>
        /// <param name="height"></param>
        /// <returns></returns>
        public static Vector2 GetSize(int width, int height)
        {
            width = Mathf.Clamp(width, 100, MaxWidth);
            height = Mathf.Clamp(height, 100, MaxHeight);
            return new Vector2(width, height);
        }

        /// <summary>
        /// 根据尺寸获取在屏幕中间位置
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static Vector2 GetCenterPosition(Vector2 size)
        {
            return GetCenterPosition(size.x, size.y);
        }

        /// <summary>
        /// 根据长宽获取在屏幕中间位置
        /// </summary>
        /// <param name="width">长</param>
        /// <param name="height">宽</param>
        /// <returns></returns>
        public static Vector2 GetCenterPosition(float width, float height)
        {
            float x = (MaxWidth - width) * 0.5f;
            float y = (MaxHeight - height) * 0.5f;
            return new Vector2(x, y);
        }

        /// <summary>
        /// 根据尺寸显示在相对窗口的中间时窗口的位置
        /// </summary>
        /// <param name="anchorWin">相对窗口</param>
        /// <param name="size">尺寸</param>
        /// <returns></returns>
        public static Vector2 GetRelativePosition(EditorWindow anchorWin, Vector2 size)
        {
            return GetRelativePosition(anchorWin, size.x, size.y);
        }

        /// <summary>
        /// 根据长宽显示在相对窗口的中间时窗口的位置
        /// </summary>
        /// <param name="anchorWin">相对窗口</param>
        /// <param name="width">长</param>
        /// <param name="height">宽</param>
        /// <returns></returns>
        public static Vector2 GetRelativePosition(EditorWindow anchorWin, float width, float height)
        {
            if (anchorWin == null) return GetCenterPosition(width, height);
            Rect anchorPos = anchorWin.position;
            float x = anchorPos.x + (anchorPos.width - width);
            float y = anchorPos.y + (anchorPos.height - height);
            return new Vector2(x, y);
        }
        #endregion
    }
}