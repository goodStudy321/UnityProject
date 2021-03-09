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
     * GUID:        5dad1d38-abfe-4e91-a819-2da28ec23e74
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/1/4 15:56:12
    /// BG:选择对象节点
    /// </summary>
    [Serializable]
    public class ObjRotateNode : FlowChartNode
    {
        #region 字段


        /// <summary>
        /// 对象键值
        /// </summary>
        public string key = "";

        /// <summary>
        /// 旋转角度
        /// </summary>
        public Vector3 euler = Vector3.zero;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ObjRotateNode()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            Transform target = null;
            GameObject go = ComponentBind.Get(key);
            if (go == null)
            {
                LogError(string.Format("没有发现键值为:{0}的旋转物体"));
            }
            else
            {
                target = go.transform;
            }
            if (target != null)
            {
                target.eulerAngles = euler;
            }
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            ExString.Read(ref key, br);
            //key = br.ReadString();
            ExVector.Read(ref euler, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            ExString.Write(key, bw);
            //bw.Write(key);
            euler.Write(bw);
        }

        #endregion

#if UNITY_EDITOR

        private Transform tran = null;
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as ObjRotateNode;
            if (node == null) return;
            key = node.key;
            euler = node.euler;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            tran = FindOrCreate(name);
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Vector3Field("角度:", ref euler, o);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("组件键值:", ref key, o);

            if (GUILayout.Button("定位"))
            {
                ComBindTool.Ping<ComponentBind>(key);
            }
            EditorGUILayout.EndHorizontal();
            if (string.IsNullOrEmpty(key))
            {
                UIEditLayout.HelpError("不能为空");
            }
            EditorGUILayout.EndVertical();
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            Quaternion rot = Quaternion.Euler(euler);
            Handles.ArrowHandleCap(o.GetInstanceID(), tran.position, rot, 2, EventType.Repaint);
        }
#endif
    }
}