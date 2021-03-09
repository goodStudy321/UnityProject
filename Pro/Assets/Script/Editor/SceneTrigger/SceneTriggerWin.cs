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
     * GUID:        641959d3-fe39-4dc0-8cb6-219708f66c60
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/5 19:33:10
    /// BG:场景触发器窗口
    /// </summary>
    public class SceneTriggerWin : EditWinBase
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
            SceneTriggerSelectView sv = Get<SceneTriggerSelectView>();
            SceneTriggerEditView ev = Get<SceneTriggerEditView>();
            sv.editorHandler = ev.Edit;
        }
        #endregion

        #region 公开方法
        public override void Init()
        {
            Add<SceneTriggerSelectView>();
            Add<SceneTriggerEditView>();
            Switch<SceneTriggerSelectView>();
            OnCompiled();
        }


        [MenuItem(MenuTool.Plan + "流程树场景触发编辑器 &T", false, -1000)]
        [MenuItem(MenuTool.APlan + "流程树场景触发编辑器", false, -1000)]

        public static void Open()
        {
            WinUtil.Open<SceneTriggerWin>();
        }
        #endregion
    }
}