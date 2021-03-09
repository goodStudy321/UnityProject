using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.10.13
    /// BG:头顶显示
    /// </summary>
    public abstract class TopBarBase : IDisposable
    {
        #region 字段

        private string barName = TopBarFty.LocalPlayerBarStr;

        private Transform mTransform = null;

        protected Vector3 pos = Vector3.zero;
        #endregion

        #region 属性
        /// <summary>
        /// 要加载的头顶预制件名称
        /// </summary>
        public string BarName
        {
            get { return barName; }
            set { barName = value; }
        }
        /// <summary>
        /// 变换组件
        /// </summary>
        public Transform transform
        {
            get { return mTransform; }
            set { mTransform = value; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 返回true才执行自定义更新
        /// </summary>
        /// <returns></returns>
        protected abstract bool Check();

        /// <summary>
        /// 自定义更新
        /// </summary>
        protected abstract void UpdateCustom();

        /// <summary>
        /// 初始化加载预制件回调
        /// </summary>
        /// <param name="go"></param>
        protected abstract void LoadCallback(GameObject go);
        #endregion

        #region 公开方法
        /// <summary>
        /// 初始化
        /// </summary>
        public void Initialize()
        {
            AssetMgr.LoadPrefab(BarName, LoadCallback);
        }

        /// <summary>
        /// 更新
        /// </summary>
        public void Update()
        {
            if (Check()) UpdateCustom();
        }

        /// <summary>
        /// 打开
        /// </summary>
        public void Open()
        {
            if (mTransform != null) mTransform.gameObject.SetActive(true);
        }

        /// <summary>
        /// 关闭
        /// </summary>
        public void Close()
        {
            if (mTransform != null) mTransform.gameObject.SetActive(false);
        }

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {
            if (mTransform == null) return;
            ObjPool.Instance.Add(this);
            GbjPool.Instance.Add(mTransform.gameObject);
            mTransform = null;
        }
        #endregion
    }
}