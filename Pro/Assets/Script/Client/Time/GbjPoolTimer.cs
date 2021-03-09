using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.7.5
    /// BG:返回游戏对象池计时器
    /// </summary>
    public class GbjPoolTimer : Timer
    {
        #region 字段
        private GameObject go = null;

        #endregion

        #region 属性

        public GameObject Go
        {
            get { return go; }
            set { go = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法


        #endregion

        #region 公开方法
        public override void Stop()
        {
            base.Stop();
            GbjPool.Instance.Add(Go);
            Go = null;
        }

        /// <summary>
        /// 创建并启动返回游戏对象池计时器
        /// </summary>
        /// <param name="go"></param>
        public static void Create(GameObject go, float seconds)
        {
            if (go == null) return;
            GbjPoolTimer tm = ObjPool.Instance.Get<GbjPoolTimer>();
            tm.Seconds = seconds;
            tm.AutoPool = true;
            tm.Go = go;
            tm.Start();
        }
        #endregion
    }
}