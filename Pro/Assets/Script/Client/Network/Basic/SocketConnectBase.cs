using System;
using System.Net;
using System.Net.Sockets;
using System.Collections.Generic;

namespace Loong.Game
{

    using Lang = Phantom.Localization;
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:套接字连接基类
    /// </summary>
    public class SocketConnectBase
    {
        #region 字段

        private int port = 0;

        private IPAddress ip = null;

        /// <summary>
        /// 进度
        /// </summary>
        private IProgress iProgress = null;

        /// <summary>
        /// 连接错误信息
        /// </summary>
        private string connectError = null;

        /// <summary>
        /// 断开连接错误信息
        /// </summary>
        private string disconnectError = null;

        /// <summary>
        /// 连接回调 参数为空:成功,反之:失败
        /// </summary>
        private Action<string> connectCallback = null;

        /// <summary>
        /// 断开连接回调 参数为空:成功,反之:失败
        /// </summary>
        private Action<string> disconnectCallback = null;

        /// <summary>
        /// 套接字
        /// </summary>
        private Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);


        #endregion

        #region 属性
        /// <summary>
        /// 端口
        /// </summary>
        public int Port
        {
            get { return port; }
            set { port = value; }
        }

        /// <summary>
        /// IP地址
        /// </summary>
        public IPAddress IP
        {
            get { return ip; }
            set { ip = value; }
        }


        #endregion

        #region 构造方法
        public SocketConnectBase()
        {

        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 检查是否可以连接
        /// </summary>
        /// <returns>错误信息</returns>
        private string CheckConnect(string ip)
        {
            if (string.IsNullOrEmpty(ip)) return Lang.Instance.GetDes(620000);
            if (socket == null) return null;
            if (socket.Connected) return Lang.Instance.GetDes(620001);
            return null;
        }

        /// <summary>
        /// 检查是否可以断开连接
        /// </summary>
        /// <returns></returns>
        private string CheckDisconnect()
        {
            if (socket == null) return Lang.Instance.GetDes(620002);
            if (!socket.Connected) return Lang.Instance.GetDes(620003);
            return null;
        }

        /// <summary>
        /// 解析连接回调处理器
        /// </summary>
        private void ExecuteConnectCallback()
        {
            if (iProgress != null) iProgress.Close();
            if (connectCallback == null) return;
            connectCallback(connectError);
            connectCallback = null;
        }


        /// <summary>
        /// 解析断开连接回调处理器
        /// </summary>
        private void ExecuteDisconnectCallback()
        {
            if (iProgress != null) iProgress.Close();
            if (disconnectCallback == null) return;
            disconnectCallback(disconnectError);
            disconnectCallback = null;
        }

        /// <summary>
        /// 连接完成回调
        /// </summary>
        /// <param name="ar"></param>
        private void BeginConnectCallback(IAsyncResult ar)
        {
            Socket sk = ar as Socket;
            sk.EndConnect(ar);
            if (!sk.Connected) connectError = Lang.Instance.GetDes(620005);
            ExecuteConnectCallback();
        }


        /// <summary>
        /// 断开连接完成回调
        /// </summary>
        /// <param name="ar"></param>
        private void BeginDisconnectCallback(IAsyncResult ar)
        {
            Socket sk = ar as Socket;
            sk.EndDisconnect(ar);
            sk.Close();
            if (sk.Connected) disconnectError = Lang.Instance.GetDes(620006);
            ExecuteDisconnectCallback();
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 连接
        /// </summary>
        /// <param name="ipStr">地址</param>
        /// <param name="port">端口</param>
        /// <param name="callback">连接回调 参数为空:成功,反之:失败</param>
        /// <param name="progress">进度接口</param>
        public void Connect(string ipStr, int port, Action<string> callback, IProgress progress)
        {
            iProgress = progress;
            connectCallback = callback;
            connectError = CheckConnect(ipStr);
            if (!string.IsNullOrEmpty(connectError))
            {
                ExecuteConnectCallback(); return;
            }
            if (!IPAddress.TryParse(ipStr, out ip))
            {
                connectError = Lang.Instance.GetDes(620004);
                connectError = string.Format(connectError, ipStr);
                ExecuteConnectCallback(); return;
            }
            try
            {
                socket.BeginConnect(ip, port, new AsyncCallback(BeginConnectCallback), socket);
            }
            catch (Exception e)
            {
                connectError = e.Message;
                ExecuteConnectCallback();
            }

        }

        /// <summary>
        /// 断开连接
        /// </summary>
        /// <param name="callback">断开回调 参数为空:成功,反之:失败</param>
        /// <param name="progress">进度接口</param>
        public void Disconnect(Action<string> callback, IProgress progress)
        {
            iProgress = progress;
            disconnectCallback = callback;
            disconnectError = CheckDisconnect();
            if (!string.IsNullOrEmpty(disconnectError))
            {
                ExecuteDisconnectCallback(); return;
            }
            try
            {
                socket.Shutdown(SocketShutdown.Both);
                socket.BeginDisconnect(true, new AsyncCallback(BeginDisconnectCallback), socket);
            }
            catch (Exception e)
            {
                disconnectError = e.Message;
                ExecuteDisconnectCallback();
            }
        }

        #endregion
    }
}