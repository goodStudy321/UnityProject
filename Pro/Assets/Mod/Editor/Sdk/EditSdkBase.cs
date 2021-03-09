/*=============================================================================
 * Copyright (C) 2016, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 14:30:04
 ============================================================================*/

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;

    /// <summary>
    /// SDK处理基类
    /// </summary>
    public abstract class EditSdkBase
    {
        #region 字段
        public virtual string Plat
        {
            get { return null; }
        }

        /// <summary>
        /// SDK预处理指令键值
        /// </summary>
        public virtual string SdkKey
        {
            get { return null; }
        }

        /// <summary>
        /// isdk预处理指令字典 k:预处理指令字符 v:sdk文件夹名
        /// </summary>
        public virtual StrDic CmdDic
        {
            get { return null; }
        }


        public virtual string Des { get; }

        public virtual string AppName { get; }

        public virtual string BundleID { get; }



        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected string GetPath(string sdkName, string name)
        {
            var path = SdkUtil.GetResDir(sdkName) + "/" + name;
            return path;
        }

        protected void SetBundleID(BuildTargetGroup group , string bundleID)
        {
            PlayerSettings.SetApplicationIdentifier(group, bundleID);
        }

        #endregion

        #region 公开方法
        /// <summary>
        /// 开始
        /// </summary>
        /// <param name="dic">命令行参数</param>
        public virtual void Beg(StrDic dic)
        {
            SdkUtil.Add(dic, CmdDic, Plat, SdkKey);
            PlayerSettings.productName = AppName;
        }

        /// <summary>
        /// 结束
        /// </summary>
        /// <param name="dic">命令行参数</param>
        /// <param name="dic">工程路径</param>
        public virtual void End(StrDic dic, string proPath)
        {
            SdkUtil.Remove(dic, CmdDic, Plat, SdkKey);
        }
        #endregion
    }
}