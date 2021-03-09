using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.11.20,19:58:36
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class CloseDoor : FlowChartNode
    {
        #region 字段
        private OpenDoor door;

        public string doorName = "";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        protected override void ReadyCustom()
        {
            if (string.IsNullOrEmpty(doorName))
            {
                Debug.LogError(Format("door name is null"));
            }
            else
            {
                door = flowChart.Get<OpenDoor>(doorName);
                if (door == null)
                {
                    Debug.LogError(Format("not find node with name:{0}", doorName));
                }
                else
                {
                    door.Close();
                }
            }
            Complete();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            //doorName = br.ReadString();
            ExString.Read(ref doorName, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            //bw.Write(doorName);
            ExString.Write(doorName, bw);
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CloseDoor;
            if (node == null) return;
            doorName = node.doorName;
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(GUI.skin.box);
            UIEditLayout.TextField("要关闭的门:", ref doorName, o);
            if (string.IsNullOrEmpty(doorName))
            {
                UIEditLayout.HelpError("未设置关闭的门");
            }
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}