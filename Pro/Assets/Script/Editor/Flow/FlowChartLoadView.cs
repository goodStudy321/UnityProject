using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        82801596-ce2f-4f44-97c0-d8d60a378aa7
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/10/25 14:39:37
    /// BG:
    /// </summary>
    public class FlowChartLoadView : EditViewBase
    {
        #region 字段
        [SerializeField]
        private string id = "";
        [SerializeField]
        private bool clearNpc = false;
        [SerializeField]
        private bool clearMonster = false;
        #endregion

        #region 属性

        public string ID
        {
            get { return id; }
            set { id = value; }
        }

        /// <summary>
        /// true:清理NPC
        /// </summary>
        public bool ClearNpc
        {
            get { return clearNpc; }
            set { clearNpc = value; }
        }


        /// <summary>
        /// true:清理怪物
        /// </summary>
        public bool ClearMonster
        {
            get { return clearMonster; }
            set { clearMonster = value; }
        }


        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Run()
        {
            if (!EditorApplication.isPlaying)
            {
                UIEditTip.Warning("运行条件下才有效");
            }
            else if (string.IsNullOrEmpty(ID))
            {
                UIEditTip.Warning("没有填写流程树名称");
            }
            else
            {
                if (clearNpc)
                {
                    NPCMgr.instance.CleanmNPCDic();
                }
                if (clearMonster)
                {
                    GMManager.instance.OnSubmitText("role_clear_monster");
                }
                FlowChartMgr.Start(ID);
                UIEditTip.Warning("开始加载,名称已置空");
                ID = "";
            }
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("ID(名称):", ref id, this);
            UIEditLayout.Toggle("清理NPC:", ref clearNpc, this);
            UIEditLayout.Toggle("清理怪物:", ref clearMonster, this);

            EditorGUILayout.EndVertical();
        }


        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("运行")) Run();
            EndTitle();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}