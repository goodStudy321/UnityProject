using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitUpLvEffect
{
    private static GameObject mMainUnit;
    private static GameObject mEff;
    private static Dictionary<PropertyBaseType, int> mUpProperty = new Dictionary<PropertyBaseType, int>();

    public static void UpdatePropetyBase(PropertyBaseType type, int value)
    {
        if (mUpProperty.ContainsKey(type)) mUpProperty[type] = value;
        else mUpProperty.Add(type, value);
    }

    public static void AddUnit(GameObject unit)
    {
        mMainUnit = unit;
    }

    private static void CreateEffect()
    {
        if(mEff == null)
        {
            AssetMgr.LoadPrefab(PreloadName.FX_HeroLevelUp, LoadEffectComplete);
        }
        else
        {
            mEff.SetActive(true);
        }
    }

    private static void LoadEffectComplete(GameObject go)
    {
        //DelayDestroy.onDestroy += OnDestroy;
        if (mMainUnit != null)
        {
            go.transform.parent = mMainUnit.transform;
            go.transform.localPosition = Vector3.up;
            go.transform.eulerAngles = Vector3.zero;
            go.transform.localScale = Vector3.one;
            go.SetActive(true);
            mEff = go;
        }
    }

    private static void LoadEffectTestComplete(GameObject go)
    {
        if (mMainUnit != null)
        {
            CapsuleCollider collider = null;
            if (InputMgr.instance.mOwner != null)
            {
                go.transform.parent = mMainUnit.transform;
                collider = Loong.Game.ComTool.Get<CapsuleCollider>(InputMgr.instance.mOwner.UnitTrans);
            }
            go.transform.localPosition = collider != null ? Vector3.up * (collider.height + collider.center.y + 0.8f) : Vector3.zero;
            //go.transform.eulerAngles = Vector3.zero;
            go.transform.localScale = Vector3.one;
            go.SetActive(true);
        }
    }

    private static void OnDestroy(string resName, GameObject go)
    {

    }

    public static void Start()
    {
        CreateEffect();
    }


    public static void Clean()
    {
        mMainUnit = null;
    }
}
