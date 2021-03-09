using System;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using UnityStandardAssets.CinematicEffects;
using SleekRender;
using UnityEngine.SceneManagement;

public class CameraNewPostprocessing
{
    private Camera mCamera;
    /// <summary>
    /// 场景摄像机参照物体节点
    /// </summary>
    //private GameObject mSceneCamObj = null;
    /// <summary>
    /// 场景摄像机参照物体
    /// </summary>
    private GameObject mCTCObj = null;


    public GameObject CTCObj
    {
        get { return mCTCObj; }
    }


    public CameraNewPostprocessing(Camera camera)
    {
        mCamera = camera;
    }

    public void UpdatePlayerObj(Transform trans)
    {
        //mTrans = trans;
       // UpdataFxProFocus();
    }

    public void Init()
    {
        if (mCamera != null)
        {
#if ENABLE_POSTPROCESS
            CreateAmplifyColorEffect(mCamera);
            CreateSleekRenderPostProcess(mCamera);
            CreateMotionBlur(mCamera);
#endif
        }
    }
    #region AddPostprocessing

    /// <summary>
    /// 创建后期调色控件
    /// </summary>
    /// <param name="camera"></param>
    private void CreateAmplifyColorEffect(Camera camera)
    {
        if (camera == null) return;
        AmplifyColorEffect amplifyColorEffect = camera.GetComponent<AmplifyColorEffect>();
        if (amplifyColorEffect == null) amplifyColorEffect = camera.gameObject.AddComponent<AmplifyColorEffect>();
        amplifyColorEffect.enabled = false;
    }

    private void CreateSleekRenderPostProcess(Camera camera)
    {
        if (camera == null) return;
        SleekRenderPostProcess srpp = camera.GetComponent<SleekRenderPostProcess>();
        if (srpp == null) srpp = camera.gameObject.AddComponent<SleekRenderPostProcess>();
        srpp.enabled = false;
    }


    /// LY add begin ///

    private Material mBlurMat = null;
    private bool mLoadBlurMat = false;
    private List<CoolMotionBlur> mBlurList = new List<CoolMotionBlur>();

    /// <summary>
    /// 添加动态模糊控件
    /// </summary>
    /// <param name="camera"></param>
    private void CreateMotionBlur(Camera camera)
    {
        if(camera == null)
        {
            mBlurList.Add(null);
            return;
        }

        CoolMotionBlur tMotionBlur = camera.GetComponent<CoolMotionBlur>();
        if(tMotionBlur == null)
        {
            tMotionBlur = camera.gameObject.AddComponent<CoolMotionBlur>();
        }

        mBlurList.Add(tMotionBlur);
        if (mBlurMat != null)
        {
            tMotionBlur.ScreenMat = mBlurMat;
        }
        else if (mLoadBlurMat == false)
        {
            LoadBlurMat();
        }

        tMotionBlur.enabled = false;
        //mBlurList.Add(tMotionBlur);
    }

    private void LoadBlurMat()
    {
        mLoadBlurMat = true;
        AssetMgr.Instance.Load("ScreenMat.mat", FinLoadBlurMat);
    }

