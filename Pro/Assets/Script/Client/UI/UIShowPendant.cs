using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIShowPendant
{
    public static readonly UIShowPendant instance = new UIShowPendant();

    private UIShowPendant()
    {

    }

    #region ˽�б���
    /// <summary>
    /// ģ����
    /// </summary>
    private string mModelName;
    /// <summary>
    /// ��ʾʱ��
    /// </summary>
    private ushort mShowTime; 
    #endregion

    #region ˽�з���
    /// <summary>
    /// ����ģ����
    /// </summary>
    /// <param name="unitTypeId"></param>
    private void SetModelName(ushort systemId)
    {
        systemopen sysOpen = systemopenManager.instance.Find(systemId);
        if (sysOpen == null)
            return;
        ushort modelId = sysOpen.modelid;
        string modelName = UnitHelper.instance.GetUnitModelName(modelId);
        if (string.IsNullOrEmpty(modelName))
            return;
        mModelName = modelName;
    }

    /// <summary>
    /// �򿪻ص�
    /// </summary>
    private void OpenCallback(string uiName)
    {
        EventMgr.Trigger("ShowItem",mModelName,mShowTime);
    }
    #endregion

    #region ���з���
    /// <summary>
    /// ��ʾUIģ��
    /// </summary>
    public void Open(uint systemId, ushort showTime)
    {
        SetModelName((ushort)systemId);
        mShowTime = showTime;
        if (string.IsNullOrEmpty(mModelName))
            return;
        //UIMgr.RecordOpens(UIName.UIShowPendant);
        UIMgr.Open(UIName.UIShowPendant, OpenCallback);
    }
    #endregion
}
