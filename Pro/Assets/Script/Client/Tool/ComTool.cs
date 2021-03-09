using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.09.23
    /// BG:组件工具
    /// </summary>
    public static class ComTool
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
        /// 获取组件
        /// </summary>
        /// <param name="type">组件类型</param>
        /// <param name="root">根节点</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="add">true:未发现组件时,将自动添加</param>
        /// <returns></returns>
        public static Component Get(Type type, Transform root, string path, string tip, bool add = false)
        {
            if (type == null)
            {
                iTrace.Error("Loong", string.Format("{0},获取组件,类型为空", tip)); return null;
            }

            GameObject child = TransTool.Find(root, path, tip);
            if (child == null) return null;
            Component com = child.GetComponent(type);

            if (add)
            {
                if (com == null) com = child.AddComponent(type);
            }
            else if (com == null)
            {
                iTrace.Error("Loong", string.Format("{0},根节点:{1},路径为:{2}的子物体上没有发现组件:{3}", tip, root.name, path, type.Name));
            }
            return com;
        }

        /// <summary>
        /// 获取组件
        /// </summary>
        /// <param name="typeName">组件类型名称</param>
        /// <param name="root">根节点</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="add">true:未发现组件时,将自动添加</param>
        /// <returns></returns>
        public static Component Get(string typeName, Transform root, string path, string tip, bool add = false)
        {
            Type type = Type.GetType(typeName);
            return Get(type, root, path, tip, add);
        }

        /// <summary>
        /// 获取组件
        /// </summary>
        /// <typeparam name="T">组件类型</typeparam>
        /// <param name="root">根节点</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="add">true:未发现组件时,将自动添加</param>
        /// <returns></returns>
        public static T Get<T>(Transform root, string path, string tip, bool add = false) where T : Component
        {
            Component com = Get(typeof(T), root, path, tip, add);
            T t = com as T; return t;
        }

        /// <summary>
        /// 获取组件
        /// </summary>
        /// <typeparam name="T">组件类型</typeparam>
        /// <param name="root">根节点</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="add">true:未发现组件时,将自动添加</param>
        /// <returns></returns>
        public static T Get<T>(GameObject root, string path, string tip) where T : Component
        {
            return Get<T>(root.transform, path, tip);
        }

        /// <summary>
        /// 添加组件 先检查目标物体上是否存在指定类型组件,如果没有则添加,最后返回组件
        /// </summary>
        public static T Get<T>(GameObject target) where T : Component
        {
            if (target == null) return null;
            T t = target.GetComponent<T>();
            if (t == null) t = target.AddComponent<T>();
            return t;
        }


        /// <summary>
        /// 添加组件 先检查目标物体上是否存在指定类型组件,如果没有则添加,最后返回组件
        /// </summary>
        public static T Get<T>(Transform target) where T : Component
        {
            if (target != null) return Get<T>(target.gameObject); return null;
        }

        /// <summary>
        /// 移除子物体上所有指定类型的组件
        /// </summary>
        /// <typeparam name="T">组件类型</typeparam>
        /// <param name="self">物体</param>
        /// <param name="only">false:包含物体自身的组件,true:仅仅子物体</param>
        public static void RemoveChildren<T>(GameObject self, bool only = false) where T : Component
        {
            if (self == null) return;
            T[] arr = self.GetComponentsInChildren<T>(true);
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                if (only) if (Object.ReferenceEquals(arr[i].gameObject, self)) continue;
                iTool.Destroy(arr[i]);
            }
        }

        /// <summary>
        /// 移除子物体上所有指定类型的组件
        /// </summary>
        /// <typeparam name="T">组件类型</typeparam>
        /// <param name="self">物体</param>
        /// <param name="only">false:包含物体自身的组件,true:仅仅子物体</param>
        public static void RemoveChildren<T>(Transform self, bool only = false) where T : Component
        {
            if (self != null) RemoveChildren<T>(self.gameObject);
        }

        /// <summary>
        /// 移除父物体上所有指定类型的组件
        /// </summary>
        /// <typeparam name="T">组件类型</typeparam>
        /// <param name="self">物体</param>
        /// <param name="only">false:包含物体自身的组件,true:仅仅父物体</param>
        public static void RemoveParent<T>(GameObject self, bool only = false) where T : Component
        {
            if (self == null) return;
            T[] arr = self.GetComponentsInParent<T>(true);
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                if (only) if (Object.ReferenceEquals(arr[i].gameObject, self)) continue;
                iTool.Destroy(arr[i]);
            }
        }

        /// <summary>
        /// 移除父物体上所有指定类型的组件
        /// </summary>
        /// <typeparam name="T">组件类型</typeparam>
        /// <param name="self">物体</param>
        /// <param name="only">false:包含物体自身的组件,true:仅仅父物体</param>
        public static void RemoveParent<T>(Transform self, bool only = false) where T : Component
        {
            if (self != null) RemoveParent<T>(self.gameObject);
        }

        /// <summary>
        /// 移除物体上所有指定类型的组件
        /// </summary>
        public static void Remove<T>(GameObject target) where T : Component
        {
            if (target == null) return;
            T[] arr = target.GetComponents<T>();
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++) iTool.Destroy(arr[i]);
        }

        /// <summary>
        /// 移除物体上所有指定类型的组件
        /// </summary>
        public static void Remove<T>(Transform target) where T : Component
        {
            if (target != null) Remove<T>(target.gameObject);
        }

        #endregion
    }
}