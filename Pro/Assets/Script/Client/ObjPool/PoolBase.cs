/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/7/5 00:00:00
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    public class PoolInfo<T> where T : class, new()
    {
        private bool persist;

        public bool Persist
        {
            get { return persist; }
            set { persist = value; }
        }


        public Queue<T> queue = new Queue<T>();
    }

    /// <summary>
    /// 对象池基类
    /// </summary>
    public abstract class PoolBase<T> where T : class, new()
    {
        #region 字段
        private Dictionary<string, PoolInfo<T>> dic = new Dictionary<string, PoolInfo<T>>();
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
        /// <summary>
        /// 创建类型实例
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        protected virtual T Create(string name)
        {
            return new T();
        }

        /// <summary>
        /// 实例被释放
        /// </summary>
        /// <param name="t"></param>
        protected virtual void Dispose(T t)
        {

        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 获取
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public virtual T Get(string name)
        {
            T t = null;
            if (dic.ContainsKey(name))
            {
                var info = dic[name];
                if (info.queue.Count > 0)
                {
                    t = info.queue.Dequeue();
                }
            }
            if (t == null)
            {
                t = Create(name);
            }
            return t;
        }

        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="name"></param>
        /// <param name="t"></param>
        public virtual void Add(string name, T t)
        {
            if (t == null) return;
            PoolInfo<T> info = null;
            if (dic.ContainsKey(name))
            {
                info = dic[name];
            }
            else
            {
                info = new PoolInfo<T>();
                dic[name] = info;
            }
            info.queue.Enqueue(t);
        }

        /// <summary>
        /// 设置持久化
        /// </summary>
        /// <param name="name"></param>
        /// <param name="val"></param>
        public void SetPersist(string name, bool val)
        {
            if (dic.ContainsKey(name))
            {
                var info = dic[name];
                info.Persist = val;
            }
        }

        /// <summary>
        /// 判断释放持久化
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public bool IsPersist(string name)
        {
            if (dic.ContainsKey(name))
            {
                var info = dic[name];
                return info.Persist;
            }
            return false;
        }

        /// <summary>
        /// 判断是否包含
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public virtual bool Exist(string name)
        {
            if (dic.ContainsKey(name))
            {
                return dic[name].queue.Count > 0;
            }
            return false;
        }

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {
            var dem = dic.GetEnumerator();
            while (dem.MoveNext())
            {
                var info = dem.Current.Value;
                if (info.Persist) continue;
                var queue = info.queue;
                var qem = queue.GetEnumerator();
                while (qem.MoveNext())
                {
                    var t = qem.Current;
                    Dispose(t);
                }
                queue.Clear();
            }
        }
        #endregion
    }
}