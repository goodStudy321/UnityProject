using Loong;
using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.3.12 
    /// BG:FTP工具
    /// </summary>
    public static class FtpTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void SetPro(float val)
        {
            ProgressBarUtil.Show("", "FTP上传中", val);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 上传文件
        /// </summary>
        /// <param name="data">数据</param>
        /// <param name="src">源文件</param>
        /// <param name="cb">上传完成回调 参数为错误信息,null上传完成</param>
        public static void Upload(FtpView data, string src, Action<FtpBase, bool> cb)
        {
            var ftp = new FTP();
            ftp.LocalPath = src;
            ftp.complete += cb;
            ftp.progress += SetPro;
            ftp.RemotePath = data.RemotePath;
            ftp.UserName = data.UseName;
            ftp.Password = data.Password;
            ftp.Upload();
            EditorUtility.ClearProgressBar();
        }
        #endregion
    }
}