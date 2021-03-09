using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using Loong;
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        6fe0d25e-5585-46e7-8fc6-f1e2b6292cd5
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/3/15 16:59:11
    /// BG:
    /// </summary>
    [Serializable]
    public class BubbleComInfo : BubbleBaseInfo
    {
        #region 字段

        public string comName = "";

        #endregion

        #region 属性
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public BubbleComInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            //comName = br.ReadString();
            ExString.Read(ref comName, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            //bw.Write(comName);
            ExString.Write(comName, bw);
        }

        public override void Copy(BubbleBaseInfo other)
        {
            Copy(other);
            var info = other as BubbleComInfo;
            comName = info.comName;
        }
        #endregion

#if UNITY_EDITOR
        public override void Draw(Object obj, IList lst, int idx)
        {
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("绑定组件:", ref comName, obj);
            if (GUILayout.Button("定位组件"))
            {
                ComBindTool.Ping<ComponentBind>(comName);
            }
            EditorGUILayout.EndHorizontal();
            base.Draw(obj, lst, idx);
        }
#endif
    }
}