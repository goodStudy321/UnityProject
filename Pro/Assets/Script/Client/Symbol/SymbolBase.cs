using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:符号基类
    /// </summary>
    public abstract class SymbolBase : IDisposable
    {
        #region 字段
        private bool isOver = false;

        private bool relative = false;

        private string name = null;

        /// <summary>
        /// 符号变换组件
        /// </summary>
        protected Transform trans = null;

        #endregion

        #region 属性

        /// <summary>
        /// 符号名称
        /// </summary>
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        /// <summary>
        /// true:结束
        /// </summary>
        public bool IsOver
        {
            get { return isOver; }
            set { isOver = value; }
        }

        /// <summary>
        /// 符号游戏物体
        /// </summary>
        public GameObject go
        {
            get
            {
                if (trans == null) return null;
                else return trans.gameObject;
            }
        }

        /// <summary>
        /// true:旋转180
        /// </summary>
        public bool Relative
        {
            get { return relative; }
            set { relative = value; }
        }

        #endregion

        #region 构造方法
        public SymbolBase()
        {

        }

        public SymbolBase(string name)
        {
            this.name = name;
        }
        #endregion

        #region 私有方法

        #endregion
        /// <summary>
        /// 发射
        /// </summary>
        public abstract void Launch();

        /// <summary>
        /// 更新
        /// </summary>
        public abstract void Update();

        public void SetOver()
        {
            IsOver = true;
        }
        #region 保护方法

        #endregion

        #region 公开方法
        public virtual void Dispose()
        {
            relative = false;
            if (trans == null) return;
            GbjPool.Instance.Add(trans.gameObject);
            trans = null;
        }
        #endregion
    }
}