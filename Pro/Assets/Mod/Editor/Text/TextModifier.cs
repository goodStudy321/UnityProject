//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/1 10:56:43
//*****************************************************************************

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 文本修改器
    /// </summary>
    public class TextModifier
    {
        #region 字段
        private List<string> lines = new List<string>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 判断行是否包含/等于K
        /// </summary>
        /// <param name="line">行</param>
        /// <param name="k">键</param>
        /// <param name="equal">true:等于, false:</param>
        /// <returns></returns>
        private bool Contains(string line, string k, bool equal)
        {
            return equal ? (line == k) : (line.IndexOf(k) > -1);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 读取要处理的文件
        /// </summary>
        /// <param name="path"></param>
        public void Read(string path)
        {
            if (!File.Exists(path))
            {
                Debug.LogErrorFormat("Loong, {0} not exist!", path); return;
            }

            using (var reader = new StreamReader(path))
            {
                string line = null;
                while ((line = reader.ReadLine()) != null)
                {
                    if (string.IsNullOrEmpty(line)) continue;
                    lines.Add(line);
                }
            }
        }

        /// <summary>
        /// 保存文件
        /// </summary>
        /// <param name="path">文件路径</param>
        public void Save(string path)
        {
            var dir = Path.GetDirectoryName(path);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            using (var write = new StreamWriter(path, false, new UTF8Encoding(false)))
            {
                int length = lines.Count;
                for (int i = 0; i < length; i++)
                {
                    var line = lines[i];
                    write.WriteLine(line);
                }
            }
        }

        /// <summary>
        /// 如果一行包含/等于K，则替换整行
        /// </summary>
        /// <param name="k">键值</param>
        /// <param name="content">替换之后的内容</param>
        /// <param name="equal">true:等于, false:包含</param>
        /// <param name="once">true:检查一次</param>
        public void Replace(string k, string content, bool equal = false, bool once = true)
        {
            if (string.IsNullOrEmpty(k)) return;
            int length = lines.Count;
            var find = false;
            for (int i = 0; i < length; i++)
            {
                var line = lines[i];
                if (equal ? (line != k) : (line.IndexOf(k) < 0)) continue;
                find = true;
                lines[i] = content;
                if (once) return;

            }
            if (find) return;
            Debug.LogErrorFormat("Loong, TextModifier Replace not find :{0}", k);
        }


        /// <summary>
        /// 如果一行包含/等于K,则再此行下追加内容
        /// </summary>
        /// <param name="k">键值</param>
        /// <param name="content">追加内容</param>
        /// <param name="equal">true:等于, false:包含</param>
        /// <param name="once">true:检查一次</param>
        public void WriteBlow(string k, string content, bool equal = false, bool once = true, int idx = 1)
        {
            if (string.IsNullOrEmpty(k)) return;
            var find = false;
            int length = lines.Count;
            for (int i = 0; i < length; i++)
            {
                var line = lines[i];
                if (equal ? (line != k) : (line.IndexOf(k) < 0)) continue;
                find = true;
                int next = i + idx;
                if (next == length)
                {
                    lines.Add(content);
                }
                else
                {
                    lines.Insert(next, content);
                }
                if (once) return;
            }
            if (find) return;

            Debug.LogErrorFormat("Loong, TextModifier WriteBlow not find:{0}", k);
        }


        /// <summary>
        /// 追加一行
        /// </summary>
        /// <param name="content"></param>
        public void WriteLast(string content)
        {
            lines.Add(content);
        }


        /// <summary>
        /// 移除行
        /// </summary>
        /// <param name="idx">索引</param>
        public void Remove(int idx)
        {
            if (idx < 0) return;
            if (idx >= lines.Count) return;
            lines.RemoveAt(idx);
        }
        #endregion
    }
}