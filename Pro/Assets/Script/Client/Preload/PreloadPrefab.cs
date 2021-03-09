/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 10:11:25
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 预加载Prefab
    /// </summary>
    public class PreloadPrefab : PreloadBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public PreloadPrefab()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public override void Execute()
        {
            if (dic.Count == 0) return;
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var cur = em.Current;
                var name = cur.Key;
                if (GbjPool.Instance.Exist(name)) continue;
                if (GbjPool.Instance.IsPersist(name)) continue;
                if (AssetMgr.Instance.Get(name, Suffix.Prefab) != null) continue;
                var dg = ObjPool.Instance.Get<DelGbjToPool>();
                dg.Persist = cur.Value;
                AssetMgr.Instance.Add(name, Suffix.Prefab, dg.Callback);
            }
            Dispose();
        }

        /// <summary>
        /// 添加,类型名称和资源名称一致
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="pst">true:设置AB持久化</param>
        public void Add<T>(bool pst = false)
        {
            Add(typeof(T), pst);
        }

        /// <summary>
        /// 添加,类型名称和资源名称一致
        /// </summary>
        /// <param name="type"></param>
        /// <param name="pst">true:设置AB持久化</param>
        public void Add(Type type, bool pst = false)
        {
            if (type == null) return;
            Add(type.Name, pst);
        }

        #endregion
    }
}