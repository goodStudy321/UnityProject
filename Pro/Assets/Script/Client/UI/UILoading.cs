using System;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        1ae3d1b7-10ff-4cf8-8c00-515d1d0b4351
*/

/// <summary>
/// AU:Loong
/// TM:2017/2/8 14:13:47
/// BG:Loading界面
/// </summary>
public class UILoading : IProgress, IDisposable
{
    #region 字段
    private LuaTable luaTable = null;

    private LuaFunction setMsgFunc = null;

    private LuaFunction setTipFunc = null;

    private LuaFunction setProFunc = null;

    public static readonly UILoading Instance = new UILoading();
    #endregion

    #region 属性
    public bool Persistent
    {
        set
        {
            if (luaTable == null) return;
            luaTable["Persistent"] = value;
        }
    }

    public bool Exist
    {
        get { return luaTable == null ? false : true; }
    }
    #endregion

    #region 构造方法
    private UILoading()
    {

    }
    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    public void Init(GameObject go)
    {

    }

    public void Open()
    {
        UIMgr.Open("UILoading", null);
    }

    public void Close()
    {
        UIMgr.Close("UILoading");
    }

    public void SetProgress(float value)
    {
        LuaTool.Call(setProFunc, luaTable, value);
    }

    public void SetMessage(string text)
    {
        LuaTool.Call(setMsgFunc, luaTable, text);
    }

    public void SetTip(string text)
    {
        LuaTool.Call(setTipFunc, luaTable, text);
    }

    public void SetTotal(string size, int total)
    {

    }

    public void SetCount(int count)
    {

    }

    public void Dispose()
    {
        if (luaTable != null) { luaTable.Dispose(); luaTable = null; }
        if (setMsgFunc != null) { setMsgFunc.Dispose(); setMsgFunc = null; }
        if (setTipFunc != null) { setTipFunc.Dispose(); setTipFunc = null; }
        if (setProFunc != null) { setProFunc.Dispose(); setProFunc = null; }
    }

    public void Refresh(LuaTable luaTable)
    {
        this.luaTable = luaTable;
        setMsgFunc = LuaTool.GetFunc(luaTable, "SetMsg");
        setTipFunc = LuaTool.GetFunc(luaTable, "SetTip");
        setProFunc = LuaTool.GetFunc(luaTable, "SetProgress");
    }
    #endregion
}