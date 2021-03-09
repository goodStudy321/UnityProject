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
    /// TM:2016.01.12,11:52:17
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class CamHeightNode : FlowChartNode
    {
        #region 字段

        private static float oriHeight = 0f;

        private Vector3 targetPos = Vector3.zero;

        private float count = 0;

        private float from = 0;

        private float to = 0;

        /// <summary>
        /// 高度
        /// </summary>
        public float height = 5f;

        /// <summary>
        /// 持续时间
        /// </summary>
        public float duration = 1f;

        /// <summary>
        /// 设置类型
        /// </summary>
        public int setValue = 0;

        /// <summary>
        /// 相对关系
        /// </summary>
        public RelativeType relativeType = RelativeType.Relative;

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            targetPos = CameraMgr.Main.transform.position;
            if (setValue == 0)
            {
                oriHeight = CameraMgr.Main.transform.position.y;
                from = oriHeight;
                if (relativeType == RelativeType.Relative)
                {
                    to = from + height;
                }
                else
                {
                    to = height;
                }
            }
            else
            {
                from = CameraMgr.Main.transform.position.y;
                to = oriHeight;
            }

        }

        protected override void ProcessUpdate()
        {
            count += Time.deltaTime;
            if (count < duration)
            {
                if (CameraMgr.Main == null) return;
                float t = count / duration;
                float val = from + (to - from) * t;
                targetPos.Set(targetPos.x, val, targetPos.z);
                CameraMgr.Main.transform.position = targetPos;
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
            height = br.ReadSingle();
            duration = br.ReadSingle();
            setValue = br.ReadInt32();
            relativeType = (RelativeType)br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(height);
            bw.Write(duration);
            bw.Write(setValue);
            bw.Write((int)relativeType);
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR


        private string[] arr = new string[] { "设置", "还原" };

        private string[] relativeTypeArr = new string[] { "相对", "绝对" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamHeightNode;
            if (node == null) return;
            height = node.height;
            duration = node.duration;
            setValue = node.setValue;
            relativeType = node.relativeType;
        }

        protected override void EditCompleteDynamicCustom()
        {
            Vector3 pos = CameraMgr.Main.transform.position;
            CameraMgr.Main.transform.position = new Vector3(pos.x, oriHeight, pos.z);
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical("groupbox");

            setValue = EditorGUILayout.Popup("高度类型:", setValue, arr);
            relativeType = (RelativeType)EditorGUILayout.Popup("相对类型:", (int)relativeType, relativeTypeArr);
            if (setValue == 0) height = EditorGUILayout.FloatField("高度/米:", height);
            duration = EditorGUILayout.FloatField("时间/秒:", duration);

            EditorGUILayout.EndVertical();

        }
#endif
        #endregion
    }

    /// <summary>
    /// 相对关系类型
    /// </summary>
    public enum RelativeType
    {
        /// <summary>
        /// 相对
        /// </summary>
        Relative,
        /// <summary>
        /// 绝对
        /// </summary>
        Absolute,
    }
}