/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 * 文件大小默认单位是B
 ============================================================================*/

using System;
using System.IO;

namespace Loong.Game
{

    /// <summary>
    /// 下载文件接口
    /// </summary>
    public abstract class DownloadBase : IDisposable
    {
        #region 字段
        private long size = 0;
        private long total = 0;
        private long speed = 0;
        private long limit = 0;
        private long aveSpeed = 0;
        private string src = null;
        private string dest = null;
        private bool isStop = false;
        private bool broken = false;
        private bool running = false;
        private IProgress iPro = null;
        private IDownLoadSize iSetSize = null;
        #endregion

        #region 属性
        /// <summary>
        /// 已经下载的文件大小
        /// </summary>

        public long Size
        {
            get { return size; }
            protected set { size = value; }
        }

        /// <summary>
        /// 文件的总大小
        /// </summary>
        public long Total
        {
            get { return total; }
            protected set { total = value; }
        }


        /// <summary>
        /// 下载速度 B/S
        /// </summary>
        public long Speed
        {
            get { return speed; }
            protected set { speed = value; }
        }

        /// <summary>
        /// 限制速度 B/S <1:代表不限速
        /// </summary>
        public long Limit
        {
            get { return limit; }
            set { limit = value; }
        }


        /// <summary>
        /// 平均速度
        /// </summary>
        public long AveSpeed
        {
            get { return aveSpeed; }
            protected set { aveSpeed = value; }
        }


        /// <summary>
        /// 服务器路径
        /// </summary>
        public string Src
        {
            get { return src; }
            set { src = value; }
        }

        /// <summary>
        /// 本地路径
        /// </summary>
        public string Dest
        {
            get { return dest; }
            set { dest = value; }
        }

        /// <summary>
        /// true:断点的
        /// </summary>
        public bool Broken
        {
            get { return broken; }
            set { broken = value; }
        }

        private object obj = new object();

        /// <summary>
        /// true:停止
        /// </summary>

        public bool IsStop
        {
            get { return isStop; }
            set
            {
                lock (obj)
                {
                    isStop = value;
                }
            }
        }

        /// <summary>
        /// 是否正在运行中
        /// </summary>
        public bool Running
        {
            get { return running; }
            set { running = value; }
        }



        /// <summary>
        /// 进度接口
        /// </summary>
        public IProgress IPro
        {
            get { return iPro; }
            set { iPro = value; }
        }


        /// <summary>
        /// 已下载大小接口
        /// </summary>
        public IDownLoadSize ISetSize
        {
            get { return iSetSize; }
            set { iSetSize = value; }
        }

        #endregion

        #region 委托事件
        /// <summary>
        /// 下载结束事件,true:下载成功,false:下载失败
        /// </summary>
        public event Action<DownloadBase, bool> complete = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void Complete(bool suc)
        {
            Close();
            if (complete != null)
            {
                complete(this, suc);
            }
        }
        #endregion

        #region 公开方法


        /// <summary>
        /// 重置
        /// </summary>
        public void Reset()
        {
            Size = 0;
            Total = 0;
            Speed = 0;
        }

        /// <summary>
        /// 停止
        /// </summary>
        public virtual void Stop()
        {
            IsStop = true;
            Running = false;
        }

        /// <summary>
        /// 连接
        /// </summary>
        /// <param name="source"></param>
        /// <param name="target"></param>
        public abstract bool Connect();

        /// <summary>
        /// 断开连接
        /// </summary>
        public abstract void Disconnect();

        /// <summary>
        /// 执行下载
        /// </summary>
        /// <returns></returns>
        public abstract bool Execute();


        /// <summary>
        /// 单独开线程下载
        /// </summary>
        public abstract void Start();


        /// <summary>
        /// 关闭,不清理事件
        /// </summary>
        public virtual void Close()
        {

        }

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {
            Close();
            IPro = null;
            ISetSize = null;
            Src = null;
            Dest = null;
            Broken = false;
            IsStop = false;
            complete = null;
        }
        #endregion


    }
}