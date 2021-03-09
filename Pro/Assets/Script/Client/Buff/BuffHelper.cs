using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BuffHelper
{
    public static readonly BuffHelper instance = new BuffHelper();

    private BuffHelper() { }
    #region 公有字段
    /// <summary>
    /// 清除buff
    /// </summary>
    /// <param name="unit"></param>
    public void ClearBuffs(Unit unit)
    {
        if (unit == null)
            return;
        unit.mBuffManager.DestoryAllBuffs();
        for (int i = 0; i < unit.Children.Count; i++)
            unit.Children[i].mBuffManager.DestoryAllBuffs();
    }
    #endregion
}
