using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        f2a4f5d1-2002-43b9-97d6-2457dd669d77
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/5 12:27:14
    /// BG:Npc编辑窗口
    /// </summary>
    public class NpcWindow : EditWinBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法


        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void OnCompiled()
        {
            SceneSelectView sv = Get<SceneSelectView>();
            NpcEditView ev = Get<NpcEditView>();
            sv.editorHandler = ev.Edit;
        }
        #endregion

        #region 公开方法
        public override void Init()
        {
            Add<NpcEditView>();
            Add<SceneSelectView>();
            Switch<SceneSelectView>();
            OnCompiled();
        }


        [MenuItem(MenuTool.Plan + "NPC编辑器 &N", false, -1003)]
        [MenuItem(MenuTool.APlan + "NPC编辑器", false, -1003)]
        public static void Open()
        {
            WinUtil.Open<NpcWindow>();
        }
        #endregion
    }
}