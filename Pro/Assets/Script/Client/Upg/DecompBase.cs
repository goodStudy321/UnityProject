/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.5.29 20:17:52
 ============================================================================*/

using System;
using System.IO;
using System.Threading;

namespace Loong.Game
{
    /// <summary>
    /// 解压缩基类
    /// </summary>
    public abstract class DecompBase : IDisposable
    {
        #region 字段
        private float pro = 0;
        private bool isStop = false;
        private string error = null;
        private string src = null;
        private string dest = null;
        private Stream srcStream = null;
        #endregion

        #region 属性

        /// <summary>
        /// 进度
        /// </summary>
        public float Pro
        {
            get { return pro; }
            protected set { pro = value; }
        }

        /// <summary>
        /// true:停止
        /// </summary>
        public bool IsStop
        {
            get { return isStop; }
            set { isStop = value; }
        }


        /// <summary>
        /// 错误信息
        /// </summary>
        public string Error
        {
            get { return error; }
            set { error = value; }
        }


        public string Src
        {
            get { return src; }
            set { src = value; }
        }



        /// <summary>
        /// 解压目录/路径
        /// </summary>
        public string Dest
        {
            get { return dest; }
            set { dest = value; }
        }

        /// <summary>
        /// 解压需要路径
        /// </summary>
        public virtual bool IsFile
        {
            get { return false; }
        }

        /// <summary>
        /// 源文件流
        /// </summary>
        public Stream SrcStream
        {
            get { return srcStream; }
            set { srcStream = value; }
        }


        #endregion

        #region 委托事件
        /// <summary>
        /// 结束事件
        /// </summary>
        public Action<DecompBase, bool> complete;

        /// <summary>
        /// 进度事件
        /// </summary>
        public Action<float> progress;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Run(object arg)
        {
            Execute();
        }
        #endregion

        #region 保护方法
        public FileStream Create(string fileName, int bufSize)
        {
            return FileTool.SafeCreate(fileName, bufSize);
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 解压缩
        public abstract bool Execute();

        /// <summary>
        /// 通过线程运行
        /// </summary>
        public void RunThread()
        {
            while (!ThreadPool.QueueUserWorkItem(Run))
            {
                Thread.Sleep(10);
            }
        }

        public virtual void Dispose()
        {
            Pro = 0;
            Dest = null;
            complete = null;
            progress = null;
            if (srcStream != null) srcStream.Dispose();
            SrcStream = null;
        }
        #endregion
    }
}