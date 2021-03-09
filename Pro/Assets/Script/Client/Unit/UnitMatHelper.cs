using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class UnitMatHelper
{
    /// <summary>
    /// 查找并设置材质
    /// </summary>
    /// <param name="trans"></param>
    /// <param name="matPropName">材质shader属性名</param>
    /// <param name="matList">设置的材质列表</param>

    public static void FindSetMats(Transform trans, string matPropName, List<Material> matList)
    {
        if (trans == null)
            return;
        SkinnedMeshRenderer[] renderers = trans.GetComponentsInChildren<SkinnedMeshRenderer>();
        if (renderers == null)
            return;
        int rendLength = renderers.Length;
        if (rendLength == 0)
            return;
        matList.Clear();
        for (int i = 0; i < rendLength; i++)
        {
            FindMaterials(renderers[i],matPropName,matList);
        }
    }

    /// <summary>
    /// 查找多材质
    /// </summary>
    public static void FindMaterials(SkinnedMeshRenderer renderer, string matPropName, List<Material> matList)
    {
        if (renderer == null)
            return;
        Material[] mats = renderer.materials;
        if (mats == null)
            return;
        int matsLength = mats.Length;
        if (matsLength == 0)
            return;
        for (int i = 0; i < matsLength; i++)
        {
            FindMaterial(mats[i], matPropName, matList);
        }
    }

    /// <summary>
    /// 查找单个材质
    /// </summary>
    /// <param name="mat"></param>
    public static void FindMaterial(Material mat, string matPropName, List<Material> matList)
    {
        if (mat == null)
            return;
        if (!mat.HasProperty(matPropName))
            return;
        matList.Add(mat);
    }

    /// <summary>
    /// 设置Shader浮点属性
    /// </summary>
    public static void SetShaderFltPro(List<Material> mats, string proName, float val)
    {
        if (mats == null)
            return;
        int count = mats.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
        {
            mats[i].SetFloat(proName, val);
        }
    }
}
