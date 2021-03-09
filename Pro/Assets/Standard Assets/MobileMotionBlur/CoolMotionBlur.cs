using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class CoolMotionBlur : MonoBehaviour
{
    ///  LY add begin///

    /// <summary>
    /// 质量等级
    /// </summary>
    private static int mQualityLv = 0;

    public static int QualityLv
    {
        get { return mQualityLv; }
        set { mQualityLv = value; }
    }

    ///  LY add end ///

    [SerializeField]
    private Material screenMat;
    [SerializeField]
    [HideInInspector]
    private Vector2 mMovingCenter = new Vector2(0.5f, 0.5f);
    [SerializeField]
    [HideInInspector]
    private float mBlurStrength = 1.0f;


    public Vector2 BlurCenter
    {
        get { return mMovingCenter; }
        set
        {
            mMovingCenter = value;
            if (mMovingCenter.x < 0)
            {
                mMovingCenter.x = 0;
            }
            if (mMovingCenter.x > 1f)
            {
                mMovingCenter.x = 1f;
            }
            if (mMovingCenter.y < 0)
            {
                mMovingCenter.y = 0;
            }
            if (mMovingCenter.y > 1f)
            {
                mMovingCenter.y = 1f;
            }

            if (enabled == false || screenMat == null)
            {
                return;
            }
            screenMat.SetVector("_Center", new Vector4(mMovingCenter.x, mMovingCenter.y, 0, 0));
        }
    }

    public float BlurStrength
    {
        get { return mBlurStrength; }
        set
        {
            mBlurStrength = value;
            if (mBlurStrength < 0)
            {
                mBlurStrength = 0f;
            }

            if (enabled == false || screenMat == null)
            {
                return;
            }
            screenMat.SetFloat("_Strength", mBlurStrength);
        }
    }

    public bool BlurEnabled
    {
        get { return enabled; }
        set { enabled = value; }
    }

    public Material ScreenMat
    {
        get { return screenMat; }
        set { screenMat = value; }
    }


    void OnEnable()
    {
        /// LY add begin ///

        if (CheckCanUse() == false)
            return;

        //if(Application.isPlaying == true && QualityMgr.instance.AnimQuality < QualityMgr.AnimQualityType.AQT_2)
        //{
        //    enabled = false;
        //    return;
        //}

        /// LY add end ///

        if (screenMat != null)
        {
            screenMat.SetVector("_Center", new Vector4(mMovingCenter.x, mMovingCenter.y, 0, 0));
            screenMat.SetFloat("_SampleDist", 0.2f);
            screenMat.SetFloat("_Strength", mBlurStrength);
        }
    }

    void Start()
    {
        if (screenMat != null)
        {
            screenMat.SetVector("_Center", new Vector4(mMovingCenter.x, mMovingCenter.y, 0, 0));
            screenMat.SetFloat("_SampleDist", 0.2f);
            screenMat.SetFloat("_Strength", mBlurStrength);
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        /// LY add begin ///

        if (CheckCanUse() == false)
        {
            Graphics.Blit(src, dst);
            return;
        }

        //if (Application.isPlaying == true && QualityMgr.instance.AnimQuality < QualityMgr.AnimQualityType.AQT_2)
        //{
        //    enabled = false;
        //    return;
        //}

        /// LY add end ///

        if (screenMat == null) return;
        Graphics.Blit(src, dst, screenMat);
    }

    /// LY add begin ///

    private bool CheckCanUse()
    {
#if UNITY_EDITOR
        if (mQualityLv <= 0)
        {
            enabled = true;
            return true;
        }

        if (mQualityLv >= 2)
        {
            enabled = true;
            return true;
        }

        enabled = false;
        return false;
#else
        if(mQualityLv >= 2)
        {
            enabled = true;
            return true;
        }

        enabled = false;
        return false;
#endif
    }

    /// LY add end ///
}
