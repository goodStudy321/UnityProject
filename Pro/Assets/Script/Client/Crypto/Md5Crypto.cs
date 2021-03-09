/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013.8.12 20:09:25
 * 对于文件,GenFile方法占用内存最小
 ============================================================================*/

using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Security.Cryptography;

namespace Loong.Game
{
    /// <summary>
    /// MD5(信息摘要)
    /// </summary>
    public static class Md5Crypto
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 计算MD5并返回字符串
        /// </summary>
        /// <param name="dest">目标字节数组</param>
        /// <returns></returns>
        private static string Calc(byte[] dest)
        {
            StringBuilder sb = new StringBuilder();
            int length = dest.Length;
            for (int i = 0; i < length; i++)
            {
                byte b = dest[i];
                sb.Append(b.ToString("X2"));
            }
            return sb.ToString();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 生成字节数组的MD5
        /// </summary>
        /// <param name="bytes">字节数组</param>
        /// <returns></returns>
        public static string Gen(byte[] bytes)
        {
            if (bytes == null || bytes.Length < 1) return null;
            MD5 md5 = MD5.Create();
            byte[] dest = md5.ComputeHash(bytes);
            return Calc(dest);
        }

        /// <summary>
        /// 生成字符串的MD5
        /// </summary>
        /// <param name="text">字符串</param>
        /// <returns></returns>
        public static string Gen(string text)
        {
            if (string.IsNullOrEmpty(text)) return null;
            byte[] bytes = Encoding.UTF8.GetBytes(text);
            return Gen(bytes);
        }

        /// <summary>
        /// 生成流的MD5
        /// </summary>
        /// <param name="stream"></param>
        /// <returns></returns>
        public static string Gen(Stream stream)
        {
            if (stream == null) return null;
            MD5 md5 = MD5.Create();
            byte[] dest = md5.ComputeHash(stream);
            return Calc(dest);
        }

        /// <summary>
        /// 生成文件的MD5
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <returns></returns>
        public static string GenFile(string path)
        {
            if (string.IsNullOrEmpty(path)) return null;
            if (!File.Exists(path)) return null;
            string md5 = null;
            using (FileStream stream = File.OpenRead(path))
            {
                md5 = Gen(stream);
            }
            return md5;
        }


        /// <summary>
        /// 快速生成文件的MD5
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GenFileFast(string path)
        {
            if (string.IsNullOrEmpty(path)) return null;
            if (!File.Exists(path)) return null;
            string str = null;
            int bufSize = 1024 * 16;
            byte[] buf = new byte[bufSize];
            FileStream stream = null;
            MD5 md5 = null;
            try
            {
                md5 = MD5.Create();
                stream = File.OpenRead(path);
                int readLen = 0;
                var output = new byte[bufSize];
                while ((readLen = stream.Read(buf, 0, bufSize)) > 0)
                {
                    md5.TransformBlock(buf, 0, readLen, output, 0);
                }
                md5.TransformFinalBlock(buf, 0, 0);
                str = BitConverter.ToString(md5.Hash);
                str = str.Replace("-", "");
                str = str.ToLower();
            }
            catch (Exception)
            {
            }
            finally
            {
                if (md5 != null) md5.Clear();
                if (stream != null) stream.Dispose();
            }
            return str;
        }


        #endregion
    }
}