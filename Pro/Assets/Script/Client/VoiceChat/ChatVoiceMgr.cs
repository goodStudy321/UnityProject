using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using CloudVoiceIM;
using Loong.Game;
using System.Threading;

public enum VoiceType
{
    FEELMALE=3, //情感男声
    FEELFEMALE=4 //情感女声
}

public static class ChatVoiceMgr
{
    //应用编号
    private const uint appId = 1003138;

    //播放本地语音路径
    private static string recordPath = string.Empty;

    //返回录音url地址
    private static string recordUrlPath = string.Empty;
    //识别得语音
    private static string msg = string.Empty;

    public static void Init()
    {
        int init = CloudVoiceImSDK.instance.Init(0, appId, Application.persistentDataPath, false);
        if (init == 0)
        {
            iTrace.dLog("xiaoyu", "初始化成功。。。");
        }
        else
        {
            iTrace.dError("xiaoyu", "初始化失败。。。");
        }
        EventMgr.Trigger(EventKey.VoiceLogin, init);
        EventMgr.Add(EventKey.Logout, LogOut);
    }

    public static void Login(string rName,long rId)
    {
        string ttFormat = "{{\"nickname\":\"{0}\",\"uid\":\"{1}\"}}";
        string tt = string.Format(ttFormat, rName, rId);
        string[] wildcard = new string[2];
        wildcard[0] = "0x001";
        wildcard[1] = "0x002";
        iTrace.dLog("xiaoyu", string.Format("请求登陆  UID: "+ rId));
        CloudVoiceImSDK.instance.Login(tt, "1", wildcard, 0, ImThirdLoginResp);
    }

    private static void ImThirdLoginResp(ImThirdLoginResp data)
    {
        iTrace.dLog("xiaoyu", "ImThirdLoginResp 是否在主线程：" + ThreadUtil.IsMain.ToString());
        if (data.result == 0)
        {
            iTrace.dLog("xiaoyu", string.Format("登录成功，昵称:{0},用户ID:{1}", data.nickName, data.userId));
        }
        else
        {
            iTrace.dError("xiaoyu", data.result + string.Format("登录失败，错误消息：{0}   用户ID：{1}", data.msg, data.userId));
        }
    }

    /// <summary>
    /// 登出
    /// </summary>
    public static void LogOut(params object[] args)
    {
        CloudVoiceImSDK.instance.LogOut();
    }

    /// <summary>
    /// 开始录音
    /// </summary>
    public static void RecordStartRequest()
    {
        ////录音文件保存路径(.amr)
        string filePath = string.Format("{0}/{1}.amr", Application.persistentDataPath, DateTime.Now.ToFileTime());
        iTrace.dLog("xiaoyu", "开始录音 文件保存路径： " + filePath);
        CloudVoiceImSDK.instance.RecordStartRequest(filePath, 1);
    }

    /// <summary>
    /// 结束录音
    /// </summary>
    private static uint time = 0;

    public static void RecordStopRequest()
    {
        CloudVoiceImSDK.instance.RecordStopRequest(ImRecordStopResp, ImUploadFileResp, ImSpeechStopResp);     
    }

    private static void ImRecordStopResp(ImRecordStopResp arg)
    {
        recordPath = arg.strfilepath;
        time = arg.time;
    }

    private static void ImUploadFileResp(ImUploadFileResp data)
    {
        if (data.result == 0)
        {
            recordUrlPath = data.fileurl;
            iTrace.dLog("xiaoyu", "上传成功:" + recordUrlPath);
        }
        else
        {
            iTrace.dError("xiaoyu", "上传失败");
        }
    }

    private static void ImSpeechStopResp(ImSpeechStopResp arg)
    {
        string labelText = "";
        if (arg.result == 0)
        {
            labelText = "识别成功，识别内容:" + arg.text;
            iTrace.dLog("xiaoyu", labelText);
            msg = arg.text;
        }
        else
        {
            labelText = "识别失败，原因:" + arg.msg;
            iTrace.dError("xiaoyu", labelText);
            UITip.LocalLog(690017);
            msg = "";
        }
        EventMgr.Trigger("RecordStopRequest", time, recordPath, recordUrlPath, msg);
    }

    /// <summary>
    /// 播放语音文件
    /// </summary>
    public static void RecordStartPlayRequest(string rPath)
    {
        string ext = DateTime.Now.ToFileTime().ToString();
        CloudVoiceImSDK.instance.RecordStartPlayRequest("", rPath, ext, ImRecordFinishPlayResp);
    }

    private static void ImRecordFinishPlayResp(ImRecordFinishPlayResp data)
    {
        if (data.result == 0)
        {
            iTrace.dLog("xiaoyu", "播放成功");
        }
        else
        {
            iTrace.dError("xiaoyu", "播放失败");
        }
    }

    /// <summary>
    /// 停止播放语音
    /// </summary>
    public static void RecordStopPlayRequest()
    {
        CloudVoiceImSDK.instance.RecordStopPlayRequest();
    }

    ///// <summary>
    ///// 进行语音识别
    ///// </summary>
    //public static void SpeechStartRequest()
    //{
    //    string ext = DateTime.Now.ToFileTime().ToString();
    //    CloudVoiceImSDK.instance.SpeechStartRequest(recordPath, ext, ImSpeechStopResp);
    //}

    /// <summary>
    /// 上传语音文件
    /// </summary>
    public static void UploadFileRequest(string mrecordPath)
    {
        string fileId = DateTime.Now.ToFileTime().ToString();
        CloudVoiceImSDK.instance.UploadFileRequest(mrecordPath, fileId, ImUploadFileResp);
    }

    ///// <summary>
    ///// 下载语音文件
    ///// </summary>
    //public static void DownLoadFileRequest()
    //{
    //    string DownLoadfilePath = string.Format("{0}/{1}.amr", Application.persistentDataPath, DateTime.Now.ToFileTime()); ; //文件路径
    //    string fileid = DateTime.Now.ToFileTime().ToString(); //文件ID
    //    CloudVoiceImSDK.instance.DownLoadFileRequest(recordUrlPath, DownLoadfilePath, fileid, (data4) =>
    //    {
    //        if (data4.result == 0)
    //        {
    //            iTrace.Log("xiaoyu", "下载成功:" + data4.filename);
    //            //播放语音文件
    //            RecordStartPlayRequest();
    //        }
    //        else
    //        {
    //            iTrace.Error("xiaoyu", "下载失败");
    //        }
    //    });
    //}

    /// <summary>
    /// 文字转语音
    /// </summary>
    public static void TextToVoiceRequest(string text, int targetType)
    {
        CloudVoiceImSDK.instance.TextToVoiceRequest(text, targetType, 1, "ext", ImTextToVoiceResp);
    }

    private static void ImTextToVoiceResp(ImTextToVoiceResp data)
    {
        string labelText = "";
        if (data.result == 0)
        {
            labelText = "文字转语音成功:" + data.content;
            iTrace.dLog("xiaoyu", labelText);
            CloudVoiceImSDK.instance.RecordStartPlayRequest("", data.content, "ext", ImRecordFinishPlayResp);
        }
        else
        {
            labelText = "文字转语音成功失败：" + data.msg + "-" + data.result;
            iTrace.dError("xiaoyu", labelText);
        }
    }

}
