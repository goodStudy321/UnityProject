using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using taecg.tools.mobileFastShadow;

#if UNITY_EDITOR
using UnityEditor;
#endif


public class PJShadowMgr
{
    public static readonly string CasterLayer = "ShadowCaster";
    public static readonly string ReceiveLayer = "ShadowReceive";
    public static readonly string ReceiveLayer2 = "ShadowReceive02";

    /// <summary>
    /// 单件指针
    /// </summary>
    private static PJShadowMgr mInstance = null;

    /// <summary>
    /// 新动态阴影
    /// </summary>
    private MobileFastShadow mMFShadow = null;


    public static PJShadowMgr Instance
    {
        get
        {
            if (mInstance == null)
            {
                mInstance = new PJShadowMgr();
            }
            return mInstance;
        }
    }

    public MobileFastShadow FSShadow
    {
        get { return mMFShadow; }
        set
        {
            mMFShadow = value;
        }
    }
}