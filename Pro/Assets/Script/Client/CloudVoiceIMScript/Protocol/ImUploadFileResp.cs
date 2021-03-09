using UnityEngine;
using System.Collections;
namespace CloudVoiceIM
{
    public class ImUploadFileResp : CloudVoiceMsgBase
    {
        public int result;
        public string msg;
        public string fileid;
        public string fileurl;
        public int percent;
        public ImUploadFileResp(object Parser)
        {
            uint parser = (uint)Parser;
            result = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
            fileid = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 3, 0));
            fileurl = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 4, 0));
            percent = CloudVoiceImInterface.parser_get_integer(parser, 5, 0);

            //YunVaImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_UPLOAD_FILE_RESP, this));

			if(((result==0)&&(percent==100))||(result!=0))
			{
                CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_UPLOAD_FILE_RESP, this));
                CloudVoiceLogPrint.DebugLog("ImUploadFileResp", string.Format("result:{0},msg:{1},fileid:{2},fileurl:{3},percent:{4}", result, msg, fileid, fileurl, percent));
			}
        }
    }
}
