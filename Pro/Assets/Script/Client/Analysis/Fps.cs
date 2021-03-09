/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013.6.8 11:38:22
 ============================================================================*/

using UnityEngine;


namespace Loong.Game
{

    /// <summary>
    /// :帧率
    /// </summary>
    public class Fps : MonoBehaviour
    {
        #region 字段
        private int frame = 0;
        private float fps = 0f;
        private bool active = true;
        private float lastInterval = 0f;
        private float timeInterval = 1f;
        private static Fps instance = null;
        private GUILayoutOption[] ops = null;
        private GUIStyle lblStyle = null;
        #endregion

        #region 属性
        public static Fps Instance { get { return instance; } }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Start()
        {
            var ht = Screen.height * 0.1f;
            lblStyle = new GUIStyle();
            lblStyle.fontSize = 50;
            lblStyle.alignment = TextAnchor.MiddleCenter;
            ops = new GUILayoutOption[] { GUILayout.Width(Screen.width), GUILayout.Height(ht) };
        }

        /// <summary>
        /// 更新
        /// </summary>
        private void Update()
        {
            frame++;
            if ((Time.realtimeSinceStartup - lastInterval) < timeInterval) return;
            fps = frame / timeInterval;
            lastInterval = Time.realtimeSinceStartup;
            frame = 0;
        }

        /// <summary>
        /// GUI显示
        /// </summary>
        private void OnGUI()
        {
            if (!active) return;
            GUILayout.Label(fps.ToString() + " " + Application.targetFrameRate, lblStyle, ops);
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
            var go = new GameObject("Fps");
            instance = go.AddComponent<Fps>();
            DontDestroyOnLoad(go);
        }
        #endregion
    }
}