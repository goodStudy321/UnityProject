//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/1 10:57:07
// Gradle后处理
//*****************************************************************************

using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// PostGradle
    /// </summary>
    public abstract class PostGradle
    {
        #region 字段
        private string gradleName = "build.gradle";
        private string gradleProName = "gradle.properties";

        private string rootDir = null;
        private string unityDir = null;
        private string launchDir = null;
        private string rootGrale = null;
        private string rootGralePro = null;
        private string unityGradle = null;
        private string launchGradle = null;
        #endregion

        #region 属性
        /// <summary>
        /// Gralde文件名称
        /// </summary>
        public string GradleName
        {
            get { return gradleName; }
        }

        /// <summary>
        /// 根目录
        /// </summary>
        public string RootDir
        {
            get { return rootDir; }
            private set { rootDir = value; }
        }

        /// <summary>
        /// 根-build.gradle路径
        /// </summary>
        public string RootGradle
        {
            get { return rootGrale; }
            private set { rootGrale = value; }
        }

        /// <summary>
        /// 根-gradle.properties路径
        /// </summary>
        public string RootGradlePro
        {
            get { return rootGralePro; }
            private set { rootGralePro = value; }
        }

        /// <summary>
        /// Launcher目录
        /// </summary>
        public string LaunchDir
        {
            get { return launchDir; }
            private set { launchDir = value; }
        }

        /// <summary>
        /// Launcher-build.gradle路径
        /// </summary>
        public string LaunchGradle
        {
            get { return launchGradle; }
            private set { launchGradle = value; }
        }


        /// <summary>
        /// unity目录
        /// </summary>
        public string UnityDir
        {
            get { return unityDir; }
            private set { unityDir = value; }
        }


        /// <summary>
        /// unity-build.gralde路径
        /// </summary>
        public string UnityGradle
        {
            get { return unityGradle; }
            private set { unityGradle = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法


        protected abstract void OnPostGradle();
        #endregion

        #region 公开方法

        public void OnPostGradle(string path)
        {
            var rDir = Path.GetDirectoryName(path);
            var curDir = Directory.GetCurrentDirectory();
            UnityDir = Path.Combine(curDir, path);
            var luncherPro = Path.Combine(rDir, "launcher");
            LaunchDir = Path.Combine(curDir, luncherPro);
            RootDir = Path.Combine(curDir, rDir);

            RootGradle = Path.Combine(rootDir, gradleName);
            RootGradlePro = Path.Combine(rootDir, gradleProName);
            UnityGradle = Path.Combine(unityDir, gradleName);
            LaunchGradle = Path.Combine(launchDir, gradleName);

            OnPostGradle();
        }
        #endregion
    }
}