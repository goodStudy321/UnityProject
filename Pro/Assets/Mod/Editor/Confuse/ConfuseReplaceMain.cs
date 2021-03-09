//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/29 12:16:34
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseReplaceMain
    /// </summary>
    public class ConfuseReplaceMain
    {
        #region 字段
        public static readonly List<string> K_MAINS = new List<string>()
        {
            "//LOONG_CONFUSE_MAIN_AWAKE",
            "//LOONG_CONFUSE_MAIN_SETTING",
            "//LOONG_CONFUSE_MAIN_STARTUP",
            "//LOONG_CONFUSE_MAIN_REALBEG",
            "//LOONG_CONFUSE_MAIN_REALEND",
        };


        private ConfuseCodeCfg codeCfg = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ConfuseReplaceMain()
        {

        }

        public ConfuseReplaceMain(ConfuseCodeCfg codeCfg)
        {
            this.codeCfg = codeCfg;
        }
        #endregion

        #region 私有方法
        private string Replace(List<ICodeClass> codeClasses, string line)
        {
            var newLine = line.Trim();
            int length = K_MAINS.Count;
            for (int i = 0; i < length; i++)
            {
                var k = K_MAINS[i];
                if (newLine != k) continue;
                newLine = ConfuseUnusedCreateFty.Create(codeClasses);
                return newLine;
            }

            return line;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Applay(List<ICodeClass> codeClasses)
        {
            var src = codeCfg.GetMainPathExter();
            var fileName = Path.GetFileName(src);
            var srcDir = Path.GetDirectoryName(src);

            var destFileName = DateTime.Now.Ticks + "_" + fileName;
            var dest = Path.Combine(srcDir, destFileName);

            File.Copy(src, dest, true);

            FileStream srcFs = null;
            FileStream destFs = null;
            StreamReader reader = null;
            StreamWriter writer = null;
            try
            {
                srcFs = File.OpenRead(dest);
                reader = new StreamReader(srcFs, Encoding.UTF8);
                destFs = new FileStream(src, FileMode.Create);
                writer = new StreamWriter(destFs, Encoding.UTF8);
                string line = null;
                while ((line = reader.ReadLine()) != null)
                {
                    //line = line.Trim();
                    if (!string.IsNullOrEmpty(line))
                    {
                        line = Replace(codeClasses, line);
                    }
                    writer.WriteLine(line);
                }
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "replaceFile:{0}, to:{1}, err:{2}", src, dest, e.Message);
            }
            finally
            {
                if (reader != null) reader.Dispose();
                if (writer != null) writer.Dispose();
                if (srcFs != null) srcFs.Dispose();
                if (destFs != null) destFs.Dispose();
                if (File.Exists(dest)) File.Delete(dest);
            }
        }
        #endregion
    }
}