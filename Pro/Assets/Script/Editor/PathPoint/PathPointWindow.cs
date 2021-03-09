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
     * GUID:        08c77a60-8f60-4b08-b7be-0731796858b6
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/4/10 12:06:37
    /// BG:路径移动编辑窗口
    /// </summary>
    public class PathMoveWindow : EditWinBase
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
            PathPointSelectView ps = Get<PathPointSelectView>();
            PathPointEditView pe = Get<PathPointEditView>();
            ps.editorHandler = pe.Edit;
        }
        #endregion

        #region 公开方法

        public override void Init()
        {
            Add<PathPointEditView>();
            Add<PathPointSelectView>();
            Switch<PathPointSelectView>();
            OnCompiled();
        }

        [MenuItem(MenuTool.Plan + "路径点编辑器 &p", false, -1005)]
        [MenuItem(MenuTool.APlan + "路径点编辑器", false, -1005)]
        public static void Open()
        {
            WinUtil.Open<PathMoveWindow>();
        }

        #endregion
    }
}