using System;
using System.IO;
using Hello.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

public static class LuaMgr 
{
    private static LuaState lua = null;

    private static bool isError = false;

    private static string luaName = "lua.bytes";

    private static readonly object locker = new object();

    public static LuaState Lua
    {
        get
        {
            if (lua == null)
            {
                lock (locker)
                {
                    if (lua == null)
                    {
                        Init();
                    }
                }
            }
            return lua;
        }
    }

    private static void Init()
    {

        lua = new LuaState();


        lua.LuaSetTop(0);
        lua.Start();
        LuaBinder.Bind(lua);
        DelegateFactory.Init();
        LuaCoroutine.Register(Lua, Global.Main);
    }

#if UNITY_EDITOR
    private static void OnDestroy()
    {
        if (lua != null)
        {
            lua.Dispose();
        }
        GC.Collect();
    }
#endif

    /// <summary>
    /// lua入口
    /// </summary>
    private static void MainEntry()
    {
        Lua.Require("Main/Main");
        LuaTool.Call("Main", "Entry");
    }

    private static void ThrowException()
    {
        string error = lua.LuaToString(-1);
        lua.LuaPop(2);
        isError = true;
        throw new LuaException(error, LuaException.GetLastError());
    }


    [MonoPInvokeCallbackAttribute(typeof(LuaCSFunction))]
    private static int LuaOpen_Socket_Core(IntPtr L)
    {
        return LuaDLL.luaopen_socket_core(L);
    }

    /// <summary>
    /// 打开套接字
    /// </summary>
    private static void OpenLuaSocket()
    {
        lua.OpenLibs(LuaDLL.luaopen_socket_core);
        LuaConst.openLuaSocket = true;
        lua.BeginPreLoad();
        lua.RegFunction("socket.core", LuaOpen_Socket_Core);
        lua.EndPreLoad();
    }

    /// <summary>
    /// 打开库
    /// </summary>
    private static void OpenLibs()
    {
        Lua.OpenLibs(LuaDLL.luaopen_pb);
        lua.LuaGetField(LuaIndexes.LUA_REGISTRYINDEX, "_LOADED");
        lua.OpenLibs(LuaDLL.luaopen_cjson);
        lua.LuaSetField(-2, "cjson");

        lua.OpenLibs(LuaDLL.luaopen_cjson_safe);
        lua.LuaSetField(-2, "cjson.safe");
    }

    #region 保护方法

    #endregion

    #region 公开方法


    public static void Update()
    {
        if (isError) return;
        if (lua == null) return;
        if (lua.LuaUpdate(Time.deltaTime, Time.unscaledDeltaTime) != 0)
        {
            ThrowException();
        }

        lua.LuaPop(1);
        lua.Collect();
#if UNITY_EDITOR
        lua.CheckTop();
#endif
    }

    public static void LateUpdate()
    {
        if (isError) return;
        if (lua == null) return;
        if (lua.LuaLateUpdate() != 0)
        {
            ThrowException();
        }

        lua.LuaPop(1);
    }

    public static void FixedUpdate()
    {
        if (isError) return;
        if (lua == null) return;
        if (lua.LuaFixedUpdate(Time.fixedDeltaTime) != 0)
        {
            ThrowException();
        }

        lua.LuaPop(1);
    }
    public static void Refresh()
    {
        MainEntry();
    }

    public static void Dispose()
    {
        lua.Dispose();
        lua = null;
    }
    #endregion
}
