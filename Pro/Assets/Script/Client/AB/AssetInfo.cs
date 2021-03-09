/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 12:04:11
 ============================================================================*/
using System;
using UnityEngine;


namespace Loong.Game
{
    /// <summary>
    /// 资源信息
    /// </summary>
    public class AssetInfo
    {
        #region 字段
        private int uRef = 0;

        private short _ref = 0;

        private bool persist = false;

        private AssetBundle ab = null;
        #endregion

        #region 属性
        /// <summary>
        /// 使用引用计数
        /// </summary>
        public int URef
        {
            get { return uRef; }
            set { uRef = value; }
        }


        /// <summary>
        /// AB引用计数
        /// </summary>
        public short Ref
        {
            get { return _ref; }
            set { _ref = value; }
        }

        /// <summary>
        /// true:持久化
        /// </summary>
        public bool Persist
        {
            get { return persist; }
            set { persist = value; }
        }

        /// <summary>
        /// 资源包
        /// </summary>
        public AssetBundle Ab
        {
            get { return ab; }
            set { ab = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AssetInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 释放
        /// 当持久化属性为真时,不释放
        /// 当强制释放时,不管引用计数;反之当引用计数变为0时释放
        /// </summary>
        /// <param name="force">true:绕过引用计数,false:引用计数为0时释放</param>
        /// <param name="unload">true:释放所有已加载资源,false:仅仅释放AB内存</param>
        public void Unload(bool force = false, bool unload = true)
        {
            if (force)
            {
                Ref = 0;
                URef = 0;
                if (ab) ab.Unload(unload);
                Ab = null;
            }
            else
            {
                --Ref;
                if (_ref < 1)
                {
                    Ref = 0;
                    URef = 0;
                    if (persist) return;
                    if (ab != null) ab.Unload(unload);
                    Ab = null;
                }
            }
        }


        public void Dispose(bool unload = true)
        {
            Ref = 0;
            URef = 0;
            Persist = false;
            if (ab) ab.Unload(unload);

            Ab = null;
        }
        #endregion
    }
}