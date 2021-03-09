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
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        6f989671-99d8-47cd-94b6-91f17a03ea1a
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/12 16:13:13
    /// BG:
    /// </summary>
    [Serializable]
    public class ObjPathNode : PathNodeBase
    {
        #region 字段

        /// <summary>
        /// 键值
        /// </summary>
        public string key = "";

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            if (Check())
            {
                var go = ComponentBind.Get(key);
                if (go == null)
                {
                    Debug.LogError(Format(string.Format("没有发现键值为:{0}的目标物体", key)));
                    Complete();
                }
                else
                {
                    target = go.transform;
                    base.ReadyCustom();
                }
            }
            else
            {
                Complete();
            }

        }

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            ExString.Read(ref key, br);
            //key = br.ReadString();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            ExString.Write(key, bw);
            //bw.Write(key);
        }

        public override bool Check()
        {
            if (string.IsNullOrEmpty(key))
            {
                Debug.LogError(Format("对象键值为空"));
                return false;
            }
            return true;
        }
        #endregion

        #region 编辑器字段/属性/方法

#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {

            if (other == null) return;
            var node = other as ObjPathNode;
            if (node == null) return;
            EditCopy(other);
            key = node.key;
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical("groupbox");
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("键值:", ref key, o);
            if (GUILayout.Button("定位组件")) ComBindTool.Ping<ComponentBind>(key);
            EditorGUILayout.EndHorizontal();
            if (string.IsNullOrEmpty(key)) EditorGUILayout.HelpBox("请输入有效键值", MessageType.Error);
            EditorGUILayout.HelpBox("一定确定绑定组件的键值的有效性", MessageType.Warning);
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}