using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        4412cf1c-28f8-4527-adb0-bd59bab32068
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/4/12 15:17:50
    /// BG:文本信息
    /// </summary>
    [Serializable]
    public class TextInfo
#if UNITY_EDITOR
       : IDraw
#endif
    {
        #region 字段
        /// <summary>
        /// 持续时间
        /// </summary>
        public float dur = 1;

        /// <summary>
        /// 字幕
        /// </summary>
        public string text = "";

        public int textID = 0;
        #endregion

        #region 属性

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
        public void Read(BinaryReader br)
        {
            dur = br.ReadSingle();
            ExString.Read(ref text, br);
            textID = br.ReadInt32();

        }

        public void Write(BinaryWriter bw)
        {
            bw.Write(dur);
            ExString.Write(text, bw);
            bw.Write(textID);

        }

        public void Copy(TextInfo other)
        {
            dur = other.dur;
            textID = other.textID;
        }

#if UNITY_EDITOR
        public void Draw(Object obj, IList lst, int idx)
        {
            UIEditLayout.TextField("内容:", ref text, obj);

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("内容ID:", ref textID, obj);
            EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
            EditorGUILayout.EndHorizontal();

            UIEditLayout.FloatField("持续时间/秒:", ref dur, obj);
        }
#endif
        #endregion
    }
}