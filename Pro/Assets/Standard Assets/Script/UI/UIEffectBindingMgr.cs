using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
	using UnityEditor;
#endif
using Loong.Game;



public class MatData
{
    /// <summary>
    /// 材质名称
    /// </summary>
    public string matName = "";
    /// <summary>
    /// 材质
    /// </summary>
    public Material mat = null;
    /// <summary>
    /// 引用计数
    /// </summary>
    public int quoteNum = 0;
}

/// <summary>
/// UI特效管理器
/// </summary>
public class UIEffectBindingMgr
{
    public static readonly UIEffectBindingMgr instance = new UIEffectBindingMgr();
    /// <summary>
    /// 存放克隆材质字典
    /// </summary>
    private Dictionary<int, List<MatData>> m_mapCloneMat = new Dictionary<int, List<MatData>>();
    /// <summary>
    /// 
    /// </summary>
    private Dictionary<int, List<UIEffectBinding>> m_mapShowEB = new Dictionary<int, List<UIEffectBinding>>();
    /// <summary>
    /// 当前显示面板层级
    /// </summary>
    //private int mTopDepth = -9999;

    private bool usePersist = false;
    private string rplPosStr = "";


    private UIEffectBindingMgr()
    {
        Init();
    }

    private void Init()
    {
        
    }

    public void SetGlobalData(bool persist, string rplStr)
    {
        usePersist = persist;
        rplPosStr = rplStr;
    }

    /// <summary>
    /// 增加共享材质
    /// </summary>
    /// <param name="depth"></param>
    /// <param name="matName"></param>
    /// <param name="mat"></param>
    private void AddShareMat(int depth, string matName, Material mat)
    {
        if (String.IsNullOrEmpty(matName) == true || mat == null)
            return;

        MatData addData = new MatData();
        addData.matName = matName;
        addData.mat = mat;
        addData.quoteNum = 0;

        if (m_mapCloneMat.ContainsKey(depth))
        {
            m_mapCloneMat[depth].Add(addData);
        }
        else
        {
            List<MatData> newList = new List<MatData>();
            newList.Add(addData);

            m_mapCloneMat.Add(depth, newList);
        }
    }

    /// <summary>
    /// 根据深度与材质名称获取共用材质
    /// </summary>
    /// <param name="depth"></param>
    /// <param name="matName"></param>
    /// <returns></returns>
    private Material GetShareMat(int depth, string matName)
    {
        if (String.IsNullOrEmpty(matName) == true)
            return null;

        if (m_mapCloneMat.ContainsKey(depth))
        {
            List<MatData> tDataList = m_mapCloneMat[depth];
            if (tDataList == null)
                return null;

            for (int a = 0; a < tDataList.Count; a++)
            {
                if (tDataList[a].matName == matName)
                {
                    tDataList[a].quoteNum++;
                    return tDataList[a].mat;
                }
            }
        }

        return null;
    }

    /// <summary>
    /// 共用材质引用完成
    /// </summary>
    /// <param name="depth"></param>
    /// <param name="matName"></param>
    private void FinUseShareMat(int depth, string matName)
    {
        if (String.IsNullOrEmpty(matName) == true)
            return;

        if (m_mapCloneMat.ContainsKey(depth) == false)
            return;

        List<MatData> tDataList = m_mapCloneMat[depth];
        if (tDataList == null)
            return;

        for (int a = 0; a < tDataList.Count; a++)
        {
            if (tDataList[a].matName == matName)
            {
                tDataList[a].quoteNum--;
                break;
            }
        }

        //RemoveNoQuoteShareMat();
    }

    private void FinUseShareMat(Material finMat)
    {
        if (finMat == null)
            return;

        var em = m_mapCloneMat.GetEnumerator();
        while (em.MoveNext())
        {
            List<MatData> matDataList = em.Current.Value;
            for (int a = matDataList.Count - 1; a >= 0; a--)
            {
                if (matDataList[a].mat == finMat)
                {
                    matDataList[a].quoteNum--;
                }
            }
        }
    }

