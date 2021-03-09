using UnityEngine;
using System.Collections;
namespace CloudVoiceIM
{
    public class ImRecordVolumeNotify : CloudVoiceMsgBase
    {
        public string v_ext;//扩展字段
        public int v_volume;//音量（1-100）
        public ImRecordVolumeNotify(object Parser)
        {
            uint parser = (uint)Parser;
            v_ext = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 1, 0));
            v_volume = CloudVoiceImInterface.parser_get_integer(parser, 2, 0);
            CloudVoiceLogPrint.DebugLog("ImRecordVolumeNotify", string.Format("v_ext:{0},v_volume:{1}", v_ext, v_volume));
            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_RECORD_VOLUME_NOTIFY, this));
        }
        
    }
}
