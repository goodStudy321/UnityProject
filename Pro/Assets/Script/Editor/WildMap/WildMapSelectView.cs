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
    /// BG:
    /// </summary>
    public class WildMapSceneView : SceneSelectView
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 私有方法
        /// <summary>
        /// 编辑安装区域和入口
        /// </summary>
        private void EditSceneArea()
        {
            Win.Switch<WildMapAreaView>();
        }

        /// <summary>
        /// 编辑单位刷新列表
        /// </summary>
        private void EditRefreshUnits()
        {
            Win.Switch<WildMapRefreshView>();
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            if (e.type == EventType.ContextClick) ContextClick();
            //DrawSceneConfig();
        }

        protected override void ContextClick()
        {
            GenericMenu menu = new GenericMenu();
            menu.AddItem("编辑安全区域和入口", false, EditSceneArea);
            menu.AddSeparator("");
            menu.AddItem("编辑刷新列表", false, EditRefreshUnits);
            menu.AddSeparator("");
            //menu.AddItem("打开场景", false, OpenSceneExtension);
            menu.AddSeparator("");
            menu.ShowAsContext();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}