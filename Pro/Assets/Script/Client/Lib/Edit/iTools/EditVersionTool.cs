#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2015-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        93a216f3-9a42-4c9c-8e03-5e81ea5b9de0
    */

    /// <summary>
    /// AU:Loong
    /// TM:2015.5.6
    /// BG:编辑器版本号工具
    /// </summary>
    public static class EditVersionTool
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

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取工程设置版本号,并会做有效性验证
        /// </summary>
        /// <returns></returns>
        public static Version Get()
        {
            Version ver = null;
            string verStr = PlayerSettings.bundleVersion;

            if (string.IsNullOrEmpty(verStr))
            {
                verStr = "1.0.0";
                ver = new Version(verStr);
                PlayerSettings.bundleVersion = verStr;

            }
            else
            {
                uint major = 1;
                uint minor = 0;
                uint build = 0;
                string[] arr = verStr.Split('.');
                if (arr != null && arr.Length != 0)
                {
                    int length = arr.Length;
                    if (length == 1)
                    {
                        if (!uint.TryParse(arr[0], out major)) major = 1;
                    }
                    else if (length == 2)
                    {
                        if (!uint.TryParse(arr[0], out major)) major = 1;
                        uint.TryParse(arr[1], out minor);
                    }
                    else if (length == 3)
                    {
                        if (!uint.TryParse(arr[0], out major)) major = 1;
                        uint.TryParse(arr[1], out minor);
                        uint.TryParse(arr[2], out build);
                    }
                }
                verStr = string.Format("{0}.{1}.{2}", major, minor, build);
                PlayerSettings.bundleVersion = verStr;
                ver = new Version(verStr);
            }
            return ver;
        }
        #endregion
    }
}
#endif