using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class ITweenCallbackTool : MonoSingleton<ITweenCallbackTool>
{
    public Action Callback;
    public Action<object> CallbackObj;


    public void SetOnCallback(Action callbak)
    {
        Callback = callbak;
    }

    public void SetOnCallback(Action<object> callback)
    {
        CallbackObj = callback;
    }

    public void OnCallback()
    {
        if (Callback == null) return;
        Callback();
    }

    public void OnCallbackObj(object value)
    {
        if (CallbackObj == null) return;
        CallbackObj(value);
    }

}
