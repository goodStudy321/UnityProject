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
     * GUID:        859d6d4e-dead-424d-bd49-a7debd09e2cc
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/4/10 12:07:00
    /// BG:路径移动选择视图
    /// </summary>
    public class PathPointSelectView : SelectViewBase<PathPointSelectInfo>
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
        protected override void OpenCustom()
        {
            Win.SetTitle("点列表选择视图");
        }

        protected override void SetInfos()
        {
            Load();
            infos.Clear();
            int length = PathInfoManager.instance.Size;
            for (int i = 0; i < length; i++)
            {
                PathInfo pointsInfo = PathInfoManager.instance.Get(i);
                PathPointSelectInfo info = new PathPointSelectInfo();
                info.ID = pointsInfo.id;
                infos.Add(info);
            }
        }
        #endregion

        #region 公开方法
        public void Load()
        {
            try
            {
                PathInfoManager.instance.Load("table");
            }
            catch (Exception e)
            {
                string error = string.Format("加载C L 路径点.xls发生错误:{0}", e.Message);
                EditorUtility.DisplayDialog("错误", error, "确定");
                Win.Close();
            }
        }
        #endregion
    }
}