//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 11:46:48
// 混淆代码
//=============================================================================

using System;
using System.IO;
using Loong.Edit;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    using Random = UnityEngine.Random;
    //k:旧类型,v新类型
    using TypeDic = Dictionary<string, string>;

    public class ConfuseCode : ConfuseBase
    {
        #region 字段
        public ConfuseCfg cfg = null;

        public ConfuseCodeCfg codeCfg = null;

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ConfuseCode()
        {

        }

        public ConfuseCode(ConfuseCfg cfg, ConfuseCodeCfg codeCfg)
        {
            this.cfg = cfg;
            this.codeCfg = codeCfg;
        }
        #endregion

        #region 私有方法
        private string GetType(string type)
        {
            return string.Format("{0}{1}{2:X}", type, codeCfg.flag, cfg.freq);
        }

        /// <summary>
        /// 获取混淆类型字典
        /// k:原类型, v:目标类型
        /// </summary>
        /// <returns></returns>
        private TypeDic GetTypeDic()
        {
            var dic = new TypeDic();
            var srcTypes = CodeUtil.GetStrs(codeCfg.srcTypePath);
            var destTypes = CodeUtil.GetStrs(codeCfg.destTypePath);

            int srcLen = srcTypes.Count;
            for (int i = 0; i < srcLen; i++)
            {
                if (destTypes.Count < 1) break;
                var srcType = srcTypes[i];
                var destIdx = Random.Range(0, destTypes.Count);
                var destType = destTypes[destIdx];
                ListTool.Remove<string>(destTypes, destIdx);

                destType = GetType(destType);
                dic.Add(srcType, destType);
            }
            return dic;
        }


        private void Replace(TypeDic dic)
        {
            var pDir = Directory.GetCurrentDirectory();
            var dirs = codeCfg.scriptDirs;
            int length = dirs.Count;
            for (int i = 0; i < length; i++)
            {
                var dir = dirs[i];
                var fullDir = Path.Combine(pDir, dir);
                if (!Directory.Exists(fullDir)) continue;
                Replace(dic, fullDir);
            }
        }

        private void Replace(TypeDic dic, string dir)
        {
            var title = "替换:" + dir;
            var destDir = codeCfg.cacheDir;
            var curDirLen = Directory.GetCurrentDirectory().Length + 1;
            var files = Directory.GetFiles(dir, "*.cs", SearchOption.AllDirectories);
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                var rPath = file.Substring(curDirLen);
                ProgressBarUtil.Show(title, rPath, i / length);
                var destPath = Path.Combine(destDir, rPath);
                var destFullDir = Path.GetDirectoryName(destPath);
                if (!Directory.Exists(destFullDir)) Directory.CreateDirectory(destFullDir);
                ReplaceFile(dic, file, destPath);
            }
        }

        private void ReplaceFile(TypeDic dic, string src, string dest)
        {
            FileStream srcFs = null;
            FileStream destFs = null;
            StreamReader reader = null;
            StreamWriter writer = null;
            try
            {
                srcFs = File.OpenRead(src);
                reader = new StreamReader(srcFs, Encoding.UTF8);
                destFs = new FileStream(dest, FileMode.Create);
                writer = new StreamWriter(destFs, Encoding.UTF8);
                string line = null;
                while ((line = reader.ReadLine()) != null)
                {
                    line = ReplaceStr(dic, line);
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
            }

        }

        private string ReplaceStr(TypeDic dic, string str)
        {
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var cur = em.Current;
                str = str.Replace(cur.Key, cur.Value);
            }
            return str;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Apply()
        {
            ProgressBarUtil.Max = 50;
            var dic = GetTypeDic();
            Replace(dic);

            ProgressBarUtil.Clear();
        }
        #endregion
    }
}