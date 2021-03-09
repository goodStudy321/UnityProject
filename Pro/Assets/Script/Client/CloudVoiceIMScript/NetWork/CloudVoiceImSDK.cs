using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using CloudVoiceIM;
namespace CloudVoiceIM
{
    public class CloudVoiceImSDK : MonoSingleton<CloudVoiceImSDK>
    {
        #region 事件监听
        public override void Init() 
        {
            DontDestroyOnLoad(this);

            #region IM_LOGIN
            EventListenerManager.AddListener(ProtocolEnum.IM_THIRD_LOGIN_RESP, CPLoginResponse);
            #endregion

            #region IM_TOOL
            EventListenerManager.AddListener(ProtocolEnum.IM_RECORD_STOP_RESP, RecordStopRespInfo);
            EventListenerManager.AddListener(ProtocolEnum.IM_RECORD_FINISHPLAY_RESP, RecordFinishPlayRespInfo);
            EventListenerManager.AddListener(ProtocolEnum.IM_SPEECH_STOP_RESP, RecordRecognizeRespInfo);
            EventListenerManager.AddListener(ProtocolEnum.IM_UPLOAD_FILE_RESP, UploadFileRespInfo);
            EventListenerManager.AddListener(ProtocolEnum.IM_DOWNLOAD_FILE_RESP, DownLoadFileRespInfo);
            EventListenerManager.AddListener(ProtocolEnum.IM_TEXT_TO_VOICE_RESP, TextToVoiceResp);
            #endregion
        }
        #endregion
        #region 初始化SDK
        /// <summary>
        /// 初始化
        /// </summary>
		/// <returns>返回 0表示成功，-1表示失败 .</returns>
		/// <param name="context">回调上下文.</param>
        /// <param name="appid">Appid.</param>
		/// <param name="path">保存数据库文件，提供路径.</param>
		/// <param name="isTest">If set to <c>是否为测试环境，true为测试环境</c> is test.</param>
        public int Init(uint context, uint appid, string path, bool isTest)
        {
            CloudVoiceLogPrint.DebugLog("Init", string.Format("context:{0},appid:{1},path:{2},isTest:{3}", context, appid, path, isTest));
            return CloudVoiceImInterface.instance.InitSDK(context, appid, path, isTest);
		}
        #endregion

        #region 登录
        public  System.Action  ActionReLoginSuccess;
       
        private  System.Action<ImThirdLoginResp>  ActionLoginResponse;
        
        /// <summary>
        /// 登录（第三方登录方式）CP接入推荐用这种方式
        /// </summary>
        /// <param name="tt"></param>
        /// <param name="gameServerID">服务器ID</param>
        /// <param name="wildCard"></param>
        /// <param name="readStatus"></param>
        /// <param name="Response"></param>   
       