    /// <summary>
    /// 移除没有引用的共用材质
    /// </summary>
    private void RemoveNoQuoteShareMat()
    {
        List<int> tryRemoveList = new List<int>();

        var em = m_mapCloneMat.GetEnumerator();
        while (em.MoveNext())
        {
            List<MatData> matDataList = em.Current.Value;
            for(int a = matDataList.Count - 1; a >= 0; a--)
            {
                if(matDataList[a].quoteNum <= 0 || matDataList[a].mat == null)
                {
                    //if (matDataList[a].mat != null)
                    //{
                    //    GameObject.Destroy(matDataList[a].mat);
                    //}
                    matDataList.RemoveAt(a);
                }
            }

            if (matDataList.Count <= 0)
            {
                tryRemoveList.Add(em.Current.Key);
            }
        }

        for (int a = 0; a < tryRemoveList.Count; a++)
        {
            m_mapCloneMat.Remove(tryRemoveList[a]);
        }
    }

    /// <summary>
    /// 克隆共享材质
    /// </summary>
    /// <param name="depth"></param>
    /// <param name="oriMat"></param>
    private void CloneShareMat(int depth, Material oriMat)
    {
        string matName = oriMat.name;
        Material cloneMat = new Material(oriMat);
        cloneMat.name = matName;
        GameObject.DontDestroyOnLoad(cloneMat);
        //AssetMgr.Instance.SetPersist(cloneMat.name, Suffix.Mat);
        if(usePersist == true)
        {
            string poseStr = ".mat";
            if(string.IsNullOrEmpty(rplPosStr) == false)
            {
                poseStr = rplPosStr;
            }
            EventMgr.Trigger("ResSetPersist", cloneMat.name, poseStr, true);
        }
        AddShareMat(depth, matName, cloneMat);
    }

    /// <summary>
    /// 激活特效层级控件
    /// </summary>
    /// <param name="depth"></param>
    /// <param name="efb"></param>
    public void UIEBActive(int depth, UIEffectBinding efb)
    {
        //UIEBDisable(efb);

        Renderer[] rens = efb.GetComponentsInChildren<Renderer>();
        if (rens == null)
        {
            return;
        }

        for (int a = 0; a < rens.Length; a++)
        {
            if (rens[a].sharedMaterials == null || rens[a].sharedMaterials.Length == 0)
            {
                //Transform ttt = efb.transform.parent;
                //while(ttt != null)
                //{
                //    iTrace.Error("LY", "--------------------------     " + ttt.name);
                //    ttt = ttt.parent;
                //}
                continue;
            }

            Material[] mats = rens[a].sharedMaterials;
            for(int b = 0; b < mats.Length; b++)
            {
                if (mats[b] == null)
                    continue;

                string matName = mats[b].name;


                //if (matName == "xuanzhongkuan_007")
                //{
                //    Debug.Log("+++++++++++++++++++++++++++++++      " + depth);
                //    //Debug.Log("       " + rens[a].transform.parent.name);
                //    //Debug.Log("       " + rens[a].transform.parent.parent.name);
                //    //Debug.Log("       " + rens[a].transform.parent.parent.parent.name);
                //    //Debug.Log("       " + rens[a].transform.parent.parent.parent.parent.name);
                //    //Debug.Log("       " + rens[a].transform.parent.parent.parent.parent.parent.name);
                //    //Debug.Log("       " + rens[a].transform.parent.parent.parent.parent.parent.parent.name);
                //    //Debug.Log("       " + rens[a].transform.parent.parent.parent.parent.parent.parent.parent.name);
                //    //if (rens[a].transform.parent.parent.parent.parent.parent.parent.parent.parent != null)
                //    //{
                //    //    Debug.Log("       " + rens[a].transform.parent.parent.parent.parent.parent.parent.parent.parent.name);
                //    //    if (rens[a].transform.parent.parent.parent.parent.parent.parent.parent.parent.parent != null)
                //    //    {
                //    //        Debug.Log("       " + rens[a].transform.parent.parent.parent.parent.parent.parent.parent.parent.parent.name);
                //    //    }
                //    //}
                //}

                Material sMat = GetShareMat(depth, matName);
                if (sMat == null)
                {
                    CloneShareMat(depth, mats[b]);
                    sMat = GetShareMat(depth, matName);
                }
                mats[b] = sMat;
            }
#if UNITY_EDITOR
            rens[a].materials = mats;
#else
            rens[a].sharedMaterials = mats;
#endif
        }
    }
    //public void UIEBActive(int depth, UIEffectBinding efb)
    //{
    //    UIEBDisable(efb);

