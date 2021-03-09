using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Random = System.Random;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.07.15
    /// BG:GUID工具
    /// </summary>
    public static class GuidTool
    {
        #region 字段
        private static Random rand = null;

        private static Guid guid = Guid.NewGuid();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 获取随机值
        /// </summary>
        /// <returns></returns>
        private static int GetRandom()
        {
            if (rand == null)
            {
                int id = BitConverter.ToInt32(guid.ToByteArray(), 0);
                rand = new Random(id);
            }
            int value = rand.Next(0, 999);
            return value;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 生成日期UID,18位长度
        /// </summary>
        /// <returns></returns>
        public static long GenDateLong()
        {
            string uidStr = GenDateString();
            long uid = long.Parse(uidStr);
            return uid;
        }

        /// <summary>
        /// 生成日期UID,18位长度
        /// </summary>
        public static ulong GenDateUlong()
        {
            string uidStr = GenDateString();
            ulong uid = ulong.Parse(uidStr);
            return uid;
        }


        /// <summary>
        /// 生成日期UID字符,18位长度
        /// </summary>
        /// <returns></returns>
        public static string GenDateString()
        {
            string dateStr = DateTime.Now.ToString("yyMMddHHmmssfff");
            int next = GetRandom();
            string nextStr = next.ToString().PadLeft(3, '0');
            string str = string.Format("{0}{1}", dateStr, nextStr);
            return str;
        }
        #endregion
    }
}