using UnityEngine;
using System.Collections;
using CloudVoiceIM;
namespace CloudVoiceIM
{
    public class ImReconnectionNotify : CloudVoiceMsgBase
    {
		public int userid;
        public ImReconnectionNotify(object Parser)
        {
			uint parser = (uint)Parser;
            userid = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_RECONNECTION_NOTIFY, this));
            CloudVoiceLogPrint.DebugLog("ImReconnectionNotify", string.Format("userid:{0}", userid));
        }
    }
}
