/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/25 14:24:15
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 压缩类型工厂
    /// </summary>
    public static class CompFty
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
        /// 创建压缩类型
        /// </summary>
        /// <param name="tn">类型名称</param>
        /// <returns></returns>
        public static CompBase Create(string tn)
        {
            Type t = Type.GetType(tn);
            if (t == null)
            {
                string fullName = "Loong.Game." + tn;
                t = Type.GetType(fullName);
            }
            object obj = null;
            try
            {
                obj = Activator.CreateInstance(t);
            }
            catch (Exception e)
            {
                string err = string.Format("创建压缩类型:{0}实例错误", e.Message);
                iTrace.Error("Loong", err);
            }
            if (obj == null) return null;
            CompBase zip = obj as CompBase;
            return zip;
        }

        /// <summary>
        /// 根据类型创建压缩实例
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <returns></returns>
        public static CompBase Create<T>() where T : CompBase, new()
        {
            var t = new T();
            return t;
        }

        /// <summary>
        /// 创建默认压缩
        /// </summary>
        /// <returns></returns>
        public static CompBase Create()
        {
#if LOONG_ENABLE_UPG
            return new LzmaU();
#else
            return null;
#endif
        }

        #endregion
    }
}