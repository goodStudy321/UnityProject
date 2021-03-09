/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/1/6 1:03:56
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 列表工具
    /// </summary>
    public static class ListTool
    {
        #region 字段

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

        /// <summary>
        /// 移除指定索引元素;将将要移除的元素和最后元素交换;移除最后元素
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="lst">列表</param>
        /// <param name="i">索引</param>
        public static void Remove<T>(List<T> lst, int i)
        {
            if (lst == null) return;
            int last = lst.Count - 1;
            if (i > last) return;
            if (i < last)
            {
                Swap(lst, i, last);
            }
            lst.RemoveAt(last);
        }

        /// <summary>
        /// 交换列表中两个指定索引的引用
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="lst">列表</param>
        /// <param name="i1">索引1</param>
        /// <param name="i2">索引2</param>
        public static void Swap<T>(List<T> lst, int i1, int i2)
        {
            if (lst == null) return;
            int last = lst.Count - 1;
            if (i1 == i2) return;
            if (i1 > last) return;
            if (i2 > last) return;
            T temp = lst[i1];
            lst[i1] = lst[i2];
            lst[i2] = temp;
        }


        /// <summary>
        /// 清理列表;每一个列表项都调用Dispose;并放入对象池
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="lst">列表</param>
        public static void Clear<T>(List<T> lst) where T : IDisposable
        {
            if (lst == null) return;
            while (lst.Count > 0)
            {
                int last = lst.Count - 1;
                T t = lst[last];
                lst.RemoveAt(last);
                t.Dispose();
                ObjPool.Instance.Add(t);
            }
        }
        #endregion
    }
}