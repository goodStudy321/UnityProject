using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using CloudVoiceIM;
using AOT;

namespace CloudVoiceIM
{
    public enum CmdChannel
    {
        IM_LOGIN = 1,
        IM_FRIEND = 2,
        IM_GROUPS = 3,
        IM_CHAT = 4,
        IM_CLOUND = 5,
        IM_CHANNEL = 6,
        IM_TROOPS = 7,
		IM_LBS = 8,
        IM_TOOLS = 9,
    };
    public class InvokeEventClass
    {
        public ProtocolEnum eventType;
        public object dataObj;

        public InvokeEventClass(ProtocolEnum EventType, object DataObj)
        {

            eventType = EventType;
            dataObj = DataObj;
        }
    }
    public delegate void CloudVoiceCallBack(CmdChannel type, uint cmdid, uint parser, uint context);

    [StructLayout(LayoutKind.Sequential)]
    public class CloudVoiceImInterface : MonoSingleton<CloudVoiceImInterface>
    {
        public override void Init()
        {
            base.Init();
            if (cvCallBack == null)
            {
                cvCallBack = new CloudVoiceCallBack(CallBack);
            }
            DontDestroyOnLoad(this);
        }
        private CloudVoiceCallBack cvCallBack;

        #region used by CloudVoice callback

        public static int parser_get_integer(uint parser, int cmdId, int index = 0)
        {
            return parser_get_integer(parser, (byte)cmdId, index);
        }

        public static IntPtr parser_get_string(uint parser, int cmdId, int index = 0)
        {
            return parser_get_string(parser, (byte)cmdId, index);
        }

        public static bool parser_is_empty(uint parser, int cmdId, int index = 0)
        {
            return parser_is_empty(parser, (byte)cmdId, index);
        }

        public static void parser_get_object(uint parser, int cmdId, uint obj, int index = 0)
        {
            parser_get_object(parser, (byte)cmdId, obj, index);
        }

        public static byte parser_get_uint8(uint parser, int cmdId, int index = 0)
        {
            return parser_get_uint8(parser, (byte)cmdId, index);
        }

        public static uint parser_get_uint32(uint parser, int cmdId, int index = 0)
        {
            return (uint)parser_get_integer(parser, (byte)cmdId, index);
        }

		#endregion

        public static MyQueue eventQueue = new MyQueue();

        public class MyQueue
        {

            private Queue<InvokeEventClass> myQueue;

            private object _lock;

            public MyQueue()
            {
                myQueue = new Queue<InvokeEventClass>();
                _lock = new object();
            }

            public void Enqueue(InvokeEventClass item)
            {
                lock (_lock)
                {
                    myQueue.Enqueue(item);
                }
            }

            public bool GetData(Queue<InvokeEventClass> outQ)
            {
                lock (_lock)
                {
                    int count = myQueue.Count;
                    if (count == 0)
                    {
                        return false;
                    }

                    for (int i = 0; i < count; i++)
                    {
                        InvokeEventClass obj = myQueue.Dequeue();
                        outQ.Enqueue(obj);
                    }

                    return true;
                }
            }
        }

        #region 接口调用

        public int InitSDK(uint context, uint appid, string path, bool isTest)
        {
            #if UNITY_EDITOR
            {
                Debug.LogError("CloudVoiceLogPrint:Please run on Android or ios cellphone!");
                return 3;
            }
            #elif UNITY_IOS||UNITY_ANDROID
                {
                    return CloudVoice_IM_Init(CallBack, context, appid, path, isTest);
                }
            #endif
        }

        public void ReleaseSDK()
        {
            #if UNITY_IOS||UNITY_ANDROID
                {
                    CloudVoice_IM_Release();
                }
            #endif
        }

        public int CV_SendCmd(CmdChannel type, uint cmdid, uint parser)
        {
        #if UNITY_IOS||UNITY_ANDROID
            {
                return CloudVoice_IM_SendCmd(type, cmdid, parser);
            }
        #else
            return 3;
        #endif

        }

        public uint CVpacket_get_parser()
        {
        #if UNITY_IOS||UNITY_ANDROID
            {
                return cloudvoice_packet_get_parser();
            }
        #else
               return 3;
        #endif

        }

        public void CVparser_set_object(uint parser, byte cmdId, uint value)
        {
            #if UNITY_IOS||UNITY_ANDROID
                {
                    parser_set_object(parser, cmdId, value);
                }
            #endif
        }

        public void CVparser_set_uint8(uint parser, byte cmdId, int value)
        {
            #if UNITY_IOS||UNITY_ANDROID
                {
                    parser_set_uint8(parser, cmdId, value);
                }
            #endif
        }

        public void CVparser_set_integer(uint parser, byte cmdId, int value)
        {
            #if UNITY_IOS||UNITY_ANDROID
                {
                    parser_set_integer(parser, cmdId, value);
                }
            #endif
        }

        public void CVparser_set_string(uint parser, byte cmdId, string value)
        {
            #if UNITY_IOS||UNITY_ANDROID
                {
                    parser_set_string(parser, cmdId, value);
                }
            #endif
        }

