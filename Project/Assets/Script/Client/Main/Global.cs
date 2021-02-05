using System;
using System.IO;
using Hello.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using UnityEngine.Profiling;


public static class Global
{
    private static Main main = null;


    private static bool IsHideUIRoot = false;


    #region Property
    /// <summary>
    /// 入口脚本
    /// </summary>
    public static Main Main
    {
        get { return main; }
        set { main = value; }
    }


    #endregion

    public static void Initialize()
    {
        

    }

    /// <summary>
    /// 更新
    /// </summary>
    public static void Update()
    {

        LuaMgr.Update();


        if (IsHideUIRoot) HideUIRoot();

#if GAME_DEBUG
        iTrace.Update();
#endif
    }

    public static void LateUpdate()
    {
        
        LuaMgr.LateUpdate();
    }


    private static void HideUIRoot()
    {
        
    }
}