using System;
using System.Net.Sockets;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:Socket基类
    /// </summary>
    public abstract class SocketBase : IDisposable
    {
        #region 字段

        private ushort maxSize = 200;

        /// <summary>
        /// 套接字
        /// </summary>
        private Socket mSocket = null;

        /// <summary>
        /// 计数器
        /// </summary>
        protected ushort count = 0;

        /// <summary>
        /// 当前处理的消息
        /// </summary>
        protected byte[] packet = null;

        /// <summary>
        /// 要处理的消息队列
        /// </summary>
        protected Queue<byte[]> pkts = new Queue<byte[]>();

        #endregion

        #region 属性

        /// <summary>
        /// 一帧允许处理数据的最大次数
        /// </summary>
        public ushort MaxSize
        {
            get { return maxSize; }
            set { maxSize = value; }
        }


        /// <summary>
        /// 发送消息套接字
        /// </summary>
        public Socket skt
        {
            get { return mSocket; }
            set { mSocket = value; }
        }
        #endregion

        #region 构造方法
        public SocketBase()
        {

        }

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法


        #endregion

        #region 公开方法
        /// <summary>
        /// 更新
        /// </summary>
        public abstract void Update();

        /// <summary>
        /// 连接
        /// </summary>
        public virtual void Connect()
        {
            
        }

        /// <summary>
        /// 断开连接
        /// </summary>
        public virtual void Disconnect()
        {
            mSocket = null;
            //maxSize = 0;
            pkts.Clear();
            count = 0;
        }


        public virtual void Dispose()
        {
            lock (pkts)
            {
                Disconnect();
            }
        }

        #endregion
    }
}