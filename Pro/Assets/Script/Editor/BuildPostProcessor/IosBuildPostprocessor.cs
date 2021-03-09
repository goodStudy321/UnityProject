using System;
using Loong.iOS;
using System.IO;
using UnityEngine;
using UnityEditor;
using System.Collections;
using UnityEditor.iOS.Xcode;
using System.Collections.Generic;

namespace Loong.Post
{

    /// <summary>
    /// AU:Loong
    /// TM:2016.4.10
    /// BG:Ios发布后处理
    /// </summary>
    public class IosBuildPostprocessor : BuildPostProcessorBase
    {
        #region 字段

        /// <summary>
        /// 工程名称
        /// </summary>
        private string proName = "Unity-iPhone";

        /// <summary>
        /// 相对工程文件路径
        /// </summary>
        //private string rProPath = "/Unity-iPhone.xcodeproj/project.pbxproj";
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public IosBuildPostprocessor()
        {

        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 设置XCode
        /// </summary>
        /// <param name="proPath">目录</param>
        /// <param name="proFilePath">工程文件完整路径</param>
        private void SetXCode(string proPath, string proFilePath)
        {
            PBXProject pro = new PBXProject();
            pro.ReadFromString(File.ReadAllText(proFilePath));
            var targetGUID = pro.TargetGuidByName(proName);
            pro.SetBuildProperty(targetGUID, "ENABLE_BITCODE", "NO");
            File.WriteAllText(proFilePath, pro.WriteToString());
            //SuitIphoneX(proPath);
        }

        /// <summary>
        /// 适应iPhoneX
        /// </summary>
        /// <param name="path"></param>
        private void SuitIphoneX(string path)
        {
            var src = @"_window         = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];";
            var dest = @"//    _window         = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];

            CGRect winSize = [UIScreen mainScreen].bounds;
            if (winSize.size.width / winSize.size.height > 2) {
                winSize.size.width -= 150;
                winSize.origin.x = 75;
                ::printf(""-> is iphonex aaa hello world\n"");
            } else {
                ::printf(""-> is not iphonex aaa hello world\n"");
            }
            _window = [[UIWindow alloc] initWithFrame: winSize];

            ";
            var uappCtrlPath = path + "/Classes/UnityAppController.mm";
            var uappCtrl = new XClass(uappCtrlPath);
            uappCtrl.Replace(src, dest);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Execute(BuildTarget target, string proPath)
        {
            if (target != BuildTarget.iOS) return;
            Debug.Log(string.Format("打包IOS完成,路径为:{0}", proPath));
            string proFilePath = PBXProject.GetPBXProjectPath(proPath);
            if (File.Exists(proFilePath))
            {
                SetXCode(proPath, proFilePath);
            }
            else
            {
                Debug.LogError(string.Format("Xcode工程文件路径:{0},不存在", proFilePath));
            }
        }
        #endregion
    }
}