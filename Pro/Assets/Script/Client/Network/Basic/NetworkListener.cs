using System;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:网络监听
    /// </summary>
    public static class NetworkListener
    {
        #region 字段
        /// <summary>
        /// 接收数据监听
        /// </summary>
        private static Dictionary<Type, Action<object>> dic = new Dictionary<Type, Action<object>>();
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
        /// 添加处理器
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="handler"处理器></param>
        public static void Add<T>(Action<object> handler) where T : class
        {
            Add(typeof(T), handler);
        }

        /// <summary>
        /// 添加处理器
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="handler">处理器</param>
        public static void Add(Type type, Action<object> handler)
        {
            if (type == null) return;
            if (handler == null) return;
            if (dic.ContainsKey(type))
            {
                dic[type] += handler;
            }
            else
            {
                dic.Add(type, handler);
            }
        }

        /// <summary>
        /// 添加处理器
        /// </summary>
        /// <param name="id"></param>
        /// <param name="handler"></param>
        public static void Add(ushort id, Action<object> handler)
        {
            Type type = ProtoMgr.Get(id);
            Add(type, handler);
        }

        /// <summary>
        /// 移除处理器
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="handler">处理器</param>
        public static void Remove<T>(Action<object> handler)
        {
            Remove(typeof(T), handler);
        }

        /// <summary>
        /// 移除处理器
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="handler">处理器</param>
        public static void Remove(Type type, Action<object> handler)
        {
            if (type == null) return;
            if (handler == null) return;
            if (dic.ContainsKey(type))
            {
                dic[type] -= handler;
            }
        }

        /// <summary>
        /// 移除处理器
        /// </summary>
        /// <param name="id">协议ID</param>
        /// <param name="handler">处理器</param>
        public static void Remove(ushort id, Action<object> handler)
        {
            Type type = ProtoMgr.Get(id);
            Remove(type, handler);
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        public static void Remove<T>()
        {
            Remove(typeof(T));
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="type">类型</param>
        public static void Remove(Type type)
        {
            if (type == null) return;
            if (dic.ContainsKey(type))
            {
                dic.Remove(type);
            }
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="id">协议ID</param>
        public static void Remove(ushort id)
        {
            Type type = ProtoMgr.Get(id);
            Remove(type);
        }


        /// <summary>
        /// 解析事件
        /// </summary>
        /// <param name="obj">处理对象</param>
        public static void Execute(object obj)
        {
            Type type = obj.GetType();
            if (!dic.ContainsKey(type)) return;
            if (dic[type] == null) return;
            dic[type](obj);
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            dic.Clear();
        }
        #endregion
    }
}