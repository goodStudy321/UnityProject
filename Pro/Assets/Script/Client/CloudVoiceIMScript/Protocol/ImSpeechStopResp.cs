using UnityEngine;
using System.Collections;
namespace CloudVoiceIM
{
    public class ImSpeechStopResp : CloudVoiceMsgBase
    {
        public int result;
        public string msg;
        public string text;
        public string ext;
		public string url;
        public ImSpeechStopResp(object Parser)
        {
            uint parser = (uint)Parser;
            result = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
            text = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 3, 0));
            ext = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 4, 0));
            url = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 5, 0));
            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_SPEECH_STOP_RESP, this));

            CloudVoiceLogPrint.DebugLog("ImSpeechStopResp", string.Format("result:{0},msg:{1},text:{2},ext:{3},url:{4}", result, msg, text, ext, url));
        }
    }
}
