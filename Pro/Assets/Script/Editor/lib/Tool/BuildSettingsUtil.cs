using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    public static class BuildSettingsUtil
    {
        public static BuildTarget Target
        {
            get { return EditorUserBuildSettings.activeBuildTarget; }
        }

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
                Debug.LogErrorFormat("Hello, 获取平台组: {0}, 失败", target);
            return group;
        }
    }
}

