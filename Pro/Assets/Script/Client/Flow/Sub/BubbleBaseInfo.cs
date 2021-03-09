using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        ed472e3d-02e7-4212-8b8d-dded62a00ea9
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/3/15 16:56:38
    /// BG:气泡基础信息
    /// </summary>
    [Serializable]
    public class BubbleBaseInfo
#if UNITY_EDITOR
        : IDraw
#endif
    {
        #region 字段
        public float x = 0;

        public float ht = 1.5f;

        public float dur = 1f;

        public string text = "";

        public int textID = 0;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public BubbleBaseInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public virtual void Read(BinaryReader br)
        {
            x = br.ReadSingle();
            ht = br.ReadSingle();
            dur = br.ReadSingle();
            //text = br.ReadString();
            ExString.Read(ref text, br);

            textID = br.ReadInt32();
        }


        public virtual void Write(BinaryWriter bw)
        {
            bw.Write(x);
            bw.Write(ht);
            bw.Write(dur);
            //bw.Write(text);
            ExString.Write(text, bw);
            bw.Write(textID);
        }

        public virtual void Copy(BubbleBaseInfo other)
        {
            x = other.x;
            ht = other.ht;
            dur = other.dur;
            textID = other.textID;
        }

        #endregion
#if UNITY_EDITOR
        public virtual void Draw(Object obj, IList lst, int idx)
        {
            UIEditLayout.FloatField("相对X轴位置(米):", ref x, obj);
            UIEditLayout.FloatField("相对Y轴位置(米):", ref ht, obj);
            UIEditLayout.FloatField("持续时间(秒):", ref dur, obj);
            //TODO
            UIEditLayout.TextArea("内容:", ref text, obj, null, GUILayout.MinHeight(60));
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("内容ID:", ref textID, obj);
            EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
            EditorGUILayout.EndHorizontal();
        }
#endif
    }
}