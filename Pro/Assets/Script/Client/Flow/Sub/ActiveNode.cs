using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;

#if UNITY_EDITOR
using Loong;
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.12.10,20:28:22
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class ActiveNode : FlowChartNode
    {
        #region 字段

        public string targetName = "null";

        public bool setActive;


        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            var target = ComponentBind.Get(targetName);
            if (target != null)
            {
                target.SetActive(setActive);
            }
#if GAME_DEBUG
            else
            {
                Debug.LogError(Format("Not find Go with key:{0}", targetName));
            }
#endif
            Complete();
        }

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            //targetName = br.ReadString();
            ExString.Read(ref targetName, br);
            setActive = br.ReadBoolean();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            //bw.Write(targetName);
            ExString.Write(targetName, bw);
            bw.Write(setActive);
        }
        #endregion


        #region 编辑器字段/属性/方法

#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as ActiveNode;
            if (node == null) return;
            targetName = node.targetName;
            setActive = node.setActive;
        }


        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical("box");
            setActive = System.Convert.ToBoolean(EditorGUILayout.Popup("状态类型:", System.Convert.ToInt32(setActive), DefineTool.activeArr));
            EditorGUILayout.BeginHorizontal();
            targetName = EditorGUILayout.TextField("目标名称:", targetName);
            if (GUILayout.Button("定位组件")) ComBindTool.Ping<ComponentBind>(targetName);
            EditorGUILayout.EndHorizontal();
            if (string.IsNullOrEmpty(targetName))
            {
                EditorGUILayout.HelpBox("必须输入绑定目标物体名称", MessageType.Error);
            }

            EditorGUILayout.EndVertical();

        }


#endif

        #endregion
    }
}