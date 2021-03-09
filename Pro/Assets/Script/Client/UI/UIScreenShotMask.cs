using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


public class UIScreenShotMask
{
    /// <summary>
    /// 单件指针
    /// </summary>
    private static UIScreenShotMask mInstance = null;

    private GameObject mPanelObj = null;
    private UITexture mShotTex = null;

    private int oriMainCamCull = 0;
    private int ori3DCamCull = 0;

    private int mCallMaskCount = 0;

    private bool openShotMask = false;
    private bool lastUICamEnable = false;


    public static UIScreenShotMask Instance
    {
        get
        {
            if (mInstance == null)
            {
                mInstance = new UIScreenShotMask();
            }
            return mInstance;
        }
    }

    /// <summary>
    /// 初始化资源
    /// </summary>
	public void Initialize()
    {
        if (UIMgr.Cam == null)
        {
            iTrace.Log("LY", "UIMgr.Cam is missing !!! ");
            return;
        }

        Transform maskParent = UIMgr.Cam.transform;

        mPanelObj = new GameObject("ScreenShotMask");
        mPanelObj.transform.parent = maskParent;
        mPanelObj.transform.localPosition = Vector3.zero;
        mPanelObj.transform.localRotation = Quaternion.identity;
        mPanelObj.transform.localScale = Vector3.one;

        UIPanel panel = mPanelObj.AddComponent<UIPanel>();
        panel.depth = -3;

        GameObject texObj = new GameObject("ShotTex");
        texObj.transform.parent = mPanelObj.transform;
        texObj.transform.localPosition = Vector3.zero;
        texObj.transform.localRotation = Quaternion.identity;
        texObj.transform.localScale = Vector3.one;

        mShotTex = texObj.AddComponent<UITexture>();
        mShotTex.width = Screen.width;
        mShotTex.height = Screen.height;
        //mShotTex.UpdateAnchors();
        mShotTex.updateAnchors = UIRect.AnchorUpdate.OnEnable;
        mShotTex.SetAnchor(UIMgr.Root.gameObject, 0, 0, 0, 0);

        mPanelObj.layer = LayerMask.NameToLayer("UI");
        texObj.layer = LayerMask.NameToLayer("UI");

        mPanelObj.SetActive(false);

        //mShotTex.mainTexture = TexTool.GetScreenShotByCam(CameraMgr.Main);

        EventMgr.Add("OpenScreenShotMask", TriggerOpenShotMask);

        mCallMaskCount = 0;
    }

    public void Update()
    {
        if (openShotMask == false)
            return;

        if (UIMgr.Cam == null)
            return;

        bool curUICamEnable = UIMgr.Cam.enabled;
        if(curUICamEnable != lastUICamEnable)
        {
            if(curUICamEnable == true)
            {
                CameraMgr.Main.cullingMask = 0;

                GameObject threeDCamObj = Utility.FindNode(CameraMgr.Main.gameObject, "3DUICam");
                if (threeDCamObj != null)
                {
                    Camera t3DCam = threeDCamObj.GetComponent<Camera>();
                    t3DCam.cullingMask = 0;
                }
            }
            else
            {
                CameraMgr.Main.cullingMask = oriMainCamCull;
                GameObject threeDCamObj = Utility.FindNode(CameraMgr.Main.gameObject, "3DUICam");
                if (threeDCamObj != null)
                {
                    threeDCamObj.GetComponent<Camera>().cullingMask = ori3DCamCull;
                }
            }
        }
        lastUICamEnable = curUICamEnable;
    }

    private void TriggerOpenShotMask(params object[] args)
    {
        if (args == null || args.Length <= 0)
        {
            return;
        }

        bool openShotMask = (bool)args[0];

        if (openShotMask == true)
        {
            mCallMaskCount++;
            if (mCallMaskCount == 1)
            {
                mShotTex.mainTexture = TexTool.GetScreenShotByCam(CameraMgr.Main);
                mShotTex.ResetAndUpdateAnchors();
                if (CameraMgr.Main != null)
                {
                    //CameraMgr.Main.enabled = false;
                    oriMainCamCull = CameraMgr.Main.cullingMask;
                    CameraMgr.Main.cullingMask = 0;

                    GameObject threeDCamObj = Utility.FindNode(CameraMgr.Main.gameObject, "3DUICam");
                    if(threeDCamObj != null)
                    {
                        //threeDCamObj.GetComponent<Camera>().enabled = false;
                        Camera t3DCam = threeDCamObj.GetComponent<Camera>();
                        ori3DCamCull = t3DCam.cullingMask;
                        t3DCam.cullingMask = 0;
                    }
                }
            }

            //Global.Main.StartCoroutine(Loong.Game.TexTool.GetScreenShotByCam(CameraMgr.Main, ShotRenderCallBack));
        }
        else
        {
            mCallMaskCount--;
            if(mCallMaskCount < 0)
            {
                mCallMaskCount = 0;
            }
            if (mCallMaskCount == 0)
            {
                if (CameraMgr.Main != null)
                {
                    //CameraMgr.Main.enabled = true;
                    CameraMgr.Main.cullingMask = oriMainCamCull;
                    GameObject threeDCamObj = Utility.FindNode(CameraMgr.Main.gameObject, "3DUICam");
                    if (threeDCamObj != null)
                    {
                        //threeDCamObj.GetComponent<Camera>().enabled = true;
                        threeDCamObj.GetComponent<Camera>().cullingMask = ori3DCamCull;
                    }
                }
                if(mShotTex.mainTexture != null)
                {
                    GameObject.DestroyImmediate(mShotTex.mainTexture);
                    mShotTex.mainTexture = null;
                }
            }
        }
        mPanelObj.SetActive(openShotMask);
    }

    //private void ShotRenderCallBack(Texture2D tex)
    //{
    //    mShotTex.mainTexture = tex;
    //}
}