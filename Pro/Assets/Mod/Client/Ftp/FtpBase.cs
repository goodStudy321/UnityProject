/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.3.12 20:09:25
 ============================================================================*/

using System;
using System.Net;
using System.Collections;
using System.Collections.Generic;

namespace Loong
{
    /// <summary>
    /// Ftp基类
    /// </summary>
    public abstract class FtpBase : IDisposable
    {
        #region 字段
        private string localPath = "";
        private string remotePath = "";
        private string username = "";
        private string password = "";

        #endregion

        #region 属性

        /// <summary>
        /// 本地路径
        /// </summary>
        public string LocalPath
        {
            get { return localPath; }
            set { localPath = value; }
        }

        /// <summary>
        /// 远程路径
        /// </summary>
        public string RemotePath
        {
            get { return remotePath; }
            set { remotePath = value; }
        }

        /// <summary>
        /// 用户名
        /// </summary>
        public string UserName
        {
            get { return username; }
            set { username = value; }
        }

        /// <summary>
        /// 密码
        /// </summary>
        public string Password
        {
            get { return password; }
            set { password = value; }
        }


        #endregion

        #region 委托事件

        /// <summary>
        /// 进度回调事件
        /// </summary>
        public event Action<float> progress = null;

        /// <summary>
        /// 完成回调事件
        /// </summary>
        public event Action<FtpBase, bool> complete = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void SetPro(float val)
        {
            if (progress == null) return;
            progress(val);
        }

        protected void Complete(bool suc)
        {
            if (complete == null) return;
            complete(this, suc);
        }
        #endregion

        #region 公开方法


        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {
            localPath = "";
            remotePath = "";
            username = "";
            password = "";
            progress = null;
            complete = null;
        }



        public abstract bool Upload();

        public abstract bool Download();

        #endregion
    }
}