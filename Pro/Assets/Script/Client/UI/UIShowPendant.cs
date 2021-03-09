using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIShowPendant
{
    public static readonly UIShowPendant instance = new UIShowPendant();

    private UIShowPendant()
    {

    }

    #region 私有变量
    /// <summary>
    /// 模型名
    /// </summary>
    private string mModelName;
    /// <summary>
    /// 显示时间
    /// </summary>
    private ushort mShowTime; 
    #endregion

    #region 私有方法
    /// <summary>
    /// 设置模型名
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
    /// 打开回调
    /// </summary>
    private void OpenCallback(string uiName)
    {
        EventMgr.Trigger("ShowItem",mModelName,mShowTime);
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 显示UI模型
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
