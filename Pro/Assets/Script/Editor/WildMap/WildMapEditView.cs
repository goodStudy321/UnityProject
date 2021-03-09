using System.IO;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;

using NPOI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.08.13
    /// BG:野外地图配置基类
    /// </summary>
    public class WildMapEditView : ExcelEditView
    {
        #region 字段
        private int sceneRow = -1;

        private SceneInfo si = null;

        #endregion

        #region 私有方法

        /// <summary>
        /// 场景所在行
        /// </summary>
        public int SceneRow
        {
            get { return sceneRow; }
            set { sceneRow = value; }
        }

        /// <summary>
        /// 场景信息
        /// </summary>
        public SceneInfo SI
        {
            get { return si; }
            set { si = value; }
        }

        #endregion

        #region 保护方法

        /// <summary>
        /// 返回
        /// </summary>
        protected override void Return()
        {
            Win.Switch<SceneSelectView>();
        }


        #endregion

        #region 公开方法
        public virtual void Edit(SelectInfo info)
        {
            SceneSelectInfo ssi = info as SceneSelectInfo;
            SI = SceneInfoManager.instance.Find(ssi.ID);
        }
        #endregion
    }
}