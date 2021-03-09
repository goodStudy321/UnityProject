using System;
using UnityEngine;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.12.03
    /// BG:日期时间工具
    /// </summary>
    public static class DateTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 格式化时间跨度
        /// </summary>
        /// <param name="span">时间跨度</param>
        /// <param name="d2h">true:天转换成小时</param>
        /// <param name="dd">天</param>
        /// <param name="hh">时</param>
        /// <param name="mm">分</param>
        /// <param name="ss">秒</param>
        /// <returns></returns>
        public static string Format(TimeSpan span, bool d2h = false, string dd = "天", string hh = "时", string mm = "分", string ss = "秒")
        {
            dd = Phantom.Localization.Instance.GetDes(690037);
            hh = Phantom.Localization.Instance.GetDes(690038);
            mm = Phantom.Localization.Instance.GetDes(690039);
            ss = Phantom.Localization.Instance.GetDes(690040);
            StringBuilder temp = ObjPool.Instance.Get<StringBuilder>();
            temp.Remove(0, temp.Length);
            int days = span.Days;
            int hours = span.Hours;
            if (days > 0)
            {
                if (d2h)
                {
                    hours += days * 24;
                }
                else
                {
                    temp.Append(days).Append(dd);
                }
            }

            if ((hours > 0) || (temp.Length > 0))
            {
                temp.Append(hours).Append(hh);
            }

            int minutes = span.Minutes;
            if ((minutes > 0) || (temp.Length > 0))
            {
                temp.Append(minutes).Append(mm);
            }

            int seconds = span.Seconds;
            if (span.Milliseconds > 0)
            {
                float fMilli = span.Milliseconds * 0.001f;
                int milli = Mathf.RoundToInt(fMilli);
                seconds += milli;
            }
            temp.Append(seconds).Append(ss);
            string str = temp.ToString();
            temp.Remove(0, temp.Length);
            ObjPool.Instance.Add(temp);
            return str;
        }
        #endregion
    }
}