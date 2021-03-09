//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 19:57:17
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    using UIDic = Dictionary<string, GUIBase>;

    /// <summary>
    /// GUIMgr
    /// </summary>
    public static class GUIMgr
    {
        #region 字段
        private static UIDic dic = new UIDic();

        private static List<GUIBase> lst = new List<GUIBase>();

        #endregion

        #region 属性

        #endregion

        #region 委托事件
        public static event Action<GUIBase> open = null;

        public static event Action<GUIBase> close = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 激活GUI,并隐藏其它UI
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public static T Switch<T>() where T : GUIBase, new()
        {
            var name = typeof(T).Name;
            T t = null;
            if (dic.ContainsKey(name))
            {
                t = dic[name] as T;
                var em = dic.GetEnumerator();
                while (em.MoveNext())
                {
                    var cur = em.Current;
                    if (cur.Key == name) continue;
                    cur.Value.Enable = false;
                }
            }
            else
            {
                t = new T();
                t.Init();
                lst.Add(t);
                dic.Add(name, t);
            }
            t.Enable = true;
            return t;

        }

        /// <summary>
        /// 打开UI
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public static T Open<T>() where T : GUIBase, new()
        {
            return Switch<T>();
        }

        public static void Close<T>() where T : GUIBase
        {
            var name = typeof(T).Name;
            if (dic.ContainsKey(name))
            {
                dic[name].Enable = false;
            }
        }

        public static void OnGUI()
        {
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                var it = lst[i];
                if (it.Enable)
                {
                    it.OnGUI();
                }
            }
        }

        public static void HandlerOpen(GUIBase ui)
        {
            if (open != null) open(ui);
        }

        public static void HandlerClose(GUIBase ui)
        {
            if (close != null) close(ui);
        }
        #endregion
    }
}