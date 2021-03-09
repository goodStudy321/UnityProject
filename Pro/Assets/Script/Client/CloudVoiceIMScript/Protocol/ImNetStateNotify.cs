using UnityEngine;
using System;
using System.Collections;
namespace CloudVoiceIM
{
    public class ImNetStateNotify : CloudVoiceMsgBase
    {
        public Net netState;
        public ImNetStateNotify(object Parser)
        {
            uint parser = (uint)Parser;
            netState = (Net)CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            CloudVoiceLogPrint.DebugLog("ImNetStateNotify", string.Format("netState:{0}", netState));
            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_NET_STATE_NOTIFY, this));
        }
    }
}
