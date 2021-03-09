using UnityEngine;
using System.Collections;
using CloudVoiceIM;
namespace CloudVoiceIM
{
    public class ImGetThirdBindInfoResp : CloudVoiceMsgBase
    {
        public int result;
        public string msg;
        public int CVId;
        public string nickName;
        public string iconUrl;
        public string level;
        public string vip;
        public string ext;
        public ImGetThirdBindInfoResp(object Parser)
        {
            uint parser =(uint)Parser;
            result = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
            CVId = CloudVoiceImInterface.parser_get_integer(parser, 3, 0);
            nickName = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 4, 0));
            iconUrl = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 5, 0));
            level = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 6, 0));
            vip = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 7, 0));
            ext = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 8, 0));
            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_GET_THIRDBINDINFO_RESP, this));

            CloudVoiceLogPrint.DebugLog("ImGetThirdBindInfoResp", string.Format("result:{0},msg:{1},CVId:{2},nickName:{3},iconUrl:{4},level,{5},vip:{6},ext:{7}", result, msg, CVId, nickName, iconUrl, level, vip, ext));
        }
    }
}
