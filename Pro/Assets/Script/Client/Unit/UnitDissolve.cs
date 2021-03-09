using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitDissolve
{
    #region ˽���ֶ�
    /// <summary>
    /// �ܽⵥλ
    /// </summary>
    private Unit mOwner;
    /// <summary>
    /// �ܽ����
    /// </summary>
    private List<Material> mDlMaterials = new List<Material>();
    /// <summary>
    /// �ܽ�������
    /// </summary>
    private string mDlProName = "_Dissolve_Inteisty";
    /// <summary>
    /// �ܽ�ʱ��
    /// </summary>
    private float mDlTime = 0;
    /// <summary>
    /// ��ǰʱ��
    /// </summary>
    private float mCurTime = 0;
    /// <summary>
    /// �Ƿ���������ܽ����
    /// </summary>
    private bool isAscending = true;
    #endregion

    #region ˽�з���
    /// <summary>
    /// ִ���ܽ�
    /// </summary>
    private void ExeDissolve()
    {
        if (mDlMaterials == null)
            return;
        int count = mDlMaterials.Count;
        if (count == 0)
            return;
        float dlValue = mCurTime / mDlTime;
        dlValue = Mathf.Clamp01(dlValue);
        if (!isAscending)
            dlValue = 1 - dlValue;
        for (int i = 0; i < count; i++)
            mDlMaterials[i].SetFloat(mDlProName, dlValue);
        mCurTime += Time.deltaTime;
        if(mCurTime > mDlTime)
        {
            mCurTime = 0;
            mDlTime = 0;
        }
    }

    /// <summary>
    /// �ָ����ʲ���
    /// </summary>
    private void RecoverMatParam()
    {
        if (mDlMaterials == null)
            return;
        int count = mDlMaterials.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
        {
            mDlMaterials[i].SetFloat(mDlProName, 0);
        }
    }
    #endregion

    #region ���з���
    /// <summary>
    /// ��ʼ��
    /// </summary>
    /// <param name="unit"></param>
    public void init(Unit unit)
    {
        mOwner = unit;
        if (mOwner == null)
            return;
        mCurTime = 0;
        UnitMatHelper.FindSetMats(mOwner.UnitTrans, mDlProName,mDlMaterials);
    }

    /// <summary>
    /// �����ܽ�ʱ��
    /// </summary>
    /// <param name="dlTime"></param>
    public void SetDissolve(float dlTime, int agr)
    {
        mDlTime = dlTime * 0.001f;
        isAscending = agr == 0 ? true : false;
    }
    
    /// <summary>
    /// ����
    /// </summary>
    public void Update()
    {
        if (mDlTime == 0)
            return;
        if (mCurTime > mDlTime)
            return;
        ExeDissolve();
    }

    /// <summary>
    /// �������
    /// </summary>
    public void Clear()
    {
        RecoverMatParam();
        mOwner = null;
        mDlMaterials.Clear();
        mDlTime = 0;
        mCurTime = 0;
        isAscending = true;
    }
    #endregion
}
