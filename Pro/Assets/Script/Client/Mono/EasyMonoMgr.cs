/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014/6/5 00:00:00
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    using MonoDic = Dictionary<string, EasyMono>;

    /// <summary>
    /// EasyMono管理
    /// </summary>
    public static class EasyMonoMgr
    {
        #region 字段
        private static Transform root = null;

        private static MonoDic dic = new MonoDic();
        #endregion

        #region 属性

        /// <summary>
        /// 根节点
        /// </summary>
        public static Transform Root
        {
            get
            {
                if (root == null)
                {
                    string name = typeof(EasyMonoMgr).Name;
                    root = TransTool.CreateRoot(name);
                }
                return root;
            }
        }

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
        /// <summary>
        /// 创建
        /// </summary>
        /// <param name="name">名称</param>
        /// <returns></returns>
        public static EasyMono Create(string name)
        {
            if (string.IsNullOrEmpty(name))
            {
                return null;
            }
            if (dic.ContainsKey(name))
            {
                return dic[name];
            }

            var go = new GameObject(name);
            go.transform.parent = Root;
            var mono = go.AddComponent<EasyMono>();
            dic.Add(name, mono);
            return mono;
        }

        /// <summary>
        /// 创建简单Mono
        /// </summary>
        /// <param name="type"></param>
        /// <returns></returns>
        public static EasyMono Create(Type type)
        {
            if (type == null) return null;
            return Create(type.Name);
        }

        /// <summary>
        /// 创建简单Mono
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public static EasyMono Create<T>() where T : class
        {
            return Create(typeof(T).Name);
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="name"></param>
        public static void Remove(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (!dic.ContainsKey(name)) return;
            var mono = dic[name];
            dic.Remove(name);
            Object.DestroyImmediate(mono.gameObject);
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            dic.Clear();
            TransTool.ClearChildren(root);
        }

        #endregion
    }
}