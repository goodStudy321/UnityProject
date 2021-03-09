using System;
using ProtoBuf;
using System.IO;
using System.Net;
using UnityEngine;
using System.Threading;
using System.Net.Sockets;
using System.Collections.Generic;

namespace Loong.Game
{
    using Lang = Phantom.Localization;
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:网络客户端
    /// </summary>
    public static class NetworkClient
    {
        #region 字段

        private static int port = 0;

        private static IPAddress ip = null;

        private static MemoryStream ms = null;

        private static BinaryWriter bw = null;
        /// <summary>
        /// 套接字
        /// </summary>
        private static Socket socket = null;

        private static bool disableSend = false;
        /// <summary>
        /// 进度接口
        /// </summary>
        private static IProgress iProgress = null;

        /// <summary>
        /// 连接错误信息
        /// </summary>
        private static string connectError = null;

        /// <summary>
        /// 断开连接错误信息
        /// </summary>
        private static string disconnectError = null;

        /// <summary>
        /// 断开连接后重连
        /// </summary>
        private static bool disconnectThenConnect = false;


        /// <summary>
        /// 连接回调 参数为空:成功,反之:失败
        /// </summary>
        private static Action<string> connectCallback = null;

        /// <summary>
        /// 断开连接回调 参数为空:成功,反之:失败
        /// </summary>
        private static Action<string> disconnectCb = null;

        /// <summary>
        /// 客户端连接状态
        /// </summary>
        private static NetworkConnectState state = NetworkConnectState.None;


        /// <summary>
        /// 接收数据处理
        /// </summary>
        private static SocketReceiveBase receive = new SocketReceive();

        /// <summary>
        /// 发送数据处理
        /// </summary>
        private static SocketSendBase send = new SocketSend();

        #endregion

        #region 属性
        /// <summary>
        /// 端口
        /// </summary>
        public static int Port
        {
            get { return port; }
            set { port = value; }
        }

        /// <summary>
        /// IP地址
        /// </summary>
        public static IPAddress IP
        {
            get { return ip; }
            set { ip = value; }
        }

        /// <summary>
        /// 是否连接
        /// </summary>
        public static bool Connected
        {
            get
            {
                return SktUtil.IsConnect(socket);
            }
        }

        /// <summary>
        /// true:禁止发送协议
        /// </summary>
        public static bool DisableSend
        {
            get { return disableSend; }
            set { disableSend = value; }
        }


        public static SocketReceiveBase SktRecv
        {
            get { return receive; }
        }

        public static SocketSendBase SktSend
        {
            get { return send; }
        }

        public static NetworkConnectState State
        {
            get
            {
                return state;
            }
        }

        #endregion

        #region 构造方法
        static NetworkClient()
        {
#if UNITY_EDITOR
            MonoEvent.onDestroy += OnDestory;
#endif
        }
        #endregion

        #region 私有方法
#if UNITY_EDITOR
        private static void OnDestory()
        {
            Dispose();
        }
#endif
        private static void CheckMemory()
        {
            if (ms != null) return;
            ms = new MemoryStream();
            bw = new BinaryWriter(ms);
        }

        /// <summary>
        /// 检查套接字
        /// </summary>
        private static void CheckSocket(AddressFamily af)
        {
            if (socket != null) return;
            socket = new Socket(af, SocketType.Stream, ProtocolType.Tcp);
        }

        /// <summary>
        /// 检查连接
        /// </summary>
        /// <returns>错误信息</returns>
        private static string CheckConnect(string ipStr)
        {
            if (string.IsNullOrEmpty(ipStr)) return Lang.Instance.GetDes(620000);
            return null;
        }

        /// <summary>
        /// 释放套接字
        /// </summary>
        private static void DisposeSocket()
        {
            if (socket == null) return;
            if (socket.Connected)
            {
                socket.Shutdown(SocketShutdown.Both);
                socket.Disconnect(false);
            }
            socket.Close();
            socket = null;
        }

        /// <summary>
        /// 检查是否可以断开连接
        /// </summary>
        /// <returns></returns>
        private static string CheckDisconnect()
        {
            if (socket == null) return Lang.Instance.GetDes(620002);
            if (!socket.Connected) return Lang.Instance.GetDes(620003);
            return null;
        }

