using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class TitleHelper
{
    public static readonly TitleHelper instance = new TitleHelper();
    private TitleHelper() { }
    #region 公有方法
    /// <summary>
    /// 获取称号字符
    /// </summary>
    /// <param name="actData"></param>
    /// <returns></returns>
    public string GetTitleStr(ActorData actData)
    {
        string title = "";
        if (actData == null)
            return title;
        string posStr = GetTtlStr(actData.FamilyTitle);
        string fmlName = actData.FamlilyName;
        if (string.IsNullOrEmpty(posStr) && string.IsNullOrEmpty(fmlName))
            return title;
        title = string.Format("【{0}】{1}", posStr, fmlName);
        return title;
    }

    /// <summary>
    /// 获取道庭称号
    /// </summary>
    /// <param name="posIndex"></param>
    /// <returns></returns>
    public string GetTtlStr(int posIndex)
    {
        FmlTtlInfo info = FmlTtlInfoManager.instance.Find((uint)posIndex);
        if (info != null)
            return info.title;
        return null;
    }

    public string GetMarryStr(string name)
    {
        if (string.IsNullOrEmpty(name)) return string.Empty;
        string str = Phantom.Localization.Instance.GetDes(690034);
        return string.Format("{0} {1}", name, str);
    }

    /// <summary>
    /// 改变道庭称号
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="actData"></param>
    public void ChgFmlTitle(Unit unit, ActorData actData)
    {
        //string title = GetTitleStr(actData);
        //SetUnitTitle(unit, title);
        if (actData == null) return;
        if (unit == null)
            return;
        if (unit.TopBar == null)
            return;
        CommenNameBar bar = unit.TopBar as CommenNameBar;
        if (bar == null)
            return;
        string name = TitleHelper.instance.GetTitleStr(actData);
        bar.UpdateFlamily(name);
    }

    /// <summary>
    /// 情侣名字
    /// </summary>
    public void ChgMarry(Unit unit, string name)
    {
        if (unit == null)
            return;
        if (unit.TopBar == null)
            return;
        CommenNameBar bar = unit.TopBar as CommenNameBar;
        if (bar == null)
            return;
        bar.UpdateMarry(GetMarryStr(name));
    }

    /// <summary>
    /// 设置单位称号
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="title"></param>
    public void SetUnitTitle(Unit unit,string title)
    {
        if (unit == null)
            return;
        if (unit.TopBar == null)
            return;
        CommenNameBar bar = unit.TopBar as CommenNameBar;
        if (bar == null)
            return;
        bar.Title = title;
    }

    /// <summary>
    /// 境界改变
    /// </summary>
    public void ChgConfine(Unit unit, int confine)
    {
        if (unit == null)
            return;
        if (unit.TopBar == null)
            return;
        CommenNameBar bar = unit.TopBar as CommenNameBar;
        if (bar == null)
            return;
        bar.UpdateConfine(confine);
    }

    /// <summary>
    /// 转生改变
    /// 设置转生巅峰状态
    /// </summary>
    public void ChgRebirth(Unit unit, ActorData actData)
    {
        if (unit == null)
            return;
        if (unit.TopBar == null)
            return;
        CommenNameBar bar = unit.TopBar as CommenNameBar;
        if (bar == null)
            return;
        bar.UpdateRebirthStatus(actData.Level, actData.ReliveLV);
    }
    #endregion
}
