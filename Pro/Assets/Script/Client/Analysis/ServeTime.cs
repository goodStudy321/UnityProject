using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ServeTime : MonoBehaviour {

    #region 字段
    private string serverTime = "";
    private bool active = true;
    private float lastInterval = 0f;
    private float timeInterval = 1f;
    private static ServeTime instance = null;
    private GUILayoutOption[] ops = null;
    private GUIStyle lblStyle = null;
    #endregion

    #region 属性
    public static ServeTime Instance { get { return instance; } }
    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    private void Start()
    {
        lblStyle = new GUIStyle();
        lblStyle.fontSize = 30;
        lblStyle.alignment = TextAnchor.MiddleCenter;
        ops = new GUILayoutOption[] { GUILayout.Width(Screen.width / 3), GUILayout.Height(Screen.height * 1.8f) };
    }

    /// <summary>
    /// 更新
    /// </summary>
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.O))
        {
            SetActive(true);
        }
        else if (Input.GetKeyDown(KeyCode.P))
        {
            SetActive(false);
        }

        double timeNow = TimeTool.GetServerTimeNow();
        System.DateTime startTime = TimeZone.CurrentTimeZone.ToLocalTime(new System.DateTime(1970, 1, 1)); // 当地时区
        DateTime dt = startTime.AddSeconds(timeNow / 1000);
        if ((Time.realtimeSinceStartup - lastInterval) < timeInterval) return;
        serverTime = dt.ToString("yyyy/MM/dd HH:mm:ss");
        lastInterval = Time.realtimeSinceStartup;
    }

    /// <summary>
    /// GUI显示
    /// </summary>
    private void OnGUI()
    {
        if (!active) return;
        GUILayout.Label(serverTime, lblStyle, ops);
    }
    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    public void SetActive(bool at)
    {
        active = at;
    }

    public static void Create()
    {
        if (instance != null) return;
        var go = new GameObject("ServeTime");
        instance = go.AddComponent<ServeTime>();
        DontDestroyOnLoad(go);
    }
    #endregion
}