    //    Renderer[] rens = efb.GetComponentsInChildren<Renderer>();
    //    if (rens == null)
    //    {
    //        return;
    //    }

    //    for (int a = 0; a < rens.Length; a++)
    //    {
    //        if(rens[a].sharedMaterial == null)
    //        {
    //            //Transform ttt = efb.transform.parent;
    //            //while(ttt != null)
    //            //{
    //            //    iTrace.Error("LY", "--------------------------     " + ttt.name);
    //            //    ttt = ttt.parent;
    //            //}
    //            continue;
    //        }

    //        string matName = rens[a].sharedMaterial.name;
    //        Material sMat = GetShareMat(depth, matName);
    //        if (sMat == null)
    //        {
    //            CloneShareMat(depth, rens[a].sharedMaterial);
    //        }
    //        sMat = GetShareMat(depth, matName);
    //        rens[a].sharedMaterial = sMat;
    //    }
    //}


    public void UIEBDisable(int depth, UIEffectBinding efb)
    {
        //List<int> delDepths = new List<int>();
        //var em = m_mapShowEB.GetEnumerator();
        //while (em.MoveNext())
        //{
        //    if (em.Current.Value.Contains(efb) == true)
        //    {
        //        em.Current.Value.Remove(efb);
        //        delDepths.Add(em.Current.Key);
        //    }
        //}

        //if(delDepths.Count > 0)
        //{
        //    RemoveNullList();

        //    Renderer[] rens = efb.GetComponentsInChildren<Renderer>();
        //    if (rens == null)
        //        return;

        //    for (int a = 0; a < delDepths.Count; a++)
        //    {
        //        for (int b = 0; b < rens.Length; b++)
        //        {
        //            if (rens[b].sharedMaterial == null)
        //                continue;

        //            string matName = rens[b].sharedMaterial.name;
        //            FinUseShareMat(delDepths[a], matName);
        //        }
        //    }

        //    RemoveNoQuoteShareMat();
        //}


        Renderer[] rens = efb.GetComponentsInChildren<Renderer>();
        for (int a = 0; a < rens.Length; a++)
        {
            if(rens[a] == null || rens[a].sharedMaterial == null)
            {
                continue;
            }

            Material[] mats = rens[a].sharedMaterials;
            for (int b = 0; b < mats.Length; b++)
            {
                if (mats[b] == null)
                    continue;

                //string matName = mats[b].name;
                ////if (matName == "jian_001001_01_02")
                //if (matName.Contains("xuanzhongkuan_007"))
                //{
                //    Debug.Log("---------------------------------      ");
                //}

                //FinUseShareMat(depth, matName);
                FinUseShareMat(mats[b]);
            }
        }

        RemoveNoQuoteShareMat();
    }

    
    /// <summary>
    /// 
    /// </summary>
    private void RemoveNullList()
    {
        List<int> tRDepth = new List<int>();

        var em = m_mapShowEB.GetEnumerator();
        while (em.MoveNext())
        {
            if (em.Current.Value.Count <= 0)
            {
                tRDepth.Add(em.Current.Key);
            }
        }

        for (int a = 0; a < tRDepth.Count; a++)
        {
            m_mapShowEB.Remove(tRDepth[a]);
        }
    }

