using System;
using System.Net;
using System.Net.Sockets;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:发送网络数据
    /// </summary>
    public class SocketSend : SocketSendBase
    {
        #region 字段
        /// <summary>
        /// 发送成功的字节数组的长度
        /// </summary>
        private int successLen = 0;


        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public SocketSend()
        {

        }

        public SocketSend(Socket value)
        {
            skt = value;
        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 真正使用Socket发送数据方法
        /// </summary>
        private void Send()
        {
            packet = pkts.Dequeue();
            try
            {
                successLen = skt.Send(packet);
                if (packet.Length != successLen)
                {
                    iTrace.Error("Loong", "发送数据不完全");
                }
            }
            catch (Exception)
            {
                //iTrace.Error("Loong", "socket send:{0}", e.Message);
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Update()
        {
            if (skt == null) return;
            if (!skt.Connected) return;
            if (pkts.Count == 0) return;
            while (true)
            {
                Send();
                count++;
                if (pkts.Count == 0)
                {
                    count = 0; return;
                }
                if (count > MaxSize)
                {
                    count = 0; return;
                }
            }
        }

        public override void Send(byte[] arr)
        {
            if (arr == null) return;
            if (arr.Length == 0) return;
            pkts.Enqueue(arr);
        }


        public override void Disconnect()
        {
            base.Disconnect();
        }
        #endregion
    }
}