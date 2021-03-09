using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.08.13
    /// BG:野外地图窗口
    /// </summary>
    public class WildMapWindow : EditWinBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        protected override void OnCompiled()
        {
            SceneSelectView sv = Get<SceneSelectView>();
            WildMapRefreshView ev = Get<WildMapRefreshView>();
            sv.editorHandler = ev.Edit;
        }
        #endregion

        #region 公开方法
        public override void Init()
        {
            Add<WildMapAreaView>();
            Add<SceneSelectView>();
            Add<WildMapRefreshView>();
            Switch<SceneSelectView>();
            OnCompiled();
        }

        [MenuItem(MenuTool.Plan + "野外地图编辑器 &Y", false, -1002)]
        [MenuItem(MenuTool.APlan + "野外地图编辑器", false, -1002)]
        public static void Open()
        {
            WinUtil.Open<WildMapWindow>();
        }
        #endregion
    }
}