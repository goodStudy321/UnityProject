using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Loong.Game;

public class ShowEffectMgr
{
    public static readonly ShowEffectMgr instance = new ShowEffectMgr();

    private ShowEffectMgr() { }

    #region ˽���ֶ�
    /// <summary>
    /// ������Ч
    /// </summary>
    private bool isShieldEff = false;
    /// <summary>
    /// ��ʾ����
    /// </summary>
    private int mShowNum = 3;
    /// <summary>
    /// ��ʾ��Ч�ֵ�
    /// </summary>
    private Dictionary<string, int> mShowEfffectDic = new Dictionary<string, int>();
    #endregion

    #region ����
    /// <summary>
    /// ����������Ч
    /// </summary>
    public bool IsShieldEff
    {
        get { return isShieldEff; }
        set { isShieldEff = value; }
    }
    #endregion

    #region ˽�з���
    /// <summary>
    /// �Լ�����Ч
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    private bool OwnerEffect(Unit attacker, Unit target)
    {
        UnitHelper unitHelper = UnitHelper.instance;
        if (unitHelper.IsOwner(attacker) || unitHelper.IsOwner(target))
            return true;
        return false;
    }

    /// <summary>
    /// ���������Ч
    /// </summary>
    /// <param name="effName"></param>
    /// <returns></returns>
    private bool CheckSetShowEff(string effName)
    {
        if (mShowEfffectDic[effName] >= mShowNum)
            return false;
        mShowEfffectDic[effName]++;
        return true;
    }
    
    #endregion

    #region ���з���
    /// <summary>
    /// �����ʾ��Ч
    /// </summary>
    /// <param name="effectName"></param>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool AddShowEffect(string effectName, Unit attacker = null, Unit target = null, bool hited = false)
    {
        if (mShowNum < 0)
            return true;
        if (string.IsNullOrEmpty(effectName))
            return false;
        if(hited == true)
        {
            if (QualityMgr.instance.TotalQuality < QualityMgr.TotalQualityType.TQT_2)
                return false;
        }
        if(mShowEfffectDic.ContainsKey(effectName))
        {
            if(!OwnerEffect(attacker, target))
            {
                return CheckSetShowEff(effectName);
            }
            else if (UnitHelper.instance.IsOwner(attacker) && hited)
            {
                return CheckSetShowEff(effectName);
            }
            mShowEfffectDic[effectName]++;
            return true;
        }
        mShowEfffectDic.Add(effectName, 1);
        return true;
    }

    /// <summary>
    /// �Ƴ���ʾ��Ч
    /// </summary>
    /// <param name="effectName"></param>
    public void RemoveShowEffect(GameObject go)
    {
        if (go == null)
            return;
        if (!go.activeSelf)
            return;
        string effectName = go.name;
        if (!mShowEfffectDic.ContainsKey(effectName))
            return;
        if (mShowEfffectDic[effectName] <= 0)
            return;
        mShowEfffectDic[effectName]--;
        if (mShowEfffectDic[effectName] > 0)
            return;
        mShowEfffectDic.Remove(effectName);
    }

    /// <summary>
    /// �����ʾ�ֵ�
    /// </summary>
    public void Clear()
    {
        mShowEfffectDic.Clear();
    }

    /// <summary>
    /// ��鹥����Ч
    /// </summary>
    /// <param name="atker"></param>
    /// <returns></returns>
    public bool CheckAtkEff(Unit atker)
    {
        if (!isShieldEff) return true; 
        if (atker == null) return false;
        UnitType type = UnitHelper.instance.GetUnitType(atker.TypeId);
        if (type == UnitType.Monster)
            return true;
        if (UnitHelper.instance.IsOwner(atker))
            return true;
        return false;
    }

    /// <summary>
    /// ����ܻ���Ч
    /// </summary>
    /// <param name="atker"></param>
    /// <param name="atkee"></param>
    /// <returns></returns>
    public bool CheckHitedEff(Unit atker, Unit atkee)
    {
        if (!isShieldEff) return true;
        if (atkee == null) return false;
        UnitHelper unitHelper = UnitHelper.instance;
        if (unitHelper.IsOwner(atkee))
            return true;
        if (CheckAtkEff(atker))
            return true;
        return false;
    }

    /// <summary>
    /// �ı�������Ч��ʾ
    /// </summary>
    /// <param name="args"></param>
    public void ChgShieldEff(params object[] args)
    {
        if (args == null || args.Length == 0)
            return;
        IsShieldEff = Convert.ToBoolean(args[0]);
    }

    /// <summary>
    /// ��ȡ��Ч��
    /// </summary>
    /// <param name="str"></param>
    /// <returns></returns>
    public string GetEffName(string str)
    {
        if (string.IsNullOrEmpty(str))
            return null;
        string[] strs = str.Split(',');
        string eff = null;
        if (strs.Length > 0)
            eff = strs[0];
        return eff;
    }

    /// <summary>
    /// ��ӵ������
    /// </summary>
    /// <param name="go"></param>
    public void AddToPool(GameObject go)
    {
        if (go == null)
            return;
        if (GbjPool.Instance.Exist(go.name))
            GameObject.Destroy(go);
        else
            GbjPool.Instance.Add(go);
    }

    /// <summary>
    /// �����β����
    /// </summary>
    /// <param name="go"></param>
    public void ClearEffTrail(GameObject go)
    {
        if (go == null)
            return;
        PigeonCoopToolkit.Effects.Trails.Trail[] trails = go.GetComponentsInChildren<PigeonCoopToolkit.Effects.Trails.Trail>();
        if (trails == null)
            return;
        for (int i = 0; i < trails.Length; i++)
            trails[i].ClearSystem(true);
    }

    //������ʾ��Ч����
    public void SetShowEffNum(SceneInfo info)
    {
        if (info == null)
        {
            mShowNum = 3;
            return;
        }
        mShowNum = info.showNum;
    }
    #endregion
}
