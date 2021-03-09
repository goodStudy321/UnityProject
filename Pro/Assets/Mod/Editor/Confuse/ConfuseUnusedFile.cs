//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 11:46:36
// 无用文件混淆
//=============================================================================

using System;
using System.IO;
using Loong.Edit;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    using Random = UnityEngine.Random;

    ///k:0-begLen,v:数量
    using InfoDic = Dictionary<string, ConfuseUnusedInfo>;
    public class ConfuseUnusedFile : ConfuseBase
    {
        #region 字段
        /// <summary>
        /// 混淆文件总大小
        /// </summary>
        private long size = 0L;

        /// <summary>
        /// 原生文件总大小
        /// </summary>
        private long srcSize = 0L;

        private float percent = 0.2f;

        private int begLen = 4;

        /// <summary>
        /// 发布资源目录
        /// </summary>
        public string dir = "";

        public ConfuseUnusedCfg cfg = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ConfuseUnusedFile()
        {

        }

        public ConfuseUnusedFile(string dir, ConfuseUnusedCfg cfg)
        {
            this.dir = dir;
            this.cfg = cfg;
        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 获取混淆文件名字
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        private string GetFileName(string name)
        {
            var beg = GetFileBeg(name);
            if (beg == null) return null;
            return GetFileNameWithBeg(beg);
        }

        private string GetFileNameWithBeg(string beg, int idx = 0)
        {
            var tick = DateTime.Now.Ticks;
            if (idx < 1) idx = Random.Range(1, 10000);
            var sfxIdx = Random.Range(0, 4);
            var fileSfx = cfg.fileSfxs[sfxIdx];
            var newName = string.Format("{0}_{1}{2}{3:X}.{4}", beg, tick, cfg.fileFlag, idx, fileSfx);
            return newName;
        }

        private string GetFileBeg(string name)
        {
            if (name.Length < begLen) return null;
            var beg = name.Substring(0, begLen);
            beg = beg.ToLower();
            beg = beg.Replace(".", "");
            //beg = beg.Replace("-", "");
            //beg = beg.Replace("_", "");
            return beg;
        }

        /// <summary>
        /// 写入文件
        /// </summary>
        /// <param name="path"></param>
        private void WriteFile(string path)
        {
            using (var fs = new FileStream(path, FileMode.Create))
            {
                using (var write = new BinaryWriter(fs))
                {
                    var lMin = 2000;
                    var lMax = 3500;
                    var randMax = 30;
                    var vMin = short.MinValue;
                    var vMax = short.MaxValue;
                    for (int j = 0; j < 2; j++)
                    {
                        var len = Random.Range(1, randMax);
                        len = Random.Range(1, randMax);
                        for (int i = 0; i < len; i++)
                        {
                            var v = (short)Random.Range(vMin, vMax);
                            write.Write(v);
                            size += 2;
                        }
                        len = Random.Range(1, randMax);
                        for (int i = 0; i < len; i++)
                        {
                            var v = Random.Range(vMin, vMax);
                            write.Write(v);
                            size += 4;
                        }
                        len = Random.Range(lMin, lMax);
                        for (int i = 0; i < len; i++)
                        {
                            long v = Random.Range(vMin, vMax);
                            write.Write(v);
                            size += 8;
                        }
                        len = Random.Range(1, randMax);
                        for (int i = 0; i < len; i++)
                        {
                            var v = (byte)Random.Range(0, byte.MaxValue);
                            write.Write(v);
                            size += 1;
                        }
                    }
                    write.Write(DateTime.Now.Ticks);
                    size += 8;
                }
            }
        }

        /// <summary>
        /// 生成首字母字典
        /// </summary>
        /// <param name="files"></param>
        /// <returns></returns>
        private InfoDic GenDic(List<string> files)
        {

            var title = "生成头部字典";
            var dic = new InfoDic();
            float length = files.Count;
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                var name = Path.GetFileName(path);
                var beg = GetFileBeg(name);
                if (beg == null) continue;
                ProgressBarUtil.Show(title, name, i / length);
                if (dic.ContainsKey(beg))
                {
                    dic[beg].fileCount += 1;
                }
                else
                {
                    dic[beg] = new ConfuseUnusedInfo() { fileCount = 1 };
                }
            }
            return dic;
        }

        private void SetDic(InfoDic dic, int fileLen)
        {
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var info = em.Current.Value;
                var max = cfg.fileCount * info.fileCount / fileLen;
                if (max < 1) max = 1;
                info.max = max;
            }
        }

        /// <summary>
        /// 获取有效文件列表
        /// </summary>
        /// <param name="files"></param>
        /// <returns></returns>
        private List<string> GetFiles(string[] files)
        {
            var lst = new List<string>();
            int length = files.Length;
            lst.Capacity = length / 2;
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                var sfx = Path.GetExtension(file);
                if (sfx == ".meta") continue;
                lst.Add(file);
                var fi = new FileInfo(file);
                srcSize += fi.Length;
            }
            return lst;
        }

        private void Gen(List<string> files, InfoDic dic)
        {
            int count = 0;
            var title = "混淆文件中";
            int length = files.Count;
            float total = cfg.fileCount;
            var destDir = cfg.destDir;
            if (string.IsNullOrEmpty(destDir)) destDir = dir;
            var srcDirLen = dir.Length + 1;
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                var rPath = file.Substring(srcDirLen);
                var name = Path.GetFileNameWithoutExtension(rPath);
                var beg = GetFileBeg(name);
                if (beg == null) continue;
                if (!dic.ContainsKey(beg)) continue;
                var info = dic[beg];
                if (info.IsMax()) continue;
                info.AddIdx();
                var newName = GetFileNameWithBeg(beg, i);
                if (newName == null) continue;
                var rDir = Path.GetDirectoryName(rPath);
                var newDir = Path.Combine(destDir, rDir);
                if (!Directory.Exists(newDir)) Directory.CreateDirectory(newDir);
                var newPath = Path.Combine(newDir, newName);
                ProgressBarUtil.Show(title, newName, count / total);
                ++count;
                if (count > cfg.fileCount) break;
                WriteFile(newPath);
            }
        }

        private int SetTarget(int fileLen)
        {
            if (cfg.fileCount > 0) return cfg.fileCount;
            var len = fileLen * percent / (1 - percent);
            return (int)len;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Apply()
        {
            var arr = Directory.GetFiles(dir, "*", SearchOption.AllDirectories);
            if (arr == null) return;
            var files = GetFiles(arr);
            ProgressBarUtil.Max = 50;
            var fileCount = SetTarget(files.Count);
            cfg.fileCount = fileCount;
            var dic = GenDic(files);
            SetDic(dic, files.Count);
            Gen(files, dic);
            ProgressBarUtil.Clear();
            float len = files.Count;
            var ty = this.GetType().Name;
            var total = (len + fileCount);
            var lenPer = 100 * fileCount / total;
            var totalSize = (1f * (size + srcSize));
            var sizeStr = ByteUtil.GetSizeStr(size);
            var sizePer = 100 * size / totalSize;
            Debug.LogFormat("{0}, count:{1}/({2}+{3})={4:f2}%, size:{5}({6})/({7}+{8})={9:f2}%,", ty, fileCount, fileCount, len, lenPer, size, sizeStr, size, srcSize, sizePer);
        }
        #endregion
    }
}