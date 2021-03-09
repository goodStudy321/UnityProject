using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;
using taecg.tools.mobileFastShadow;


public class HotfixCheckMgr
{
    /// <summary>
    /// 单件指针
    /// </summary>
    private static HotfixCheckMgr mInstance = null;

    public GameObject directorCamRoot = null;
    public GameObject csRenderCamNote = null;
    public GameObject csFxCamNote = null;
    public GameObject shadowRoot = null;

    public CSPCamInitHelper cspCamInitHelper = null;
    public Camera cspCamera = null;
    public Camera fxCamera = null;
    public MobileFastShadow mobileFastShadow = null;


    public static HotfixCheckMgr Instance
    {
        get
        {
            if (mInstance == null)
            {
                mInstance = new HotfixCheckMgr();
            }
            return mInstance;
        }
    }

    /// <summary>
    /// 初始化资源
    /// </summary>
	public void Initialize()
    {
        directorCamRoot = GameObject.Find("★ Director Camera Root");

        shadowRoot = GameObject.Find("ShadowRoot");

        if(shadowRoot != null)
        {
            mobileFastShadow = shadowRoot.GetComponent<MobileFastShadow>();
        }

        if (directorCamRoot != null)
        {
            Transform tTrans = directorCamRoot.transform.Find("Render Camera");
            if(tTrans != null)
            {
                csRenderCamNote = tTrans.gameObject;
                cspCamera = csRenderCamNote.GetComponent<Camera>();

                tTrans = csRenderCamNote.transform.Find("Camera");
                if(tTrans != null)
                {
                    csFxCamNote = tTrans.gameObject;
                    fxCamera = csFxCamNote.GetComponent<Camera>();
                }
            }

            cspCamInitHelper = directorCamRoot.GetComponent<CSPCamInitHelper>();
            if(cspCamInitHelper == null)
            {
                cspCamInitHelper = directorCamRoot.AddComponent<CSPCamInitHelper>();
            }

            cspCamInitHelper.mCSPCamera = cspCamera;
            cspCamInitHelper.mFxCamera = fxCamera;
            cspCamInitHelper.mMFShadow = mobileFastShadow;

            cspCamInitHelper.mCSPCamera.allowMSAA = false;
            cspCamInitHelper.mFxCamera.allowMSAA = false;

            cspCamInitHelper.InitSetResComp();
            PJShadowMgr.Instance.FSShadow = mobileFastShadow;
        }

        EventMgr.Add("ResSetPersist", ResSetPersist);
    }

    public void ResSetPersist(params object[] args)
    {
        if (args == null || args.Length < 3)
            return;

        string name = (string)args[0];
        string sfx = (string)args[1];
        bool val = (bool)args[2];

        AssetMgr.Instance.SetPersist(name, sfx, val);
    }
}