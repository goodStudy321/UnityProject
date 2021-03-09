//using UnityEngine;
using System;
using System.Collections;
using System.Runtime.InteropServices;


[StructLayout(LayoutKind.Sequential, Pack = 1)]
public struct DeviceReq
{
    public UInt32 id;
    public byte IsMobile;
}

public class DebugService
{
    public const int MSG_REGISTER   = 0x1010;
    public const int MSG_REMOVE     = 0x1011;
    public const int MSG_SELECT     = 0x1012;
    public const int MSG_LOG        = 0x1013;

    public const int MSG_FILESTART_REQ      = 0x1014;
    public const int MSG_FILESTART_START    = 0x1015;
    public const int MSG_FILE_END           = 0x1016;
    public const int MSG_GM                 = 0x1017;
    public const int MSG_FILE_TRUNK         = 0x1018;

    public const int MSG_SEND_MESSAGE       = 0x2000;

#if UNITY_IPHONE && !UNITY_EDITOR
    public const string _DLL = "__Internal";
#else
    //public const string _DLL = "cai-nav-rcn"; DebugNetDriver
    public const string _DLL = "DebugNetDriver";
#endif

     [DllImport(_DLL)]
    public static extern void writeRecvData([In]IntPtr netHandle, [In]byte[] pData, UInt32 DataLen);

    [DllImport(_DLL)]
    public static extern bool next([In]IntPtr netHandle, [In, Out]ref UInt32 nSerialNo, [In, Out]ref UInt32 nServantName, [In, Out]ref IntPtr Body, int inputlen, [In, Out]ref int bodylen);

    [DllImport(_DLL)]
    public static extern void writeSendData([In]IntPtr netHandle, UInt32 nSerialNo, UInt32 nServantName, [In]byte[] pData, UInt32 DataLen, [In, Out]ref IntPtr retdata, UInt32 len, [In, Out]ref UInt32 retlen);

    [DllImport(_DLL, CharSet = CharSet.Ansi)]
    public static extern void CopyStringToByte(string Char, [In, Out]byte[] bytes, int len);

    [DllImport(_DLL)]
    public static extern void createNetHandle([In, Out]ref IntPtr netHandle);

    [DllImport(_DLL)]
    public static extern void reset([In]IntPtr netHandle);

    [DllImport(_DLL)]
    public static extern void GetStartFile(IntPtr pBuf, int len, byte []bytes, ref Int32 reLen);

    protected Connection mService = null;

    protected IntPtr m_Buffer;

    protected byte[] GlobalBuf = new byte[4096];

    public void Init()
    {
        if (mService != null)
        {
            mService.Close();
        }
        else
            createNetHandle(ref m_Buffer);

        mService = new TcpConnect(OnParse);
        mService.connectHandle = OnConnect;
        mService.disconnectHandle = OndisConnect;
        //mService.Connect("10.6.8.243", 5150, false);
        mService.Connect("192.168.2.145", 5150, false);

        //mService.Connect("127.0.0.1", 5150, false);
    }

    public void Disconnect()
    {
        if (mService != null)
        {
            reset(m_Buffer);
            mService.Close();
        }
    }

    public void SendMsg(uint SerId, byte []buf, uint len)
    {
        uint relen = 0;
        IntPtr writeBuf = IntPtr.Zero;
        writeSendData(m_Buffer, SerId, 1, buf, len, ref writeBuf, 4096, ref relen);

        if (GlobalBuf.Length < len)
            GlobalBuf = new byte[len];
        
        Marshal.Copy(writeBuf, GlobalBuf, 0, (int)relen);
        mService.Send(GlobalBuf, (int)relen);
    }

    public virtual void OnConnect(object param)
    {
//         DeviceReq devReq;
//         
//         devReq.id = 1001;
//         devReq.IsMobile = 1;
// 
//         IntPtr writeBuf = IntPtr.Zero;
//         uint len = 0;
// 
//         uint Size = (uint)Marshal.SizeOf(devReq);
//         byte[] ArrayPtr = new byte[Size];
//         IntPtr pnt = Marshal.AllocHGlobal((int)Size);
//         Marshal.StructureToPtr(devReq, pnt, false);
//         Marshal.Copy(pnt, ArrayPtr, 0, (int)Size);
//         Service.writeSendData(m_Buffer, 0x1010, 1, ArrayPtr, Size, ref writeBuf, 1024, ref len);
//         if (GlobalBuf.Length < len)
//             GlobalBuf = new byte[len];
// 
//         Marshal.Copy(writeBuf, GlobalBuf, 0, (int)len);
//         mService.Send(GlobalBuf, (int)len);
        

        //Debug.Log("connected");
    }

    private void OndisConnect(object param)
    {
        
    }

    public virtual void OnMessage(UInt32 SerId, IntPtr buf, int reLen)
    {

    }

    private int OnParse(byte[] data, int size)
    {
        writeRecvData(m_Buffer, data, (UInt32)size);
        bool bRe = false;
        int BufSize = 0;
        IntPtr buf = IntPtr.Zero;
        do
        {
            UInt32 nSerNo = 0;
            UInt32 nProtoId = 0;
            int nReLen = 0;

            bRe = next(m_Buffer, ref nSerNo, ref nProtoId, ref buf, BufSize, ref nReLen);

            if (bRe)
            {
                OnMessage(nSerNo, buf, nReLen);
            }
        } while (bRe == true);

        return 0;
    }
}