    /// <summary>
    /// 检查添加激活的界面特效
    /// </summary>
    /// <param name="depth"></param>
    /// <param name="efb"></param>
    //private void CheckAddEffBinding(int depth, UIEffectBinding efb)
    //{
    //    bool needChange = true;
    //    var em = m_mapShowEB.GetEnumerator();
    //    while (em.MoveNext())
    //    {
    //        if(em.Current.Value.Contains(efb))
    //        {
    //            if(depth == em.Current.Key)
    //            {
    //                needChange = false;
    //                break;
    //            }
    //            else
    //            {
    //                em.Current.Value.Remove(efb);
    //            }
    //        }
    //    }

    //    RemoveNullList();

    //    if (needChange == true)
    //    {
    //        if(m_mapShowEB.ContainsKey(depth) == false)
    //        {
    //            m_mapShowEB.Add(depth, new List<UIEffectBinding>());
    //        }
    //        m_mapShowEB[depth].Add(efb);
    //    }
    //}

    /// <summary>
    /// 
    /// </summary>
    /// <param name="efb"></param>
    //private void RemoveDisableEB(UIEffectBinding efb)
    //{
    //    var em = m_mapShowEB.GetEnumerator();
    //    while (em.MoveNext())
    //    {
    //        if (em.Current.Value.Contains(efb))
    //        {
    //            em.Current.Value.Remove(efb);
    //        }
    //    }

    //    RemoveNullList();
    //}

    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    //private int GetTopDepth()
    //{
    //    if(mTopDepth >= 0 && m_mapShowEB.ContainsKey(mTopDepth))
    //    {
    //        return mTopDepth;
    //    }

    //    mTopDepth = -9999;
    //    var em = m_mapShowEB.GetEnumerator();
    //    while (em.MoveNext())
    //    {
    //        if (em.Current.Key > mTopDepth)
    //        {
    //            mTopDepth = em.Current.Key;
    //        }
    //    }

    //    return mTopDepth;
    //}

    /// <summary>
    /// 显示顶层特效
    /// </summary>
    //private void ShowTopFx()
    //{
    //    var em = m_mapShowEB.GetEnumerator();
    //    while (em.MoveNext())
    //    {
    //        if (em.Current.Key == mTopDepth)
    //        {
    //            for(int a = 0; a < em.Current.Value.Count; a++)
    //            {
    //                em.Current.Value[a].gameObject.SetActive(true);
    //            }
    //        }
    //        else
    //        {
    //            for (int a = 0; a < em.Current.Value.Count; a++)
    //            {
    //                em.Current.Value[a].gameObject.SetActive(false);
    //            }
    //        }
    //    }
    //}


    /// <summary>
    /// 共用材质特效生效
    /// </summary>
    /// <param name="activeEff"></param>
    //public void EffectBindingActive(int panelDepth, UIEffectBinding activeEff)
    //{
    //    CheckAddEffBinding(panelDepth, activeEff);

    //    if (panelDepth > mTopDepth)
    //    {
    //        mTopDepth = panelDepth;
    //    }

    //    GetTopDepth();
    //    ShowTopFx();
    //}

    /// <summary>
    /// 
    /// </summary>
    /// <param name="activeEff"></param>
    //public void EffectBindingHide(int panelDepth, UIEffectBinding activeEff)
    //{
    //    if(panelDepth == mTopDepth)
    //    {
    //        RemoveDisableEB(activeEff);
    //    }

    //    GetTopDepth();
    //    ShowTopFx();
    //}

    /// <summary>
    /// 
    /// </summary>
    /// <param name="activeEff"></param>
    //public void EffectBindingDestory(UIEffectBinding activeEff)
    //{
    //    RemoveDisableEB(activeEff);

    //    GetTopDepth();
    //    ShowTopFx();
    //}
}
