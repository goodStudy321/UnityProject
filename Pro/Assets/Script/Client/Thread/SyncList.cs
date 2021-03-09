//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/18 11:59:59
// 线程安全列表
//=============================================================================

using System;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// SyncList
    /// </summary>
    public class SyncList<T>
    {
        #region 字段
        private List<T> val = null;

        #endregion

        #region 属性

        public List<T> Val
        {
            get { return val; }
            set { val = value; }
        }

        public int Count
        {
            get
            {
                lock (val)
                {
                    return val.Count;
                }
            }
        }

        public T this[int index]
        {
            get
            {
                lock (val)
                {
                    return val[index];
                }
            }
            set
            {
                lock (val)
                {
                    val[index] = value;
                }
            }

        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public SyncList()
        {

        }

        public SyncList(List<T> val)
        {
            this.val = val;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Add(T v)
        {
            lock (val)
            {
                val.Add(v);
            }
        }

        public void Remove(T v)
        {
            lock (val)
            {
                val.Remove(v);
            }
        }


        public T RemoveAt(int index)
        {
            lock (val)
            {
                var t = val[index];
                val.RemoveAt(index);
                return t;
            }
        }

        public T RemoveLast()
        {
            lock (val)
            {
                var index = val.Count - 1;
                var t = val[index];
                val.RemoveAt(index);
                return t;
            }
        }


        public void Clear()
        {
            lock (val)
            {
                val.Clear();
            }
        }

        #endregion
    }
}