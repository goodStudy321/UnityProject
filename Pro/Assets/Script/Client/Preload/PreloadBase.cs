/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 10:11:25
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 预加载基类
    /// </summary>
    public class PreloadBase : IDisposable
    {
        #region 字段
        /// <summary>
        /// 预加载集合
        /// </summary>
        protected Dictionary<string, bool> dic = new Dictionary<string, bool>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public PreloadBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 添加资源名称到预加载列表
        /// </summary>
        /// <param name="name">音效和图片应该包含后缀</param>
        public virtual void Add(string name, bool persist = false)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (dic.ContainsKey(name))
            {
                dic[name] = persist;
            }
            else
            {
                dic.Add(name, persist);
            }
        }

        /// <summary>
        /// 将预加载列表添加到资源加载列表
        /// </summary>
        public virtual void Execute()
        {
            if (dic.Count == 0) return;
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var item = em.Current.Key;
                AssetMgr.Instance.Add(item, null);
            }
            Dispose();
        }

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {
            dic.Clear();
        }
        #endregion
    }
}