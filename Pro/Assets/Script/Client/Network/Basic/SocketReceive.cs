using System;
using UnityEngine;
using System.Threading;
using System.Net.Sockets;
using UnityEngine.Profiling;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:接收网络数据
    /// </summary>
    public class SocketReceive : SocketReceiveBase
    {
        #region 字段
        private int offset = 0;
        /// <summary>
        /// 读取数据大小
        /// </summary>
        private int readSize = 0;
        /// <summary>
        /// 接受数据总大小
        /// </summary>
        private int recvSize = 0;

        /// <summary>
        /// 包长度占用的字节数
        /// </summary>
        private const int headPktLen = 4;

        /// <summary>
        /// 协议ID占用的字节数
        /// </summary>
        private const int headIDLen = 2;

        /// <summary>
        /// 缓存区大小
        /// </summary>
        private const int bufSize = 1024 * 4096;

        /// <summary>
        /// 数据缓冲区
        /// </summary>
        private byte[] buf = new byte[bufSize];


        /// <summary>
        /// 接受数据线程
        /// </summary>
        private Thread thread = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件
        public static event Action onLsnr = null;
        #endregion

        #region 构造方法
        public SocketReceive()
        {
#if UNITY_EDITOR
            MonoEvent.onDestroy += Disconnect;
#endif
        }
        #endregion

        #region 私有方法
        private void Run()
        {
            if (thread != null) return;
            Running = true;
            thread = new Thread(Receive);
            thread.IsBackground = true;
            thread.Name = "ReceiveThread";
            thread.Start();
        }

        /// <summary>
        /// 处理数据
        /// 注:协议ID区间,CS{0-20000},LUA:{20000以上}
        /// </summary>
        private void Execute()
        {
            byte[] pkt = null;
            lock (pkts)
            {
                pkt = pkts.Dequeue();
            }
            if (pkt == null) return;
            ushort protoID = BitConverter.ToUInt16(pkt, 0);

            Profiler.BeginSample("TestSocketReceive:"+ protoID);
            int dataLen = pkt.Length - headIDLen;
            if (protoID < 20000)
            {
                Type type = ProtoMgr.Get(protoID);
                if (type == null)
                {
                    iTrace.Error("Loong", "NO ProtoID:{0},check (Protos.bin) and (proto.cs) are synchronized", protoID);
                    return;
                }
                object obj = null;

                if (dataLen > 0)
                {
                    Byte[] data = new byte[dataLen];
                    Buffer.BlockCopy(pkt, headIDLen, data, 0, dataLen);
                    try
                    {
                        obj = ProtobufTool.Deserialize(type, data);
                    }
                    catch (Exception e)
                    {
                        iTrace.Error("Loong", "decode proto:{0},type:{1},err:{2},Please check whether the front-back protocols are consistent.", protoID, type, e.Message);
                    }
                }
                else if (dataLen == 0)
                {
                    obj = ObjPool.Instance.Get(type);
                }
                else
                {
                    iTrace.Error("Loong", "proto:{0} return length is too small", protoID);
                }
                if (obj != null)
                {
                    NetworkListener.Execute(obj);
                    ReflectionTool.ListPropClear(obj);
                    ObjPool.Instance.Add(obj);
                }
            }
            else
            {
                Byte[] data = new byte[dataLen];
                Buffer.BlockCopy(pkt, headIDLen, data, 0, dataLen);
                LuaNetBridge.Execute(protoID, data);
            }
            Profiler.EndSample();
            if (skt != null)
            {
                if (onLsnr != null) onLsnr();
            }

        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public override void Update()
        {
            if (skt == null) return;
            if (thread == null) return;
            if (!skt.Connected) return;
            lock (pkts)
            {
                if (pkts.Count == 0) return;
            }
            while (true)
            {
                Execute();

                count++;
                lock (pkts)
                {
                    if (pkts.Count == 0)
                    {
                        count = 0; return;
                    }
                }
                if (count > MaxSize)
                {
                    count = 0; return;
                }
            }
        }

        public override void Connect()
        {
            base.Connect();
            Reset();
            Run();
        }

        public override void Receive()
        {

            while (true)
            {
                if (skt == null)
                {
                    Stop();
                    break;
                }
                if (!skt.Connected) continue;
                readSize = 0;
                int size = bufSize - recvSize;
                try
                {
                    readSize = skt.Receive(buf, recvSize, size, SocketFlags.None);
                }
                catch (Exception e)
                {
                    string err = "Receive:" + e.Message;
#if UNITY_EDITOR
                    iTrace.Log("Loong", err);
#else
                    iTrace.Error("Loong", err);
#endif
                    Stop();
                    break;
                }
                if (readSize < 1)
                {
                    Stop();
                    break;
                }
                recvSize += readSize;

                Split();
            }
        }

        public void Split()
        {
            offset = 0;
            while (recvSize >= 6)
            {
                if (skt == null || thread == null)
                {
                    Stop();
                    break;
                }
                int idx1 = offset + 1;
                int idx2 = offset + 2;
                int idx3 = offset + 3;
                int idx4 = offset + 4;
                int idx5 = offset + 5;

                ByteUtil.Swap(buf, offset, idx3);
                ByteUtil.Swap(buf, idx1, idx2);
                ByteUtil.Swap(buf, idx4, idx5);
                //包含ID和数据
                int pktLen = (int)BitConverter.ToUInt32(buf, offset);
                int realLen = pktLen + headPktLen;

                if (recvSize >= realLen)
                {
                    offset += headPktLen;
                    byte[] pkt = new byte[pktLen];
                    Buffer.BlockCopy(buf, offset, pkt, 0, pktLen);
                    lock (pkts)
                    {
                        pkts.Enqueue(pkt);
                    }
                    recvSize -= realLen;
                    if (recvSize > 0)
                    {
                        offset += pktLen;
                    }
                    else if (recvSize == 0)
                    {
                        return;
                    }
                    else
                    {
                        Stop();
                        return;
                    }
                }
                else
                {
                    ByteUtil.Swap(buf, offset, idx3);
                    ByteUtil.Swap(buf, idx1, idx2);
                    ByteUtil.Swap(buf, idx4, idx5);
                    break;
                }

            }
            Buffer.BlockCopy(buf, offset, buf, 0, recvSize);
            if (skt == null || thread == null)
            {
                Stop();
            }

        }

        public override void Disconnect()
        {
            base.Disconnect();
            Clear();
            thread = null;
        }


        private void Clear()
        {
            Reset();
            pkts.Clear();
        }

        private void Stop()
        {
            //lock (pkts)
            {
                Running = false;
                Clear();
            }
        }

        public void Reset()
        {
            offset = 0;
            recvSize = 0;
        }

        #endregion
    }
}