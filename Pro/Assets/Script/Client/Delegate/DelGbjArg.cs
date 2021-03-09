using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class DelGbjArg : DelGbj
{
    public delegate void GbjHandler(GameObject go, List<object> arg);
    public new event GbjHandler handler = null;
    public List<object> args = new List<object>();

    protected override void Execute(GameObject t)
    {
        if (handler != null)
        {
            handler(t, args);
            handler = null;
        }
    }
}
