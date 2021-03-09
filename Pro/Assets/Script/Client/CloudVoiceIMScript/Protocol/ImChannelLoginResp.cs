using UnityEngine;
using System.Collections;
using System.Collections.Generic;
namespace CloudVoiceIM
{
    public class ImChannelLoginResp : CloudVoiceMsgBase
    {
        public int result;
        public string msg;
        public List<string> wildCard;
        public string announcement;
        public ImChannelLoginResp(object Parser)
        {
            uint parser=(uint)Parser;
            
            wildCard=new List<string>();
            result = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
            announcement = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 4, 0));
            for (int i = 0; ; i++)
            {
                if (CloudVoiceImInterface.parser_is_empty(parser, 3, i))
                    break;

                wildCard.Add(CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 3, i)));
                CloudVoiceLogPrint.DebugLog("ImChannelLoginResp", string.Format("wildCard:{0}", wildCard[i]));
            }

            CloudVoiceLogPrint.DebugLog("ImChannelLoginResp", string.Format("result:{0},msg:{1},announcement:{2}", result, msg, announcement));

            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_CHANNEL_LOGIN_RESP, this));
        }
        
    }
}
