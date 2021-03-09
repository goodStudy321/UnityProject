/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/11/17 11:35:32
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 加载到对象池
    /// </summary>
    public class DelGbjToPool : DelObj<GameObject>
    {
        #region 字段
        private bool persist;

        #endregion

        #region 属性

        public bool Persist
        {
            get { return persist; }
            set { persist = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override GameObject Get(Object obj)
        {
            GameObject go = null;
            if (obj != null)
            {
                go = GameObject.Instantiate(obj) as GameObject;
                go.name = obj.name;
#if UNITY_EDITOR
                ShaderTool.eResetGbj(go);
#endif
            }
            return go;
        }

        protected override void Execute(GameObject t)
        {
            if (t == null) return;
            GbjPool.Instance.Add(t);
            if (persist)
            {
                var name = t.name;
                GbjPool.Instance.SetPersist(name, true);
                AssetMgr.Instance.SetPersist(name, Suffix.Prefab);
            }
        }

        #endregion

        #region 公开方法
        public override void Dispose()
        {
            persist = false;
        }
        #endregion
    }
}