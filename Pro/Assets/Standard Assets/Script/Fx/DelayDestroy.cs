using UnityEngine;
using System.Collections;

public class DelayDestroy : MonoBehaviour
{
    #region 委托
    public delegate void OnDestroy(GameObject gbj, long unitUID);
    #endregion

    #region 公有变量
    public int Time = 1000;
    public OnDestroy onDestroy = null;
    [HideInInspector]
    public long unitUID;
    #endregion

    #region 私有方法
    void OnEnable()
    {
        StartCoroutine(StartTime());
    }

    // Use this for initialization
    IEnumerator StartTime()
    {
        yield return new WaitForSeconds(Time / 1000f);

        if (onDestroy == null)
        {
            GameObject.Destroy(gameObject);
            //Loong.Game.AssetMgr.Instance.Unload(name, ".Prefab", false);
            Loong.Game.AssetBridge.Unload(name, ".Prefab");
        }
        else
            onDestroy(gameObject, unitUID);
    }
    #endregion
}
