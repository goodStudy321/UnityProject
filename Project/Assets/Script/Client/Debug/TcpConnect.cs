using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
//using LitJson;
using System.Collections.Generic;

using UnityEngine;
using Hello.Game;


public class TcpConnect : Connection
{
    private Socket m_socket = null;
    private IAsyncResult m_recv = null;
    private IAsyncResult m_connect = null;
    private State m_state = State.Initialized;

    private AsyncCallback mAsynCallback = null;

    private int m_id = 0;

    public static int ms_id = 0;

    public enum State
    {
        Initialized,
        Connected,
        ConnectFailed,
        DisconTimeout,
        DisconRecvErr1,
        DisconRecvErr2,
        DisconSendErr1,
        DisconSendErr2,
        Close,
    }

    public TcpConnect(Handle handle)
        : base(handle)
    {
        m_id = ms_id++;
    }

    public State state
    {
        get { return m_state; }
    }

    private void Reset()
    {
        m_total_recv_length = 0;
        m_total_send_length = 0;
        m_state = State.Initialized;
    }

    public override void Break()
    {
        if (m_socket != null)
        {
            if (m_socket.Connected)
            {
#if UNITY_IPHONE
#else
                m_socket.Shutdown(SocketShutdown.Both);
#endif
                m_socket.Close();
            }

            m_socket = null;
        }
    }

    public override bool Connect(string hostname, int port, bool last)
    {

        if (m_connect != null)
            return true;
        try
        {
            Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            m_socket = socket;
            if (socket == null)
                throw (new Exception("无法建立Socket连接"));

            //Utility.PrintLog(string.Format("begin socket connect ip={0}  port = {1}",hostname,port));

            m_connect = socket.BeginConnect(hostname, port, new AsyncCallback(OnConnect), socket);

            return true;
        }
        catch (Exception exception)
        {
            SocketException socketException = exception as SocketException;
            if (socketException != null)
            {
                //Utility.PrintLog(string.Format("Tcp Connection Ip={0} Port={1} Code={3} Exception={2}", hostname, port, exception, socketException.ErrorCode));
            }
            else
            {
                //Utility.PrintLog(string.Format("Tcp Connection Ip={0} Port={1} Exception={2}", hostname, port, exception));
            }
            m_state = State.ConnectFailed;
            CloseAndJoin();
            //FloatWindow.PlayFloat(1000003);
            //OnConnectedFailed();
            //connectfaildList.Add(State.DisconSendErr1);
        }

        return false;
    }

    public override void Close()
    {
        m_state = State.Close;
        CloseAndJoin();
    }

    private void Disconnect(State state = State.Close)
    {
        if (m_state <= State.Connected)
        {
            m_state = state;
            CloseAndJoin();
            OnDisconnected(m_state);
        }
    }

    public void OnConnect(IAsyncResult ar)
    {
        //if (m_connected != null)
        //    m_connected(true);
        bool flag = ar.AsyncWaitHandle.WaitOne(50000, false);
        m_connect.AsyncWaitHandle.Close();
        if (!flag)
        {
            if (m_socket != null)
            {
                if (m_socket.Connected)
                {
#if UNITY_IPHONE
#else
                    m_socket.Shutdown(SocketShutdown.Both);
#endif
                }

                m_socket.Close();
            }

            OnConnectedFailed();
            //             if (!last)
            //             {
            //                 OnConnectedFailed();
            //                 //return false;
            //             }
            //             else
            //             {
            //                 throw (new Exception("Wait failed"));
            //             }
        }

#if UNITY_EDITOR
        //             if (Global.mainMono.SIMULATE_TCP_DISCONNECT)
        //             {
        //                 OnConnectedFailed();
        //                 return false;
        //             }
#endif

        //m_connect.AsyncWaitHandle.Close();
        Socket async_state = (Socket)m_connect.AsyncState;
        async_state.EndConnect(m_connect);
        m_connect = null;

        //async_state.Blocking = false;

        Reset();
        if (m_socket != null)
        {
            //socket.Blocking = true;
            //socket.ReceiveTimeout = 6000;
            //socket.SendTimeout = 6000;
            //socket.SendBufferSize = 0x9c40;
        }

        OnConnected();
        Debug.Log("Connect success...");
        m_state = State.Connected;
        Receive();
    }

    //bool stat = false;
    private void OnReceive(IAsyncResult ar)
    {
        try
        {
            ar.AsyncWaitHandle.Close();
            m_recv = null;
            Socket socket = (Socket)ar.AsyncState;

            if (socket == null || socket.Connected == false)
            {
                return;
            }

            //socket.Blocking = true;

            int num = socket.EndReceive(ar);
            if (num <= 0)
            {
                iTrace.Error("LY", "recv 0 bytes from peer id = " + m_id);
                //Disconnect(State.DisconRecvErr1);
                //disconnectList.Add(State.DisconRecvErr1);
                return;
            }

            handle(m_buffer, num);

            Receive();
        }
        catch //(Exception exception)
        {
            //ZLogger.Error("OnReceive exception: " + exception.ToString());
            Disconnect(State.DisconRecvErr2);
        }
    }

    private bool Receive()
    {
        try
        {
            if (mAsynCallback == null)
                mAsynCallback = new AsyncCallback(OnReceive);

            m_recv = m_socket.BeginReceive(m_buffer, 0, MAX_BUFFER_SIZE, SocketFlags.None, mAsynCallback, m_socket);
        }
        catch (InvalidOperationException)
        {
            iTrace.Error("LY", "Invalid operation recv .....");
            return false;
        }
        catch (IOException exception)
        {
            iTrace.Error("LY", "Invalid operation: " + exception.Message.ToString());
            return false;
        }

        return true;
    }

    public override bool Send(byte[] buffer, int size)
    {
        if ((m_socket == null) || !m_socket.Connected)
        {
            return false;
        }

        try
        {
            int has = 0;
            do
            {
                int ret = m_socket.Send(buffer, has, size - has, SocketFlags.None);
                has += ret;
            }
            while (has < size);

            m_total_send_length += size;
        }
        catch (Exception exception)
        {
            iTrace.Error("LY", "Send exception: " + exception.ToString() + " " + size);
            Disconnect(State.DisconSendErr1);
            return false;
        }

        return true;
    }

    private void CloseAndJoin()
    {
        try
        {
            if (m_socket != null)
            {
                if (m_socket.Connected)
                {
#if UNITY_IPHONE
#else
                    m_socket.Shutdown(SocketShutdown.Both);
#endif
                }
                m_socket.Close();
                m_socket = null;
            }
        }
        catch (Exception exception)
        {
            iTrace.Error("LY", "Close sokcet failed: " + exception.Message);
        }

        if (m_recv != null)
        {
            m_recv.AsyncWaitHandle.Close();
            m_recv = null;
        }

        if (m_connect != null)
        {
            m_connect.AsyncWaitHandle.Close();
            m_connect = null;
        }

        m_total_recv_length = 0;
        m_total_send_length = 0;
    }
}