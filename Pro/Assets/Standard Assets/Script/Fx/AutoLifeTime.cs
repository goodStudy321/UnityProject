using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AutoLifeTime:MonoBehaviour
{
    private GameObject mGo = null;

    public AutoLifeTime(GameObject go)
    {
        this.mGo = go;
    }

    /// <summary>
    /// 自己销毁
    /// </summary>
    public void LifeTimeDispose(float lifeTime)
    {
        GameObject.Destroy(mGo);
        mGo = null;
    }
}
