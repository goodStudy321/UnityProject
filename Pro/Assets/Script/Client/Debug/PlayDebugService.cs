using UnityEngine;
using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

using System.Reflection;
using System.Xml.Serialization;

public interface DebugListener
{
    void OnRegister(int clientId);
}

public class PlayDebugService : DebugService
{
    //bool mSendFileMode = false;
    int mFileReviceSize = 0;
    int mFileReviceIndex = 0;
    string mReviceFileName = string.Empty;
    byte[] m_reviceByte = null;

    byte[] m_ReviceFileBuffer = null;

    DebugListener mListener = null;
    List<string> GMString = new List<string>();

    //public class TMsgData
    //{
    //    public EventEnum enumData;
    //    public object param;
    //}

    //List<TMsgData> MsgDataList = new List<TMsgData>();

    public DebugListener DebugListener
    {
        set
        {
            mListener = value;
        }
    }


    private void SendMobileDev()
    {
        byte[] devArr = new byte[1] { 1 };
        SendMsg(DebugService.MSG_REGISTER, devArr, 1);
    }

    public void SendLog(string logStr)
    {
        //         if (mSendFileMode == true)
        //             return;

        byte[] StrArray = System.Text.Encoding.ASCII.GetBytes(logStr);
        SendMsg(DebugService.MSG_LOG, StrArray, (uint)StrArray.Length);
    }

    public override void OnConnect(object param)
    {
        SendMobileDev();
        //Debug.Log("connected");
    }

    public override void OnMessage(UInt32 SerId, IntPtr buf, int reLen)
    {
        if (SerId == DebugService.MSG_REGISTER)
        {
            DeviceReq dev = (DeviceReq)Marshal.PtrToStructure(buf, typeof(DeviceReq));

            //Debug.Log(string.Format("dev id:{0}", dev.id));

            if (mListener != null)
                mListener.OnRegister((int)dev.id);
        }
        else if (SerId == DebugService.MSG_FILESTART_REQ)
        {
            byte[] str = new byte[reLen];
            DebugService.GetStartFile(buf, reLen, str, ref mFileReviceSize);

            mFileReviceIndex = 0;
            mReviceFileName = System.Text.Encoding.Default.GetString(str, 0, reLen - sizeof(UInt32));
            m_reviceByte = new byte[mFileReviceSize];

            byte[] Sendbuf = new byte[1] { 1 };
            SendMsg(DebugService.MSG_FILESTART_START, Sendbuf, 1);

            //mSendFileMode = true;
        }
        else if (SerId == DebugService.MSG_FILE_TRUNK)
        {
            Marshal.Copy(buf, m_reviceByte, mFileReviceIndex, reLen);

            mFileReviceIndex += reLen;
            mFileReviceSize -= reLen;

            if (mFileReviceSize <= 0)
            {
                m_ReviceFileBuffer = m_reviceByte;
                m_reviceByte = null;
            }
            else
            {
                SendMsg(DebugService.MSG_FILE_TRUNK, null, 0);
            }
        }
        else if (SerId == DebugService.MSG_GM)
        {
            string cmd = Marshal.PtrToStringAnsi(buf, reLen); //System.Text.Encoding.Default.GetString(str, 0, reLen);
            GMString.Add(cmd);
        }

        if (SerId >= DebugService.MSG_SEND_MESSAGE)
        {
            //unsafe
            //{
            //    byte* memBytePtr = (byte*)buf.ToPointer();

            //    uint iEnumData = SerId - DebugService.MSG_SEND_MESSAGE;
            //    Type dataType = null;
            //    foreach (EventEnum item in Enum.GetValues(typeof(EventEnum)))
            //    {
            //        if ((uint)item == iEnumData)
            //        {
            //            dataType = GetTypeByName(item.ToString() + "Data");
            //            break;
            //        }
            //    }

            //    if (dataType == null)
            //    {
            //        MsgDataList.Add(new TMsgData() { enumData = (EventEnum)iEnumData, param = null });
            //        //MessageManager.instance.SendMessage((EventEnum)iEnumData, null, null);
            //    }
            //    else
            //    {
            //        UnmanagedMemoryStream stream = new UnmanagedMemoryStream(memBytePtr, reLen);
            //        XmlSerializer xmlSer = new XmlSerializer(dataType);
            //        object MsgObj = xmlSer.Deserialize(stream);

            //        MsgDataList.Add(new TMsgData() { enumData = (EventEnum)iEnumData, param = MsgObj });
            //        //MessageManager.instance.SendMessage((EventEnum)iEnumData, MsgObj, null);

            //        stream.Close();
            //    }
            //}
        }
    }

    public Type GetTypeByName(string typeName)
    {
        Assembly[] referencedAssemblies = System.AppDomain.CurrentDomain.GetAssemblies();
        for (int assIdx = 0; assIdx < referencedAssemblies.Length; assIdx++)
        {
            Type[] tys = referencedAssemblies[assIdx].GetTypes();
            int len = tys.Length;
            for (int i = 0; i < len; i++)
            {
                Type baseT = tys[i];
                for (; baseT != null; baseT = baseT.BaseType)
                {
                    if (baseT.Name == typeName)
                        return tys[i];
                }
            }
        }

        return null;
    }

    public void Update()
    {
        if (mService == null)
            return;

        if (m_ReviceFileBuffer != null)
        {
            string path = Application.persistentDataPath + "/" + mReviceFileName.ToLower();
            File.WriteAllBytes(path, m_ReviceFileBuffer);

            m_reviceByte = null;

            Debug.Log(string.Format("save file to:{0}", path));

            string filename = Path.GetFileNameWithoutExtension(path);
            int iInc = PlayerPrefs.GetInt(filename);
            PlayerPrefs.SetInt(filename, iInc++);

            byte[] Sendbuf = new byte[1] { 1 };
            SendMsg(DebugService.MSG_FILE_END, Sendbuf, 1);

            m_ReviceFileBuffer = null;
        }

        //if (GMString.Count > 0)
        //{
        //    try
        //    {
        //        for (int i = 0; i < GMString.Count; i++)
        //        {
        //            GMCommand.instance.TryParse(GMString[i]);
        //        }
        //    }
        //    catch (System.Exception ex)
        //    {

        //    }

        //    GMString.Clear();
        //}

        //if (MsgDataList.Count > 0)
        //{
        //    for (int i = 0, c = MsgDataList.Count; i < c; i++)
        //    {
        //        Debug.Log(string.Format("{0} {1}", MsgDataList[i].enumData.ToString(), MsgDataList[i].param.ToString()));
        //        MessageManager.instance.SendMessage(MsgDataList[i].enumData, MsgDataList[i].param, null);
        //    }

        //    MsgDataList.Clear();
        //}
    }

    //     public override bool OnParseCallback(byte[] data, int size)
    //     {
    //         if (mSendFileMode)
    //         {
    //             Array.Copy(data, 0, m_reviceByte, mFileReviceIndex, size);
    //             mFileReviceSize -= size;
    //             mFileReviceIndex += size;
    // 
    //             return true;
    //         }
    // 
    //         return false;
    //    }
}
