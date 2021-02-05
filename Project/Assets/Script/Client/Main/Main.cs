using System;
using Hello.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;

public class Main : MonoBehaviour,DebugListener
{
    private bool started = false;
   
    void Start()
    {
        LuaMgr.Refresh();
    }

   
    void Update()
    {
        LuaMgr.Update();
    }


    /// <summary>
    /// Debug接口方法（DebugListener）
    /// </summary>
    /// <param name="clientId"></param>
    public void OnRegister(int clientId)
    {
        //mClientId = clientId;
    }

    //    public void HandlerLog(string logString, string stacTrace, LogType type)
    //    {
    //#if GAME_DEBUG
    //        mDebugInstance.SendLog(logString);
    //        if (type == LogType.Exception || type == LogType.Error)
    //        {
    //            mDebugInstance.SendLog(stacTrace);
    //        }
    //#endif
    //    }
}
