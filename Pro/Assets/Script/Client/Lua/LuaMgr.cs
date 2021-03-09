using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        a8c49ad0-6913-44c7-80f2-e73c9c844b46
*/

/// <summary>
/// AU:Loong
/// TM:2017/5/10 11:05:49
/// BG:LuaState管理
/// </summary>
public static class LuaMgr
{
    #region 字段
    private static LuaState lua = null;

    private static bool isError = false;

    private static string luaName = "lua.bytes";

    private static readonly object locker = new object();
    #endregion

    #region 属性

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

    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    private static void Init()
    {
#if UNITY_EDITOR
        MonoEvent.onDestroy += OnDestroy;
#if LOONG_TEST_UPG
        if (!SetAB()) return;
#endif

#else
        if (!SetAB()) return;
#endif
        lua = new LuaState();
        OpenLibs();
#if LUA_DEBUG
        OpenLuaSocket();
#endif
        lua.LuaSetTop(0);
        lua.Start();
        LuaBinder.Bind(lua);
        DelegateFactory.Init();
        LuaCoroutine.Register(Lua, Global.Main);

    }

#if UNITY_EDITOR
    private static void OnDestroy()
    {
        MonoEvent.onDestroy -= OnDestroy;
        if (lua != null)
        {
            lua.Dispose();
        }
        GC.Collect();
    }
#endif

    /// <summary>
    /// 设置资源包
    /// </summary>
    private static bool SetAB()
    {
        bool suc = true;
        string dir = AssetPath.Commen;
        string plat = AssetPath.Platform;
        string path = string.Format("{0}{1}/{2}", dir, plat, luaName);
        if (File.Exists(path))
        {
            try
            {
                var ab = AssetBundle.LoadFromFile(path);
                LuaFileUtils.Instance.AB = ab;
            }
            catch (Exception e)
            {
                suc = false;
                var err = string.Format("load lua ab err:{0}", e.Message);
                iTrace.Error("Loong", err);
            }
        }
        else
        {
            suc = false;
            var err = string.Format("lua ab file:{0} not exist!", path);
            iTrace.Error("Loong", err);
        }

        return suc;
    }

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
    #endregion

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
        UIMgr.Refresh();
    }

    public static void Dispose()
    {
        lua.Dispose();
        lua = null;
    }
    #endregion
}