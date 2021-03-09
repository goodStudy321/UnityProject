using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using LuaInterface;
using Loong.Game;

public class UIBuff : IDisposable
{
    public static readonly UIBuff instance = new UIBuff();

    private UIBuff()
    {

    }
    #region ˽�б���
    //private LuaTable mLuaTable = null;
    //private LuaFunction mAddBuff = null;
    //private LuaFunction mDelBuff = null;
    //private LuaFunction mSetCD = null;
    #endregion

    #region ���з���
    /// <summary>
    /// ���buff
    /// </summary>
    /// <param name="buffId"></param>
    /// <param name="iconName"></param>
    public void AddBuff(uint buffId, string iconName)
    {
        /**
        if (mLuaTable == null)
            mLuaTable = LuaTool.GetTable(LuaMgr.Lua, "UIBuff");
        if (mLuaTable == null)
            return;
        if(mAddBuff == null)
            mAddBuff = LuaTool.GetFunc(mLuaTable, "AddBuff");
        if (mAddBuff == null)
            return;
        LuaTool.Call(mAddBuff, mLuaTable, buffId, iconName);
    */
    }

    /// <summary>
    /// ����buffCD
    /// </summary>
    /// <param name="buffId"></param>
    /// <param name="cdTime">buff ��cdʱ��</param>
    public void SetBuffCD(uint buffId, float cdTime)
    {
        /**
        if (mLuaTable == null)
            mLuaTable = LuaTool.GetTable(LuaMgr.Lua, "UIBuff");
        if (mLuaTable == null)
            return;
        if(mSetCD == null)
            mSetCD = LuaTool.GetFunc(mLuaTable, "SetCD");
        if (mSetCD == null)
            return;
        LuaTool.Call(mSetCD, mLuaTable, buffId, cdTime);
    */
    }

    /// <summary>
    /// ɾ��buff
    /// </summary>
    /// <param name="buffId"></param>
    public void DelBuff(uint buffId)
    {
        /**
        if (mLuaTable == null)
            mLuaTable = LuaTool.GetTable(LuaMgr.Lua, "UIBuff");
        if (mLuaTable == null)
            return;
        if (mDelBuff == null)
            mDelBuff = LuaTool.GetFunc(mLuaTable, "DelBuff");
        if (mDelBuff == null)
            return;
        LuaTool.Call(mDelBuff, mLuaTable, buffId);
    **/
    }

    public void Dispose()
    {
        //if (mLuaTable != null)
        //    mLuaTable = null;
        //if (mAddBuff != null)
        //    mAddBuff = null;
        //if (mSetCD != null)
        //    mSetCD = null;
    }
    #endregion
}
