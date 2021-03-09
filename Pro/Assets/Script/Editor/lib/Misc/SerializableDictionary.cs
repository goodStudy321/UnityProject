/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/03/11,10:16:32
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 序列化字典
    /// </summary>
    [Serializable]
    public class SerializableDictionary<Tkey, TValue> : Dictionary<Tkey, TValue>, ISerializationCallbackReceiver
    {
        #region 字段
        /// <summary>
        /// 键列表
        /// </summary>
        public List<Tkey> ks = new List<Tkey>();

        /// <summary>
        /// 值列表
        /// </summary>
        public List<TValue> vs = new List<TValue>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        /// <summary>
        /// 显式构造方法
        /// </summary>
        public SerializableDictionary()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 序列化之前
        /// </summary>
        public void OnBeforeSerialize()
        {
            ks.Clear();
            vs.Clear();
            var em = this.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                ks.Add(it.Key);
                vs.Add(it.Value);
            }
        }

        /// <summary>
        /// 序列化之后
        /// </summary>
        public void OnAfterDeserialize()
        {
            this.Clear();
            if (ks.Count != vs.Count)
            {
                iTrace.Error("Loong", "序列化字典时键数量和值数量不一致"); return;
            }
            int length = ks.Count;
            for (int i = 0; i < length; i++) this.Add(ks[i], vs[i]);
        }
        #endregion
    }
}