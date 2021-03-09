using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:音效处理数据
    /// </summary>
    [Serializable]
    public class AudioProcessorData : ProcessorDataBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 绘制UI
        /// </summary>
        /// <param name="obj">所在对象</param>
        public override void OnGUI(Object obj)
        {
            if (!UIEditTool.DrawHeader("音效处理数据", "audioProcessorData", StyleTool.Host)) return;
            DrawBasic(obj);
        }
        #endregion
    }
}