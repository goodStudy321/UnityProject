using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:九宫格选择视图
    /// </summary>
    public class SceneGridSelectView : SelectAssetView<SceneGrid>
    {
        #region 字段

        #endregion

        #region 属性

        public override string AssetDir
        {
            get { return "Assets/Scene/Share/Custom/Grid"; }
        }

        public override string AssetName
        {
            get { return "SG"; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void EditCustom(SelectAssetInfo info)
        {
            SceneGrid asset = info.Asset as SceneGrid;
            Win.Get<SceneGridEditView>().Asset = asset;
            Win.Switch<SceneGridEditView>();
        }
        #endregion

        #region 公开方法
        public override void OnPlaymodeChanged(bool playing)
        {
            if (!playing) return;
            if (infos.Count > 0) return;
            SetInfos();
        }
        #endregion
    }
}