        public void Login(string tt, string gameServerID, string[] wildCard, int readStatus,  System.Action<ImThirdLoginResp> Response)
        {
            CloudVoiceLogPrint.DebugLog("Login", string.Format("tt:{0},gameServerID:{1},readStatus:{2},1", tt, gameServerID, readStatus));
             ActionLoginResponse = Response;

             uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
             CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, tt);
             CloudVoiceImInterface.instance.CVparser_set_string(parser, 2, gameServerID);            
            for (int i = 0; i < wildCard.Length;i++ )
            {
                CloudVoiceLogPrint.DebugLog("YunVaOnLogin", string.Format("wildCard-{0}:{1}", i, wildCard[i]));
                CloudVoiceImInterface.instance.CVparser_set_string(parser, 3, wildCard[i]);
            }
            CloudVoiceImInterface.instance.CVparser_set_uint8(parser, 4, readStatus);
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_LOGIN, (uint)ProtocolEnum.IM_THIRD_LOGIN_REQ, parser);           
        }

        /// <summary>
        /// 登出帐号
        /// </summary>
        public void LogOut()
        {
            CloudVoiceLogPrint.DebugLog("LogOut", "LogOut...");
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_LOGIN, (uint)ProtocolEnum.IM_LOGOUT_REQ, parser);
        }
     
        private void CPLoginResponse(object data)
        {
           
            if (data is ImThirdLoginResp)
            {
               
                //ImThirdLoginResp dataResp = new ImThirdLoginResp();
                if ( ActionLoginResponse != null)
                {  
                     ActionLoginResponse((ImThirdLoginResp)data);
                     ActionLoginResponse = null;
                }
            }
        }
        
        private void ReLoginNotify(object data)
        {
            if( ActionReLoginSuccess!=null)
            {
                 ActionReLoginSuccess();
            }
        }

        #endregion

        #region 工具
		public  System.Action<bool> RecordingCallBack;//录音回调
        /// <summary>
        /// 开始录音（最长60秒）
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="ext"></param>
        public int RecordStartRequest(string filePath, int speech=0, string ext = "")
        {
            CloudVoiceLogPrint.DebugLog("RecordStartRequest", string.Format("filePath:{0},speech:{1},ext:{2}", filePath, speech, ext));
			if(RecordingCallBack!=null)
				RecordingCallBack(true);
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, filePath);
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 2, ext);
            CloudVoiceImInterface.instance.CVparser_set_integer(parser, 3, speech);
            int ret = CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_RECORD_STRART_REQ, parser);
            Debug.Log("RecordStartRequest ret=" + ret);
            return ret;
        }

        private  System.Action<ImRecordStopResp>  ActionRecordStopResponse;
        /// <summary>
        /// 停止录音请求  回调返回录音文件路径名
        /// </summary>
        /// <param name="Response">返回的回调</param>
        public void RecordStopRequest(System.Action<ImRecordStopResp> StopResponse, System.Action<ImUploadFileResp> UploadResp=null,System.Action<ImSpeechStopResp> SpeechResp=null)
        {
            CloudVoiceLogPrint.DebugLog("RecordStopRequest", "RecordStopRequest...");
			if(RecordingCallBack!=null)
				RecordingCallBack(false);
            ActionRecordStopResponse = StopResponse;
            ActionUploadFileResp = UploadResp;
            ActionRecognizeResp = SpeechResp;
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_RECORD_STOP_REQ, parser);
        }

        private void RecordStopRespInfo(object data)
        {
            if (data is ImRecordStopResp)
            {
                if( ActionRecordStopResponse!=null)
                {
                     ActionRecordStopResponse((ImRecordStopResp)data);
                     ActionRecordStopResponse = null;
                }
            }
        }
        private Dictionary<string,  System.Action<ImRecordFinishPlayResp>> RecordFinishPlayRespMapping = new Dictionary<string,  System.Action<ImRecordFinishPlayResp>>();
        /// <summary>
        /// 播放录音请求
        /// </summary>
        /// <param name="url">录音的url路径</param>
        /// <param name="Response">回调方法</param>
        /// <param name="filePath">录音文件路径  （可以不必两者都传 但至少要传入一个）</param>
        /// <param name="ext">扩展标记</param>
        public int RecordStartPlayRequest(string filePath, string url, string ext,  System.Action<ImRecordFinishPlayResp> Response)
        {
            CloudVoiceLogPrint.DebugLog("RecordStartPlayRequest", string.Format("filePath:{0},url:{1},ext:{2}", filePath, url, ext));
			if(!RecordFinishPlayRespMapping.ContainsKey(ext)){
				RecordFinishPlayRespMapping.Add(ext, Response);
			}

            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
			if(!string.IsNullOrEmpty(url)){
                CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, url);
			}

			if(!string.IsNullOrEmpty(filePath)){
                CloudVoiceImInterface.instance.CVparser_set_string(parser, 2, filePath);
			}
			else{
				Debug.Log(string.Format("{0}: is url voice", url));
                CloudVoiceImInterface.instance.CVparser_set_string(parser, 2, "");
			}

            CloudVoiceImInterface.instance.CVparser_set_string(parser, 3, ext);
            return CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_RECORD_STARTPLAY_REQ, parser);
        }

        private void RecordFinishPlayRespInfo(object data)
        {
            if (data is ImRecordFinishPlayResp)
            {
                ImRecordFinishPlayResp reData = (ImRecordFinishPlayResp)data;
				string key = reData.ext;
                 System.Action<ImRecordFinishPlayResp> callback;
				if(RecordFinishPlayRespMapping.TryGetValue(key, out callback)){
					if(callback != null){
						callback(reData);
					}

					RecordFinishPlayRespMapping.Remove(key);
				}
				else{
					Debug.Log(key + ": callback not found");
				}
            }
        }

        /// <summary>
        /// 停止播放语音
        /// </summary>
        public void RecordStopPlayRequest()
        {
            CloudVoiceLogPrint.DebugLog("RecordStopPlayRequest", "RecordStopPlayRequest...");
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_RECORD_STOPPLAY_REQ, parser);
        }

        //private Dictionary<string,  System.Action<ImSpeechStopResp>> RecognizeRespMapping = new Dictionary<string,  System.Action<ImSpeechStopResp>>();
        System.Action<ImSpeechStopResp> ActionRecognizeResp;
        /// <summary>
        /// 开始语音识别
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="Response"></param>
        /// <param name="ext"></param>

        public void SpeechStartRequest(string filePath, string ext, System.Action<ImSpeechStopResp> Response, int type = (int)Speech.speech_file, string url = "")
        {
            CloudVoiceLogPrint.DebugLog("SpeechStartRequest", string.Format("filePath:{0},ext:{1},type:{2},url:{3}", filePath, ext, type, url));
			//string ext = DateTime.Now.ToFileTime().ToString();
			//RecognizeRespMapping.Add(ext, Response);
            ActionRecognizeResp = Response;
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, filePath);
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 2, ext);
            CloudVoiceImInterface.instance.CVparser_set_integer(parser, 3, type);
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 4, url);
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_SPEECH_START_REQ, parser);
        }
        private void RecordRecognizeRespInfo(object data)
        {
            if (data is ImSpeechStopResp)
            {
                if (ActionRecognizeResp != null)
                {
                    ActionRecognizeResp((ImSpeechStopResp)data);
                    ActionRecognizeResp = null;
                }
                /*
				Debug.Log("record recognize...");
                ImSpeechStopResp reData = (ImSpeechStopResp)data;
				string key = reData.ext;
                 System.Action<ImSpeechStopResp> callback;
				if(RecognizeRespMapping.TryGetValue(key, out callback)){
					if(callback != null){
						callback(reData);
					}
					RecognizeRespMapping.Remove(key);
				}
                 * */
            }
        }

        /// <summary>
        /// 设置语音识别语言
        /// </summary>
        /// <param name="langueage"></param>
        public void SpeechSetLanguage(Imspeech_language langueage = Imspeech_language.im_speech_zn, Imspeech_outlanguage outlanguage = Imspeech_outlanguage.im_speechout_simplified)
		{
            CloudVoiceLogPrint.DebugLog("SpeechSetLanguage", string.Format("langueage:{0},outlanguage:{1}", langueage, outlanguage));
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CVparser_set_integer(parser, 1, (int)langueage);
            CloudVoiceImInterface.instance.CVparser_set_integer(parser, 2, (int)outlanguage);
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_SPEECH_SETLANGUAGE_REQ, parser);
		}
        private  System.Action<ImUploadFileResp>  ActionUploadFileResp;
        /// <summary>
        /// 上传文件
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="Response"></param>
        /// <param name="fileId"></param>
		public void UploadFileRequest(string filePath,string fileId,  System.Action<ImUploadFileResp> Response)
        {
            CloudVoiceLogPrint.DebugLog("UploadFileRequest", string.Format("filePath:{0},fileId:{1}", filePath, fileId));
            ActionUploadFileResp = Response;
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, filePath);
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 2, fileId);
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_UPLOAD_FILE_REQ, parser);
        }
        private void UploadFileRespInfo(object data)
        {
            if (data is ImUploadFileResp)
            {
                if (ActionUploadFileResp != null)
                {
                     ActionUploadFileResp((ImUploadFileResp)data);
                     ActionUploadFileResp = null;
                    
                }
            }
        }

        private  System.Action<ImDownLoadFileResp>  ActionDownLoadFileResp;
        /// <summary>
        /// 下载文件请求
        /// </summary>
        /// <param name="url"></param>
        /// <param name="Response"></param>
        /// <param name="filePath"></param>
        /// <param name="fileid"></param>
        public void DownLoadFileRequest(string url, string filePath, string fileid,  System.Action<ImDownLoadFileResp> Response)
        {
            CloudVoiceLogPrint.DebugLog("DownLoadFileRequest", string.Format("url:{0},filePath:{1},fileid:{2}", url, filePath, fileid));
            ActionDownLoadFileResp = Response;
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, url);
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 2, filePath);
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 3, fileid);
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_DOWNLOAD_FILE_REQ, parser);
        }
        private void DownLoadFileRespInfo(object data)
        {
            if (data is ImDownLoadFileResp)
            {
                if( ActionDownLoadFileResp!=null)
                {
                     ActionDownLoadFileResp((ImDownLoadFileResp)data);
                     ActionDownLoadFileResp = null;
                }
            }
        }

        private System.Action<ImTextToVoiceResp> ActionTextToVoiceResp;
        /// <summary>
        /// 文字转语音
        /// </summary>
        /// <param name="url"></param>
        /// <param name="Response"></param>
        /// <param name="filePath"></param>
        /// <param name="fileid"></param>
        public void TextToVoiceRequest(string text, int targetType, int respType, string ext, System.Action<ImTextToVoiceResp> Response)
        {
            CloudVoiceLogPrint.DebugLog("TextToVoiceRequest", string.Format("text:{0},targetType:{1},respType:{2},ext:{3}", text, targetType, respType, ext));
            ActionTextToVoiceResp = Response;
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, text);
            CloudVoiceImInterface.instance.CVparser_set_integer(parser, 2, targetType);
            CloudVoiceImInterface.instance.CVparser_set_integer(parser, 3, respType);
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 4, ext);
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_TEXT_TO_VOICE_REQ, parser);
        }
        private void TextToVoiceResp(object data)
        {
            if (data is ImTextToVoiceResp)
            {
                if (ActionTextToVoiceResp != null)
                {
                    ActionTextToVoiceResp((ImTextToVoiceResp)data);
                    ActionTextToVoiceResp = null;
                }
            }
        }

        //
        /// <summary>
        /// 设置音量信息。
        /// </summary>
        /// <param name="length">声音长度</param>
        /// <param name="isVolume">true为返回音量，false不返回音量</param>
         public void RecordSetInfoReq(bool isVolume=false)
        {
            CloudVoiceLogPrint.DebugLog("RecordSetInfoReq", string.Format("isVolume:{0}", isVolume));
            RecordSetInfoReq(isVolume,600);
        }
        
        public void RecordSetInfoReq(bool isVolume,int length)
        {
            CloudVoiceLogPrint.DebugLog("RecordSetInfoReq", string.Format("isVolume:{0},length:{1}", isVolume, length));
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            if(isVolume)
            {
                CloudVoiceImInterface.instance.CVparser_set_integer(parser, 1, length);
                CloudVoiceImInterface.instance.CVparser_set_integer(parser, 2, 1);
            }
            else
            {
                CloudVoiceImInterface.instance.CVparser_set_integer(parser, 1, length);
                CloudVoiceImInterface.instance.CVparser_set_integer(parser, 2, 0);
            }
            CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_RECORD_SETINFO_REQ, parser);
        }

		public bool CheckCacheFile(string url){
            CloudVoiceLogPrint.DebugLog("CheckCacheFile", string.Format("url:{0}", url));
            uint parser = CloudVoiceImInterface.instance.CVpacket_get_parser();
            CloudVoiceImInterface.instance.CVparser_set_string(parser, 1, url);
            int ret = CloudVoiceImInterface.instance.CV_SendCmd(CmdChannel.IM_TOOLS, (uint)ProtocolEnum.IM_TOOL_HAS_CACHE_FILE, parser);
			return ret == 0;
		}
        #endregion

        /// <summary>
        /// 是否打印日志
        /// </summary>
        /// <param name="logLevel">LOG_LEVEL_OFF = 0,  //0：关闭日志,LOG_LEVEL_DEBUG = 1 //1：Debug默认该级别</param>
        public void setLogLevel(int logLevel = (int)logLevel.LOG_LEVEL_DEBUG)
        {
            CloudVoiceLogPrint.setLogLevel(logLevel);
        }
    }
}
