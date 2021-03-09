using UnityEngine;
using System.Collections;
using CloudVoiceIM;
public class ImThirdLoginResp : CloudVoiceMsgBase
{
    public int result;//返回结果0为成功，非0是失败
    public string msg;//错误描述
    public int userId;//云音ID
    public string nickName;//昵称
    public string iconUrl;//用户图像地址
    public string thirdUserId;//第三方用户ID
    public string thirdUseName;//第三方用户名

    public ImThirdLoginResp(object Parser)
    {
        uint parser = (uint)Parser;
        result = CloudVoiceImInterface.parser_get_integer(parser, 1, 0);
        msg = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 2, 0));
        userId = CloudVoiceImInterface.parser_get_integer(parser, 3, 0);
        nickName = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 4, 0));
        iconUrl = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 5, 0));
        thirdUserId = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 6, 0));
        thirdUseName = CloudVoiceImInterface.IntPtrToString(CloudVoiceImInterface.parser_get_string(parser, 7, 0));
        InvokeEventClass cpData = new InvokeEventClass(ProtocolEnum.IM_THIRD_LOGIN_RESP, this);
        CloudVoiceImInterface.eventQueue.Enqueue(cpData);

        CloudVoiceLogPrint.DebugLog("ImThirdLoginResp", string.Format("result:{0},msg:{1},userId:{2},nickName:{3},iconUrl:{4},thirdUserId:{5},thirdUseName:{6}", result, msg, userId, nickName, iconUrl, thirdUserId, thirdUseName));
    }
    public ImThirdLoginResp() { }

}
