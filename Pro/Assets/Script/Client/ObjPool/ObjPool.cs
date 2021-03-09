/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/7/5 00:00:00
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Loong.Game
{
    /// <summary>
    /// 对象池
    /// </summary>
    public class ObjPool : PoolBase<object>
    {
        #region 字段
        public static readonly ObjPool Instance = new ObjPool();
        #endregion

        #region 属性

        #endregion

        #region 构造函数
        private ObjPool()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override object Create(string name)
        {
            object obj = null;
            var type = Type.GetType(name);
            if (type == null)
            {
                iTrace.Error("Loong", "not find type:{0}", name);
            }
            else
            {
                obj = Activator.CreateInstance(type, null);
            }
            return obj;
        }
        #endregion

        #region 公开方法

        /// <summary>
        /// 获取泛型类型对象
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <returns></returns>
        public T1 Get<T1>() where T1 : class, new()
        {
            var name = typeof(T1).FullName;
            var t = Get(name);
            return t as T1;
        }

        /// <summary>
        /// 获取指定类型对象
        /// </summary>
        /// <param name="type"></param>
        /// <returns></returns>
        public object Get(Type type)
        {
            if (type == null) return null;
            return Get(type.FullName);
        }


        public void Add(object obj)
        {
            if (obj == null) return;
            Add(obj.GetType().FullName, obj);
        }
        #endregion
    }
}