    private void FinLoadBlurMat(UnityEngine.Object obj)
    {
        if(obj == null || obj is Material == false)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "Can not find blur material !!! ");
#endif
            return;
        }

        Material tMat = obj as Material;
        tMat.shader = Shader.Find("CoolMotionBlur");
        AssetMgr.Instance.SetPersist(tMat.name, Suffix.Mat);

        mBlurMat = tMat;
        for(int a = 0; a < mBlurList.Count; a++)
        {
            if(mBlurList != null)
            {
                mBlurList[a].ScreenMat = mBlurMat;
            }
        }
    }

    public void StartBlurEffect(Vector2 center, float strength)
    {
#if ENABLE_POSTPROCESS
        for (int a = mBlurList.Count - 1; a >= 0; a--)
        {
            Camera tCamera = mBlurList[a].GetComponent<Camera>();
            if (mBlurList[a] != null && mBlurList[a].gameObject.activeSelf == true
                && tCamera != null && tCamera.enabled == true)
            {
                mBlurList[a].BlurCenter = center;
                mBlurList[a].BlurStrength = strength;
                mBlurList[a].BlurEnabled = true;
                break;
            }
        }
#endif
    }

    public void StopBlurEffect()
    {
#if ENABLE_POSTPROCESS
        for (int a = 0; a < mBlurList.Count; a++)
        {
            if(mBlurList[a] != null)
            {
                mBlurList[a].BlurEnabled = false;
            }
        }
#endif
    }

    /// LY add end ///

    #endregion

    public void UpdateData()
    {
#if ENABLE_POSTPROCESS
        GameObject go = GameObject.Find("Camera_Object");
        if(go == null)
        {
            iTrace.eError("LY", "场景:{0}, 后期处理摄像机不存在",SceneManager.GetActiveScene().name);
            return;
        }
        //mSceneCamObj = go;

        GameObject cam = TransTool.Find(go, "Camera_Test_C");
        if (cam != null)
        {
            mCTCObj = cam;
            UpdateAmplifyColorEffect(mCamera, cam.GetComponent<AmplifyColorEffect>());
            UpdateSleekRenderPostProcess(mCamera, cam.GetComponent<SleekRenderPostProcess>());

            CutscenePlayMgr.instance.CopyCamOriParam(mCTCObj);
            //UpdateDynamicFog(mCamera, cam.GetComponent<DynamicFog>());
            //UpdateAQUAS(mCamera, cam.GetComponent<AQUAS_Camera>());
            //UpdateAmplifyBloomEffect(mCamera, cam.GetComponent<AmplifyBloomEffect>());
        }
#endif
    }

    private void Reflection<T>(ref T current, T target)
    {
        Type t = current.GetType();
        string name = string.Empty;
        foreach (FieldInfo fi in t.GetFields())
        {
            name = fi.Name;
            object obj = fi.GetValue(target);
            fi.SetValue(current, obj);
        }
    }

    public void UpdateAmplifyColorEffect(Camera camera, AmplifyColorEffect effect)
    {
        if (camera == null)
            return;

        AmplifyColorEffect amplifyColorEffect = camera.GetComponent<AmplifyColorEffect>();

        if (amplifyColorEffect == null)
            return;

        amplifyColorEffect.enabled = false;

        if (effect == null)
            return;

        Reflection<AmplifyColorEffect>(ref amplifyColorEffect, effect);
        amplifyColorEffect.enabled = effect.enabled;
    }

    public void UpdateSleekRenderPostProcess(Camera camera, SleekRenderPostProcess effect)
    {
        if (camera == null)
            return;

        SleekRenderPostProcess sleekRenderPostProcess = camera.GetComponent<SleekRenderPostProcess>();

        if (sleekRenderPostProcess == null)
            return;

        sleekRenderPostProcess.enabled = false;

        if (effect == null)
            return;

        //Reflection<SleekRenderPostProcess>(ref sleekRenderPostProcess, effect);
        sleekRenderPostProcess.settings = effect.settings;
        sleekRenderPostProcess.enabled = effect.enabled;
    }

    //public void UpdateDynamicFog(Camera camera, DynamicFog effect)
    //{
    //    if (camera == null) return;
    //    DynamicFog dynamicFog = camera.GetComponent<DynamicFog>();
    //    if (dynamicFog == null) return;
    //    dynamicFog.enabled = false;
    //    if (effect == null) return;
    //    Reflection<DynamicFog>(ref dynamicFog, effect);
    //    dynamicFog.enabled = effect.enabled;
    //}

    //public void UpdateAQUAS(Camera camera, AQUAS_Camera effect)
    //{
    //    if (camera == null) return;
    //    AQUAS_Camera AQUAS = camera.GetComponent<AQUAS_Camera>();
    //    if (AQUAS == null) return;
    //    AQUAS.enabled = false;
    //    if (effect == null) return;
    //    Reflection<AQUAS_Camera>(ref AQUAS, effect);
    //    AQUAS.enabled = effect.enabled;
    //}

    //public void UpdateAmplifyBloomEffect(Camera camera, AmplifyBloomEffect effect)
    //{
    //    if (camera == null) return;
    //    AmplifyBloomEffect amplifyBloomEffect = camera.GetComponent<AmplifyBloomEffect>();
    //    if (amplifyBloomEffect == null) return;
    //    amplifyBloomEffect.enabled = false;
    //    if (effect == null) return;
    //    Reflection<AmplifyBloomEffect>(ref amplifyBloomEffect, effect);
    //    amplifyBloomEffect.enabled = effect.enabled;
    //}
}
