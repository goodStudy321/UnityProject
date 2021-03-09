/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/7/5 00:00:00
 ============================================================================*/

using UnityEngine;

namespace Loong.Game
{
    /// <summary>
    /// 游戏对象池
    /// </summary>
    public class GbjPool : PoolBase<GameObject>
    {
        #region 字段

        private Transform root = null;

        public static readonly GbjPool Instance = new GbjPool();
        #endregion

        #region 属性
        /// <summary>
        /// 根节点
        /// </summary>
        public Transform Root
        {
            get
            {
                if (root == null)
                {
                    root = TransTool.CreateRoot<GbjPool>();
                }
                return root;
            }
        }

        #endregion

        #region 构造方法
        private GbjPool()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override GameObject Create(string name)
        {
            return null;
        }

        protected override void Dispose(GameObject t)
        {
            if (t == null) return;
            //AssetMgr.Instance.Unload(t.name, Suffix.Prefab);
            GameObject.DestroyImmediate(t, true);
        }
        #endregion


        #region 公开方法

        /// <summary>
        /// 添加物体
        /// </summary>
        public void Add(GameObject go)
        {
            if (go == null) return;
            var name = go.name;
#if UNITY_EDITOR
            if (name.EndsWith("(Clone)"))
            {
                iTrace.Error("Loong", "add GbjPool err, name:{0}", name);
            }
#endif
            Add(name, go);
        }

        public override void Add(string name, GameObject t)
        {
            if (t == null) return;
            base.Add(name, t);      
            t.SetActive(false);
            t.transform.SetParent(Root);
            //trans.localPosition = Vector3.zero;
        }

        public void Clear(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            while (true)
            {
                var target = Get(name);
                if (target == null) break;
                Object.DestroyImmediate(target);
            }
        }

        public override GameObject Get(string name)
        {
            if (string.IsNullOrEmpty(name)) return null;
            var go = base.Get(name);
            if (go == null) return null;
            //go.transform.parent = null;
            //go.SetActive(true);
            return go;
        }

        #endregion
    }
}