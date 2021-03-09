using UnityEngine;
using System.Collections;
namespace CloudVoiceIM
{
    public class ImDownLoadFileResp : CloudVoiceMsgBase
    {
      	public int result;
        public string msg;
		public string filename;
		public string fileid;
        public int percent;

        public ImDownLoadFileResp(object Parser)
        {
            uint parser = (uint)Parser;
            result = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
            filename = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 3, 0));
            fileid = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 4, 0));
            percent = CloudVoiceImInterface.parser_get_integer(parser, 5, 0);

			if(((result==0)&&(percent==100))||(result!=0))
			{
                CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_DOWNLOAD_FILE_RESP, this));
                CloudVoiceLogPrint.DebugLog("ImDownLoadFileResp", string.Format("result:{0},msg:{1},filename:{2},fileid:{3},percent:{4}", result, msg, filename, fileid, percent));
			}
        }      
    }

    public class ImPlayPercentNotify : CloudVoiceMsgBase
	{
		public int percent;
		public string ext;

		public ImPlayPercentNotify(object Parser)
		{
			uint parser = (uint)Parser;
            percent = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            ext = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));

            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_RECORD_PLAY_PERCENT_NOTIFY, this));
            CloudVoiceLogPrint.DebugLog("ImPlayPercentNotify", string.Format("percent:{0},ext:{1}", percent, ext));
		}
	}
}
