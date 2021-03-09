using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using Phantom.Protocal;
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
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        0e3d08af-0dc2-4d2d-8b50-7ea549ede176
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/19 14:49:05
    /// BG:AI开关节点
    /// </summary>
    [Serializable]
    public class AIOnOff : FlowChartNode
    {
        #region 字段

        [SerializeField]
        private int option = 1;

        private SpawnNode spawn = null;

        public string spawnName = "";

        #endregion

        #region 属性
        /// <summary>
        /// 1:停止 2:启动
        /// </summary>
        public int Option
        {
            get { return option; }
            set { option = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            if (string.IsNullOrEmpty(spawnName))
            {
                Debug.LogError(Format("出生节点为空"));
            }
            else
            {
                spawn = flowChart.Get<SpawnNode>(spawnName);
                if (spawn == null)
                {
                    Debug.LogError(Format("Not find node with name:{0}", spawnName));
                }
                else
                {
                    int length = spawn.Infos.Count;
                    for (int i = 0; i < length; i++)
                    {
                        var info = spawn.Infos[i];
                        Unit unit = UnitMgr.instance.FindUnitByUid(info.UID);
                        if (unit == null)
                        {
                            Debug.LogError(Format("not find unit with uid:{0}", info.UID));
                        }
                        else
                        {
                            var req = ObjPool.Instance.Get<m_single_ai_tos>();
                            req.monster_id = info.UID;
                            req.type = option;
                            NetworkClient.Send<m_single_ai_tos>(req);
                        }
                    }
                }
            }

            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            option = br.ReadInt32();
            //spawnName = br.ReadString();
            ExString.Read(ref spawnName, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(option);
            //bw.Write(spawnName);
            ExString.Write(spawnName, bw);
        }
        #endregion

        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        private int[] optionArr = new int[] { 1, 2 };
        private string[] optionStrArr = new string[] { "停止AI", "启动AI" };

        public void EditSetSpawnName(FlowChartNode node)
        {

        }


        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as AIOnOff;
            if (node == null) return;
            option = node.option;
            spawnName = node.spawnName;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 3";
        }


        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.TextField("出生点", spawnName);
            if (GUILayout.Button("设置", UIOptUtil.btn))
            {

            }
            EditorGUILayout.EndHorizontal();

            if (spawn == null) UIEditLayout.HelpError("不能为空");
            UIEditLayout.IntPopup("选项:", ref option, optionStrArr, optionArr, o);
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}