        /// <summary>
        /// 设置并打开进度
        /// </summary>
        /// <param name="progress"></param>
        private static void OpenProgress(IProgress progress)
        {
            iProgress = progress;
            if (iProgress != null) iProgress.Open();
        }

        /// <summary>
        /// 关闭进度
        /// </summary>
        private static void CloseProgress()
        {
            if (iProgress != null) iProgress.Close();
            iProgress = null;
        }

        /// <summary>
        /// 显示连接信息
        /// </summary>
        private static void ShowConnectMsg()
        {
            if (string.IsNullOrEmpty(connectError))
            {
                iTrace.Log("Loong", string.Format("连接成功:{0}:{1}", IP.ToString(), Port));
            }
            else
            {
                iTrace.Error("Loong", string.Format("连接失败:{0}:{1},错误信息:{2}", IP.ToString(), Port, connectError));
            }
        }

        /// <summary>
        /// 解析连接回调处理器
        /// </summary>
        private static void ExecuteConnectCallback()
        {
            ShowConnectMsg();
            CloseProgress();
            if (connectCallback != null) connectCallback(connectError);
            connectCallback = null;
        }

        /// <summary>
        /// 显示断开信息
        /// </summary>
        private static void ShowDisconnectMsg()
        {
            if (string.IsNullOrEmpty(disconnectError))
            {
                iTrace.Log("Loong", "断开成功:{0}:{1}", IP.ToString(), Port);
            }
            else
            {
                iTrace.Error("Loong", "断开失败:{0}:{1},错误信息:{2}", (IP == null) ? "IP为空" : IP.ToString(), Port, disconnectError);
            }
        }

        /// <summary>
        /// 解析断开连接回调处理器
        /// </summary>
        private static void ExeDisconnectCb()
        {
            if (!disconnectThenConnect)
            {
                CloseProgress();
                disconnectThenConnect = false;
            }
            ShowDisconnectMsg();
            var err = disconnectError;
            disconnectError = null;
            if (disconnectCb != null) disconnectCb(err);
            EventMgr.Trigger("DisConnectSuccess");
            disconnectCb = null;
        }

        /// <summary>
        /// 连接完成回调
        /// </summary>
        /// <param name="ar"></param>
        private static void ConnectCb(IAsyncResult ar)
        {
            Socket sk = ar.AsyncState as Socket;
            try
            {
                sk.EndConnect(ar);
                if (sk.Connected)
                {
                    state = NetworkConnectState.ConnectSuccess;
                    send.skt = socket; send.Connect();
                    receive.skt = socket; receive.Connect();
                }
            }
            catch (Exception e)
            {
                connectError = e.Message;
                state = NetworkConnectState.ConnectFailed;
            }
        }


        /// <summary>
        /// 设置IP地址和端口
        /// </summary>
        /// <param name="ipStr">地址字符</param>
        /// <param name="port">端口</param>
        /// <returns></returns>
        private static bool SetIP(string ipStr, int port)
        {
            if (!IPAddress.TryParse(ipStr, out ip))
            {
                connectError = Lang.Instance.GetDes(620004);
                connectError = string.Format(connectError, ipStr);
                return false;
            }
            NetworkClient.port = port;
            return true;
        }

        /// <summary>
        /// 断开连接后再连接
        /// </summary>
        /// <param name="error"></param>
        private static void DisconnectThenConnect(string error)
        {
            disconnectThenConnect = true;
            if (string.IsNullOrEmpty(error))
            {
                DirectConnect();
            }
        }

        /// <summary>
        /// 直接连接
        /// </summary>
        private static void DirectConnect()
        {
            try
            {
                state = NetworkConnectState.Connecting;

                socket.BeginConnect(ip, port, new AsyncCallback(ConnectCb), socket);
            }
            catch (Exception e)
            {
                connectError = e.Message;
                state = NetworkConnectState.ConnectFailed;
            }
        }

