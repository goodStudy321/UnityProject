using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.3.15
    /// BG:符号路径动画
    /// </summary>
    public class TweenSymbolPath : TweenPath
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public TweenSymbolPath()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void StartUp(Transform tran, Action complete, bool relative, TweenPath buf)
        {
            Camera main = Camera.main;
            if (main == null) return;

            Copy(buf);
            float y = main.transform.eulerAngles.y;
            Vector3 euler = Vector3.zero;
            euler.y = y;
            euler.y = (relative ? (y + 180) : y);
            Quaternion rotation = Quaternion.Euler(euler);
            int length = Points.Count;
            for (int i = 0; i < length; i++)
            {
                var point = Points[i];
                point.pos = rotation * point.pos;
            }
            Target = tran;
            this.complete = complete;
            Start();
        }
        #endregion

    }
}