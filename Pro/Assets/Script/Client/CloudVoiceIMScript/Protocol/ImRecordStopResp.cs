using UnityEngine;
using System.Collections;
namespace CloudVoiceIM
{
    public class ImRecordStopResp : CloudVoiceMsgBase
    {
        public uint time;
        public string strfilepath;
		public string ext;
		public int result;
		public string msg;
        public ImRecordStopResp(object Parser)
        {
            uint parser = (uint)Parser;

            time = CloudVoiceImInterface.parser_get_uint32(parser, 1, 0);
            strfilepath = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
            ext = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 3, 0));
            result = CloudVoiceImInterface.parser_get_integer(parser, 4, 0);
            msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 5, 0));

//			ArrayList list = new ArrayList();
//			list.Add(voiceDurationTime);
//			list.Add(filePath);

            //RecordStopResp resp = new RecordStopResp(){
            //    time = voiceDurationTime,
            //    strfilepath = filePath
            //};

            CloudVoiceImInterface.eventQueue.Enqueue(new InvokeEventClass(ProtocolEnum.IM_RECORD_STOP_RESP, this));

            CloudVoiceLogPrint.DebugLog("ImRecordStopResp", string.Format("time:{0},strfilepath:{1},ext:{2},result:{3},msg:{4}", time, strfilepath, ext, result, msg));
        }
       
    }
}