        private static void SetProMsg(uint id)
        {
            if (iProgress == null) return;
            var msg = Lang.Instance.GetDes(690004);
            iProgress.SetMessage(msg);
        }


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Update()
        {
            switch (state)
            {
                case NetworkConnectState.None:
                    send.Update();
                    receive.Update();
                    break;
                case NetworkConnectState.Connecting:
                    break;
                case NetworkConnectState.ConnectFailed:
                case NetworkConnectState.ConnectSuccess:
                    ExecuteConnectCallback(); state = NetworkConnectState.None;
                    break;
                case NetworkConnectState.DisconnectFailed:
                case NetworkConnectState.DisconnectSuccess:
                    if (!receive.Running)
                    {
                        ExeDisconnectCb(); state = NetworkConnectState.None;
                    }
                    break;
                default:
                    break;
            }

        }

        /// <summary>
        /// 发送协议
        /// </summary>
        /// <typeparam name="T">协议类型</typeparam>
        /// <param name="t">协议实例</param>
        public static void Send<T>(T t) where T : class, IExtensible
        {
            if (t == null) return;
            if (socket == null) return;
            try
            {
                byte[] bytes = ProtobufTool.Serialize<T>(t);
                ushort id = (ushort)ProtoMgr.Get<T>();
                Send(id, bytes);
                ReflectionTool.ListPropClear(t);
                ObjPool.Instance.Add(t);
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", string.Format("发送协议错误:{0}", e.Message));
            }
        }

        /// <summary>
        /// 发送协议
        /// </summary>
        /// <param name="id">协议id</param>
        /// <param name="bytes">协议数据</param>
        public static void Send(ushort id, byte[] bytes)
        {
            if (disableSend) return;
            if (socket == null) return;
            if (bytes == null) return;
            CheckMemory();
            ms.SetLength(0);
            ms.Position = 0;
            var len = (UInt32)bytes.Length;
            len += 2;
            bw.Write(len);
            bw.Write(id);
            bw.Write(bytes);
            byte[] full = ms.ToArray();
            ByteUtil.Swap(full, 0, 3);
            ByteUtil.Swap(full, 1, 2);
            ByteUtil.Swap(full, 4, 5);
            send.Send(full);
        }

        /// <summary>
        /// 连接
        /// </summary>
        /// <param name="ipStr">地址</param>
        /// <param name="port">端口</param>
        /// <param name="callback">连接回调 参数为空:成功,反之:失败</param>
        /// <param name="progress">进度接口</param>
        public static void Connect(string ipStr, int port, Action<string> callback, IProgress progress, System.Net.Sockets.AddressFamily af)
        {
            if (state != NetworkConnectState.None) return;
            OpenProgress(progress);
            connectCallback = callback;
            connectError = CheckConnect(ipStr);
            if (!string.IsNullOrEmpty(connectError))
            {
                state = NetworkConnectState.ConnectFailed; return;
            }
            CheckSocket(af);
            if (socket.Connected)
            {
                string oldIPStr = ip.ToString();
                if (oldIPStr == ipStr)
                {
                    state = NetworkConnectState.ConnectSuccess;
                }
                else
                {
                    if (SetIP(ipStr, port))
                    {
                        Disconnect();
                        DisconnectThenConnect(disconnectError);
                    }
                    else
                    {
                        state = NetworkConnectState.ConnectFailed;
                    }
                }
            }
            else
            {
                if (SetIP(ipStr, port)) DirectConnect();
                else state = NetworkConnectState.ConnectFailed;
            }
        }

        /// <summary>
        /// 断开连接
        /// </summary>
        public static void Disconnect()
        {
            if (socket == null) return;
            if (state != NetworkConnectState.None) return;
            state = NetworkConnectState.Disconnecting;
            send.Dispose();
            receive.Dispose();
            while (!ThreadPool.QueueUserWorkItem(DisconnectAsync))
            {
                Thread.Sleep(10);
            }
        }

        private static void DisconnectAsync(object o)
        {
            try
            {

                if (socket.Connected)
                {
                    socket.Shutdown(SocketShutdown.Both);
                }
                socket.Close();
                state = NetworkConnectState.DisconnectSuccess;
                disconnectError = null;
            }
            catch (Exception e)
            {
                disconnectError = e.Message;
                state = NetworkConnectState.DisconnectFailed;
            }
            finally
            {
                socket = null;
            }
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            Disconnect();
        }
        #endregion
    }
}