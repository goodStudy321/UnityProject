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
     * GUID:        deb0ecd5-7805-4563-aa0c-a2da552e48b5
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/5 19:33:01
    /// BG:场景触发器选择视图
    /// </summary>
    public class SceneTriggerSelectView : SelectViewBase<SceneTriggerSelectInfo>
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
            Win.SetTitle("选择窗口");
        }

        protected override void SetInfos()
        {
            Load();
            infos.Clear();
            int length = SceneTriggerManager.instance.Size;
            for (int i = 0; i < length; i++)
            {
                SceneTrigger st = SceneTriggerManager.instance.Get(i);
                SceneTriggerSelectInfo info = new SceneTriggerSelectInfo();
                info.ID = st.iD;
                info.TriggerName = st.triggerName;
                infos.Add(info);
            }
        }


        #endregion

        #region 公开方法

        public void Load()
        {
            try
            {
                SceneTriggerManager.instance.Load("table");
            }
            catch (Exception e)
            {

                string error = string.Format("加载C 场景Trigger配置表.xls发生错误:{0}", e.Message);
                EditorUtility.DisplayDialog("错误", error, "确定");
                Win.Close();
            }
        }

        public override void OnCompiled()
        {
            SetInfos();
        }
        #endregion
    }
}