        #if UNITY_ANDROID
            //public void CVparser_set_string(uint parser, byte cmdId, IntPtr value)
            //{
            //    parser_set_string (parser, cmdId, value);
            //}
        #elif UNITY_EDITOR_WIN
                //public void CVparser_set_string(uint parser, byte cmdId, IntPtr value)
                //{
                //    parser_set_string(parser, cmdId, value);
                //}
        #endif

        public void CVparser_set_buffer(uint parser, byte cmdId, IntPtr value, int len)
        {
            #if UNITY_IOS||UNITY_ANDROID
                {
                    parser_set_buffer(parser, cmdId, value, len);
                }
            #endif
        }
        #endregion

    [MonoPInvokeCallback(typeof(CloudVoiceCallBack))]
        public static void CallBack(CmdChannel type, uint cmdid, uint parser, uint context)
        {
            //ArrayList list = new ArrayList();
			string tatal = type.ToString() + "; " + (ProtocolEnum)cmdid; //0x" + cmdid.ToString("x"); // + ";" + parser.ToString () + ";" + context.ToString ();
            Debug.Log("====Unity==== callback:" + tatal);
            CloudVoiceMsgBase.GetMsg(cmdid, (object)parser);
    
        }

        public static string IntPtrToString(IntPtr intptr, bool isVR = false)
        {
            int len = 0;
            while (true)
            {
                byte ch = Marshal.ReadByte(intptr, len);
                len++;
                if (ch == 0)
                {
                    break;
                }
            }

            byte[] test = new byte[len - 1];
            Marshal.Copy(intptr, test, 0, len - 1);

//#if UNITY_EDITOR
//            if (isVR)
//            {
//                return Encoding.UTF8.GetString(test);
//            }
//            else
//            {
//                return Encoding.Default.GetString(test);
//            }
//#endif

            return Encoding.UTF8.GetString(test);
        }

        private Queue<InvokeEventClass> tmpQ = new Queue<InvokeEventClass>();

        void Update()
        {
            if (eventQueue.GetData(tmpQ))
            {
                while (tmpQ.Count > 0)
                {
                    InvokeEventClass obj = tmpQ.Dequeue();
                    EventListenerManager.Invoke(obj.eventType, obj.dataObj);
                }
            }
        }

        void OnApplicationQuit()
        {	
           
        }


#region imsdk
#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern int CloudVoice_IM_Init(CloudVoiceCallBack callback, uint context, uint appid, string path, bool test);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern int CloudVoice_IM_Init(CloudVoiceCallBack callback, uint context, uint appid, string path, bool test);
#endif
        //private static extern int CloudVoice_IM_Init(CloudVoiceCallBack callback, uint context, uint appid, string path, bool test);

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern void CloudVoice_IM_Release();
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern void CloudVoice_IM_Release();
#endif


#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern int CloudVoice_IM_SendCmd(CmdChannel type, uint cmdid, uint parser);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern int CloudVoice_IM_SendCmd(CmdChannel type, uint cmdid, uint parser);
#endif


        //packet
#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern uint cloudvoice_packet_get_parser();
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern uint cloudvoice_packet_get_parser();
#endif


#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern uint cloudvoice_packet_get_parser_object(uint parser);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern uint cloudvoice_packet_get_parser_object(uint parser);
#endif

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern void parser_set_object(uint parser, byte cmdId, uint value);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern void parser_set_object(uint parser, byte cmdId, uint value);
#endif


#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern void parser_set_uint8(uint parser, byte cmdId, int value);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern void parser_set_uint8(uint parser, byte cmdId, int value);
#endif


#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern void parser_set_integer(uint parser, byte cmdId, int value);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern void parser_set_integer(uint parser, byte cmdId, int value);
#endif
		

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern void parser_set_string(uint parser, byte cmdId, string value);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern void parser_set_string(uint parser, byte cmdId, string value);
#endif
		

#if UNITY_ANDROID
    [DllImport("CvImSdk")]
	public static extern void parser_set_string(uint parser, byte cmdId, IntPtr value);
#endif


#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern void parser_set_buffer(uint parser, byte cmdId, IntPtr value, int len);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern void parser_set_buffer(uint parser, byte cmdId, IntPtr value, int len);
#endif
		

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern void parser_get_object(uint parser, byte cmdId, uint obj, int index);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern void parser_get_object(uint parser, byte cmdId, uint obj, int index);
#endif
		

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern byte parser_get_uint8(uint parser, byte cmdId, int index);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern byte parser_get_uint8(uint parser, byte cmdId, int index);
#endif
		

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern int parser_get_integer(uint parser, byte cmdId, int index);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern int parser_get_integer(uint parser, byte cmdId, int index);
#endif
		

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern IntPtr parser_get_string(uint parser, byte cmdId, int index);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern IntPtr parser_get_string(uint parser, byte cmdId, int index);
#endif
		

#if UNITY_IOS
	[DllImport("__Internal")]
    private static extern bool parser_is_empty(uint parser, byte cmdId, int index);
#elif UNITY_ANDROID
    [DllImport("CvImSdk")]
    private static extern bool parser_is_empty(uint parser, byte cmdId, int index);
#endif
   
    }
#endregion
}
