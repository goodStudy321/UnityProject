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
     * GUID:        a2066d85-6b98-4c2c-8a17-e6e469409179
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/13 19:24:52
    /// BG:选择场景视图
    /// </summary>
    public class SceneSelectView : SelectViewBase<SceneSelectInfo>
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
        protected override void SetInfos()
        {
            if (!Load()) return;
            infos.Clear();
            int length = SceneInfoManager.instance.Size;
            for (int i = 0; i < length; i++)
            {
                SceneInfo si = SceneInfoManager.instance.Get(i);
                SceneSelectInfo info = new SceneSelectInfo();
                info.ID = si.id;
                info.Name = si.name;
                info.ResName = si.resName.list[0];
                infos.Add(info);
            }
        }

        protected override void OpenCustom()
        {
            Win.SetSize(Screen.currentResolution.width, Screen.currentResolution.height);
        }
        #endregion

        #region 公开方法

        public bool Load()
        {
            bool success = true;
            try
            {
                SceneInfoManager.instance.Load("table");
            }
            catch (Exception e)
            {

                string error = string.Format("加载 C 场景设置表.xls发生错误:{0}", e.Message);
                EditorUtility.DisplayDialog("错误", error, "确定");
                Win.Close();
                success = false;
            }
            return success;
        }

        public override void OnCompiled()
        {
            SetInfos();
        }
        #endregion
    }
}