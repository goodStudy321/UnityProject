//#define FXPRO_EFFECT

//#if FXPRO_EFFECT
//    #define GLOWPRO_EFFECT
//    #define BLOOMPRO_EFFECT
//    #define DOFPRO_EFFECT
//#endif


//using UnityEngine;
//using System.Collections;

//using Loong.Game;

//#if FXPRO_EFFECT
//    using FxProNS;
//#elif BLOOMPRO_EFFECT
//    using BloomProNS;
//#elif GLOWPRO_EFFECT
//    using GlowProNS;
//#elif DOFPRO_EFFECT
//    using DOFProNS;
//#endif


///// <summary>
///// 后期效果动画参数助手
///// </summary>
//[ExecuteInEditMode]
//public class FxproProp : MonoBehaviour
//{
//    /// <summary>
//    /// FxPro实例
//    /// </summary>
//    private FxPro mFxPro = null;

//    private BloomHelperParams mBloomParams = null;

//    private DOFHelperParams mDOFParams = null;


//    public Color BloomTint
//    {
//        set
//        {
//            if(mFxPro == null)
//            {
//                return;
//            }
//            mBloomParams.BloomTint = value;
//            BloomHelper.Mat.SetColor("_BloomTint", value);
//        }
//        get
//        {
//            if (mFxPro == null)
//            {
//                return new Color(0, 0, 0, 1);
//            }
//            return mBloomParams.BloomTint;
//        }
//    }
//    public float BloomThreshold
//    {
//        set
//        {
//            if (mFxPro == null)
//            {
//                return;
//            }
//            float val = value;
//            if(val < 0f)
//            {
//                val = 0f;
//            }
//            if(val > 0.99f)
//            {
//                val = 0.99f;
//            }
//            mBloomParams.BloomThreshold = val;
//            BloomHelper.Mat.SetFloat("_BloomThreshold", val);
//        }
//        get
//        {
//            if (mFxPro == null)
//            {
//                return 0f;
//            }
//            return mBloomParams.BloomThreshold;
//        }
//    }
//    public float BloomIntensity
//    {
//        set
//        {
//            if (mFxPro == null)
//            {
//                return;
//            }
//            float val = value;
//            if (val < 0f)
//            {
//                val = 0f;
//            }
//            if (val > 3f)
//            {
//                val = 3f;
//            }
//            mBloomParams.BloomIntensity = val;
//            BloomHelper.Mat.SetFloat("_BloomIntensity", val);
//        }
//        get
//        {
//            if (mFxPro == null)
//            {
//                return 0f;
//            }
//            return mBloomParams.BloomIntensity;
//        }
//    }
//    public float BloomSoftness
//    {
//        set
//        {
//            if (mFxPro == null)
//            {
//                return;
//            }
//            float val = value;
//            if (val < 0.01f)
//            {
//                val = 0.01f;
//            }
//            if (val > 3f)
//            {
//                val = 3f;
//            }
//            mBloomParams.BloomSoftness = val;
//        }
//        get
//        {
//            if (mFxPro == null)
//            {
//                return 0.01f;
//            }
//            return mBloomParams.BloomSoftness;
//        }
//    }

//    public float FocalLengthMultiplier
//    {
//        set
//        {
//            if (mFxPro == null)
//            {
//                return;
//            }
//            float val = value;
//            if (val < 0.01f)
//            {
//                val = 0.01f;
//            }
//            if (val > 1f)
//            {
//                val = 1f;
//            }
//            mDOFParams.FocalLengthMultiplier = val;
//            float tFocalDist = BloomHelper.Mat.GetFloat("_FocalDist");
//            BloomHelper.Mat.SetFloat("_FocalLength", tFocalDist * val);
//        }
//        get
//        {
//            if (mFxPro == null)
//            {
//                return 0f;
//            }
//            return mDOFParams.FocalLengthMultiplier;
//        }
//    }
//    public float DepthCompression
//    {
//        set
//        {
//            if (mFxPro == null)
//            {
//                return;
//            }
//            float val = value;
//            if (val < 2f)
//            {
//                val = 2f;
//            }
//            if (val > 8f)
//            {
//                val = 8f;
//            }
//            mDOFParams.DepthCompression = val;
//            Shader.SetGlobalFloat("_OneOverDepthScale", val);
//        }
//        get
//        {
//            if (mFxPro == null)
//            {
//                return 0f;
//            }
//            return mDOFParams.DepthCompression;
//        }
//    }
//    public float DOFStrength
//    {
//        set
//        {
//            if (mFxPro == null)
//            {
//                return;
//            }
//            float val = value;
//            if (val < 0.5f)
//            {
//                val = 0.5f;
//            }
//            if (val > 2f)
//            {
//                val = 2f;
//            }
//            mDOFParams.DOFBlurSize = val;
//            DOFHelper.Mat.SetFloat("_BlurIntensity", val);
//        }
//        get
//        {
//            if (mFxPro == null)
//            {
//                return 0f;
//            }
//            return mDOFParams.DOFBlurSize;
//        }
//    }


//    private void OnEnable()
//    {
       
//    }

//    private void Awake()
//    {
        
//    }

//    private void Start()
//    {
        
//    }

//    private void Update()
//    {

//    }

    
//    public void Init()
//    {
//        mFxPro = gameObject.GetComponent<FxPro>();
//        if (mFxPro == null)
//        {
//            iTrace.Warning("LY", "FxPro instance miss !!! ");
//            return;
//        }

//        mBloomParams = mFxPro.BloomParams;
//        mDOFParams = mFxPro.DOFParams;
//        iTrace.Log("LY", "Get FxPro !!!");
//    }
//}