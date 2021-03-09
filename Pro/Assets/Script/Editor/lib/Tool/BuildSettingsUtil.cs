/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/10 20:04:38
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 编辑器设置工具
    /// </summary>
    public static class BuildSettingsUtil
    {
        #region 字段

        #endregion

        #region 属性
        /// <summary>
        /// 目标平台
        /// </summary>
        public static BuildTarget Target
        {
            get { return EditorUserBuildSettings.activeBuildTarget; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取场景设置中激活的场景列表
        /// </summary>
        /// <returns></returns>
        public static List<string> GetActiveLevels()
        {
            List<string> levels = null;
            EditorBuildSettingsScene[] scenes = EditorBuildSettings.scenes;
            if (scenes == null || scenes.Length == 0)
            {
                return null;
            }
            int length = scenes.Length;
            for (int i = 0; i < length; i++)
            {
                if (scenes[i].enabled)
                {
                    if (levels == null) levels = new List<string>();
                    levels.Add(scenes[i].path);
                }
            }
            return levels;
        }

        /// <summary>
        /// 获取当前工程设置的目标组
        /// </summary>
        /// <returns></returns>
        public static BuildTargetGroup GetGroup()
        {
            BuildTargetGroup group = BuildTargetGroup.Android;
            string target = EditorUserBuildSettings.activeBuildTarget.ToString().ToLower();
            if (target.Equals("android"))
                group = BuildTargetGroup.Android;
            else if (target.Contains("standalone"))
                group = BuildTargetGroup.Standalone;
            else if (target.Equals("iphone"))
                group = (BuildTargetGroup)Enum.Parse(typeof(BuildTargetGroup), "iPhone");
            else if (target.Equals("ios"))
                group = BuildTargetGroup.iOS;
            else
                Debug.LogErrorFormat("Loong, 获取平台组:{0},失败", target);
            return group;
        }
        #endregion
    }
}