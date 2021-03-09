#if UNITY_EDITOR

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;



namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        2a87143b-564e-4e7f-b511-8c5622b602cb
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/2/28 15:58:37
    /// BG:
    /// </summary>
    public class TestUITip : TestMonoBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public TestUITip()
        {

        }
        #endregion

        #region 私有方法
        private void Start()
        {
            AssetMgr.Instance.Start();
        }

        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            if (GUILayout.Button("普通提示", btnOpts))
            {
                string tip = UnityEngine.Random.Range(1, 1000).ToString();
                UITip.eLog(tip);
            }
            if (GUILayout.Button("警告提示", btnOpts))
            {
                string tip = UnityEngine.Random.Range(1, 1000).ToString();
                UITip.eWarning(tip);
            }
            if (GUILayout.Button("错误提示", btnOpts))
            {
                string tip = UnityEngine.Random.Range(1, 1000).ToString();
                UITip.eError(tip);
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}
#endif