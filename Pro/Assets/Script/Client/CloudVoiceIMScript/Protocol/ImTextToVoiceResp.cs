using UnityEngine;
using System.Collections;
namespace CloudVoiceIM
{
    public class ImTextToVoiceResp : CloudVoiceMsgBase
    {
        public int result;
        public string msg;
        public string content;
        public string ext;
        public ImTextToVoiceResp(object Parser)
        {
            uint parser = (uint)Parser;
            result = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
            content = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 3, 0));
            ext = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 4, 0));
            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_TEXT_TO_VOICE_RESP, this));
            CloudVoiceLogPrint.DebugLog("ImTextToVoiceResp", string.Format("result:{0},msg:{1},content:{2},ext:{3}", result, msg, content, ext));
        }
    }
}
