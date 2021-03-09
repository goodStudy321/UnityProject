#if LOONG_DOWNLOAD_PACKAGE
/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

using System.IO;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 启动安装工厂
    /// </summary>
    public static class ProcessInstallFty
    {
#region 字段

        /// <summary>
        /// 不同平台实现的安装字典
        /// </summary>
        private static Dictionary<RuntimePlatform, IProcessInstall> dic = new Dictionary<RuntimePlatform, IProcessInstall>();
#endregion

#region 属性

#endregion

#region 构造方法
        static ProcessInstallFty()
        {
            SetDic();
        }
#endregion

#region 私有方法
        private static void SetDic()
        {
            dic.Add(RuntimePlatform.Android, new AndroidProcessInstall());
            dic.Add(RuntimePlatform.IPhonePlayer, new IosProcessInstall());
            dic.Add(RuntimePlatform.WindowsEditor, new GenericProcessInstall());
            dic.Add(RuntimePlatform.WindowsPlayer, new GenericProcessInstall());
            dic.Add(RuntimePlatform.OSXEditor, new GenericProcessInstall());
            dic.Add(RuntimePlatform.OSXPlayer, new GenericProcessInstall());
        }
#endregion

#region 保护方法

#endregion

#region 公开方法
        /// <summary>
        /// 启动安装/当前平台
        /// </summary>
        public static void Start(string path)
        {
            Start(Application.platform, path);
        }

        /// <summary>
        /// 启动安装/可指定平台
        /// </summary>
        public static void Start(RuntimePlatform platform, string path)
        {
            if (File.Exists(path))
            {
                if (dic.ContainsKey(platform))
                {
                    dic[platform].Start(path);
                }
                else
                {
                    iTrace.Error("Loong", string.Format("没有实现平台{0}的启动安装", platform));
                }
            }
            else
            {
                iTrace.Error("Loong", string.Format("安装文件:{0},不存在", path));
            }
        }
#endregion
    }
}
#endif