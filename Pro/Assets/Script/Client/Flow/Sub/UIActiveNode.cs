using Slate;
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
    /// TM:2016.01.09,11:32:39
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class UIActiveNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// UI名称
        /// </summary>
        private string uiName = "";

        [SerializeField]
        private int id = -1;

        [SerializeField]
        private int setActive = 0;

        [SerializeField]
        private int useOnOffEffect = 0;
        #endregion

        #region 属性

        /// <summary>
        /// 窗口ID
        /// </summary>
        public int ID
        {
            get { return id; }
            set { id = value; }
        }

        /// <summary>
        /// 1激活 0关闭
        /// </summary>
        public int SetActive
        {
            get { return setActive; }
            set { setActive = value; }
        }

        /// <summary>
        /// UI开关效果总开关 0:关 1:开
        /// </summary>
        public int UseOnOffEffect
        {
            get { return useOnOffEffect; }
            set { useOnOffEffect = value; }
        }

        #endregion

        #region 私有方法
        private float GetDreictCamDepth()
        {
            var depth = -1f;
            var cur = DirectorCamera.current;
            if (cur == null) return depth;
            var cam = cur.cam;
            if (cam == null) return depth;
            depth = cam.depth - 1f;
            return depth;
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            if (id < 0)
            {
                UIMgr.UseOnOffEffect = (useOnOffEffect < 1) ? false : true;
                if (setActive == 0)
                {
                    //UIMgr.RecordOpens(null);
                    var depth = GetDreictCamDepth();
                    UIMgr.SetCamActive(false, depth);
                }
                else
                {
                    //UIMgr.ReOpens();
                    UIMgr.SetCamActive(true);
                }
            }
            else
            {
                if (setActive == 0)
                {
                    UIMgr.Close(uiName);
                }
                else
                {
                    UIMgr.Open(uiName, null);
                }
            }
            Complete();
        }

        #endregion

        #region 公开方法
        public override void Initialize()
        {
            base.Initialize();
            if (id < 0) return;
            ushort uid = (ushort)id;
            UIConfig conf = UIConfigManager.instance.Find(uid);
            if (conf == null)
            {
                Debug.LogError(Format("没有发现ID为:{0}的UI配置", id));
            }
            else if (string.IsNullOrEmpty(conf.typeName))
            {
                Debug.LogError(Format("ID为:{0}的UI,没有配置类型名称", id));
            }
            else
            {
                uiName = conf.typeName;
            }
        }


        public override void Preload()
        {
            if (setActive == 0) return;
            PreloadMgr.prefab.Add(uiName);
        }


        public override void Read(BinaryReader br)
        {
            base.Read(br);
            id = br.ReadInt32();
            setActive = br.ReadInt32();
            useOnOffEffect = br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(id);
            bw.Write(setActive);
            bw.Write(useOnOffEffect);
        }

        #endregion


        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        private string[] arr = new string[] { "关闭", "激活" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as UIActiveNode;
            if (node == null) return;
            id = node.id;
            setActive = node.setActive;
            useOnOffEffect = node.useOnOffEffect;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("ID:", ref id, o);
            if (GUILayout.Button("打开UI配置表"))
            {
                string path = "../table/U UI配置表.xls";
                ProcessUtil.Execute(path, wairForExit: false);
            }
            EditorGUILayout.EndHorizontal();
            UIEditLayout.Popup("开关:", ref setActive, arr, o);
            if (id < 0)
            {
                if (setActive == 0)
                {
                    UIEditLayout.HelpInfo("关闭所有UI");
                }
                else
                {
                    UIEditLayout.HelpInfo("将重新打开所有已关闭UI");
                }
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("UI开关效果总开关:");
                UIEditLayout.Popup("", ref useOnOffEffect, DisplayOption.onOff, o);
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndVertical();

        }
#endif
        #endregion
    }
}