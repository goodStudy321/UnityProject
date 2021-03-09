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
     * GUID:        e0aa78ec-9c48-4e49-a2bb-3e244350da6d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/8/26 10:56:39
    /// BG:
    /// </summary>
    public class TestGesture : TestMonoBase
    {
        #region 字段
        private string des = "滑动事件";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public TestGesture()
        {

        }
        #endregion

        #region 私有方法

        private void SetDes(string msg)
        {
            des = msg;
            iTrace.Log("Loong", msg);
        }

        private void Up()
        {
            SetDes("【上】滑事件触发了");
        }

        private void Down()
        {
            SetDes("【下】滑事件触发了");
        }

        private void Left()
        {
            SetDes("【左】滑事件触发了");
        }

        private void Right()
        {
            SetDes("【右】滑事件触发了");
        }

        private void Start()
        {
            GestureMgr.One.upSwipe += Up;
            GestureMgr.One.downSwipe += Down;
            GestureMgr.One.leftSwipe += Left;
            GestureMgr.One.rightSwipe += Right;

        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            GUILayout.Label(des, lblOpts);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}
#endif