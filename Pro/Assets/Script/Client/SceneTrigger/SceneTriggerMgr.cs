using System;
using Phantom;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        a7d653bd-6ad6-44ab-883d-15191e12d43a
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/5 22:43:50
    /// BG:场景流程树触发管理
    /// </summary>
    public static class SceneTriggerMgr
    {
        #region 字段
        private static bool stoping;
        /// <summary>
        /// 触发列表
        /// </summary>
        private static List<SceneTriggerBase> triggers = new List<SceneTriggerBase>();

        /// <summary>
        /// 流程树字典
        /// </summary>
        private static Dictionary<string, SceneTriggerBase> dic = new Dictionary<string, SceneTriggerBase>();
        #endregion

        #region 属性

        /// <summary>
        /// true:停止更新检查
        /// </summary>
        public static bool Stoping
        {
            get { return stoping; }
            set { stoping = value; }
        }

        #endregion

        #region 构造方法
        static SceneTriggerMgr()
        {
            if (Application.isPlaying)
            {
                FlowChartMgr.remove += Remove;
            }
        }
        #endregion

        #region 私有方法
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Update()
        {
            if (Stoping) return;
            if (triggers.Count == 0) return;
            int beg = triggers.Count - 1;
            int length = triggers.Count;
            for (int i = beg; i > -1; i--)
            {
                triggers[i].Update();
            }
        }

        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="trigger"></param>
        public static void Add(SceneTriggerBase trigger)
        {
            if (trigger == null) return;
            string triggerName = trigger.Data.triggerName;
            if (dic.ContainsKey(triggerName)) return;
            if (triggers.Contains(trigger)) return;
            triggers.Add(trigger);
            dic.Add(triggerName, trigger);
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="trigger"></param>
        public static void Remove(SceneTriggerBase trigger)
        {
            if (trigger == null) return;
            string triggerName = trigger.Data.triggerName;
            if (!dic.ContainsKey(triggerName)) return;
            dic.Remove(triggerName);
            triggers.Remove(trigger);
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="triggerName">触发器名称</param>
        public static void Remove(string triggerName)
        {
            if (!dic.ContainsKey(triggerName)) return;
            SceneTriggerBase trigger = dic[triggerName];
            trigger.Dispose();
        }

        /// <summary>
        /// 根据场景信息创建
        /// </summary>
        /// <param name="info">场景信息</param>
        public static void Create(SceneInfo info)
        {
            if (info == null) return;
            int length = info.trigger.list.Count;
            for (int i = 0; i < length; i++)
            {
                string triggerID = info.trigger.list[i];
                SceneTrigger st = SceneTriggerManager.instance.Find(Convert.ToUInt32(triggerID));
                if (st == null)
                {
                    iTrace.Error("Loong", "No SceneTrigger with ID:{0}", triggerID);
                }
                else if (string.IsNullOrEmpty(st.triggerName))
                {
                    iTrace.Error("Loong", "No config FlowTree with ID为", triggerID);
                }
                else
                {
                    var trigger = ObjPool.Instance.Get<SceneRectTrigger>();
                    trigger.Data = st;
                    Add(trigger);
                }
            }
        }


        /// <summary>
        /// 预加载流程树对象
        /// </summary>
        public static void Preload(SceneInfo info)
        {
            if (info == null) return;
            int length = info.trigger.list.Count;
            for (int i = 0; i < length; i++)
            {
                string triggerID = info.trigger.list[i];
                SceneTrigger st = SceneTriggerManager.instance.Find(Convert.ToUInt32(triggerID));
                if (st == null)
                {
                    iTrace.Error("Loong", "No SceneTrigger Config with ID:{0}", triggerID);
                }
                else
                {
                    AssetMgr.Instance.Add(st.triggerName, Suffix.Bytes, FlowChartMgr.Add);
                }
            }
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            dic.Clear();
            stoping = false;
            ListTool.Clear<SceneTriggerBase>(triggers);
        }
        #endregion
    }
}