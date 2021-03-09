using System;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        892b0fe7-a23c-4f20-8580-874db94b68e7
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/5/10 10:47:11
    /// BG:Lua运行时工具
    /// </summary>
    public static class LuaTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取LuaTable
        /// </summary>
        /// <param name="lua">lua状态</param>
        /// <param name="tableName">表名称</param>
        /// <returns></returns>
        public static LuaTable GetTable(LuaState lua, string tableName)
        {
            if (lua == null) return null;
            if (string.IsNullOrEmpty(tableName))
            {
                iTrace.Error("Loong", "查找LuaTable时,表名为空"); return null;
            }
            LuaTable luaTable = lua.GetTable(tableName);
            if (luaTable == null)
            {
                iTrace.Error("Loong", string.Format("没有查找到名为:{0}的LuaTable", tableName));
            }
            return luaTable;
        }

        /// <summary>
        /// 获取LuaFunction
        /// </summary>
        /// <param name="luaTable">lua表</param>
        /// <param name="funcName">方法名</param>
        /// <returns></returns>
        public static LuaFunction GetFunc(LuaTable luaTable, string funcName)
        {
            if (luaTable == null) return null;
            if (string.IsNullOrEmpty(funcName))
            {
                iTrace.Error("Loong", string.Format("在{0}中查找LuaFunction时,方法名为空", luaTable.name));
                return null;
            }
            LuaFunction func = luaTable.GetLuaFunction(funcName);
            if (func == null)
            {
                iTrace.Error("Loong", string.Format("在{0}没有查找到名称为:{1}的LuaFunction", luaTable.name, funcName));
            }
            return func;
        }

        /// <summary>
        /// 调用lua方法
        /// </summary>
        /// <param name="func">方法</param>
        /// <param name="args">参数列表</param>
        public static void Call(LuaFunction func, params object[] args)
        {
            if (func == null)
            {
                iTrace.Error("Loong", "调用Lua方法为空");
                return;
            }
            if (args == null)
            {
                func.Call(); return;
            }
            int length = args.Length;
            func.BeginPCall();
            for (int i = 0; i < length; i++)
            {
                func.Push(args[i]);
            }
            func.PCall();
            func.EndPCall();
        }

        /// <summary>
        /// 在指定名称的表中调用制定名称的方法
        /// </summary>
        /// <param name="tableName">表格名称</param>
        /// <param name="funcName">方法名称</param>
        public static void Call(string tableName, string funcName)
        {
            LuaTable table = GetTable(LuaMgr.Lua, tableName);
            if (table == null) return;
            LuaFunction func = LuaTool.GetFunc(table, funcName);
            if (func != null) { func.Call(); func.Dispose(); }
            table.Dispose();
        }
        public static LuaTable CallFunc(LuaFunction func, params object[] args)
        {
            if (func == null)
            {
                iTrace.Error("Loong", "调用Lua方法为空");
                return null;
            }
            LuaTable tabel = null;
            if (args == null)
            {
                func.Call();
                tabel = func.CheckLuaTable(); 
            }
            else
            {
                int length = args.Length;
                func.BeginPCall();
                for (int i = 0; i < length; i++)
                {
                    func.Push(args[i]);
                }
                func.PCall();
                tabel = func.CheckLuaTable();
                func.EndPCall();
            }
            return tabel ;
        }
        #endregion
    }
}