using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.12.03
    /// BG:日期显示计时
    /// </summary>
    public class DateTimer : Timer
    {
        #region 字段
        /// <summary>
        /// 提示
        /// </summary>
        private string remain;

        /// <summary>
        /// 结束目标时间
        /// </summary>
        private DateTime endTime;


        #endregion

        #region 属性
        /// <summary>
        /// 剩余时间提示
        /// </summary>
        public string Remain
        {
            get { return remain; }
        }

        /// <summary>
        /// 结束时间
        /// </summary>
        public DateTime EndTime
        {
            get { return endTime; }
        }

        #endregion

        #region 构造方法
        public DateTimer()
        {

        }

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        /// <summary>
        /// 格式化提示信息
        /// </summary>
        protected virtual void Format()
        {
            long ticks = (long)((Seconds - count) * 10000000);
            endTime = DateTime.Now + new TimeSpan(ticks);
            TimeSpan span = TimeSpan.FromTicks(ticks);
            remain = DateTool.Format(span);
        }
        #endregion

        #region 公开方法


        public override void Start()
        {
            base.Start();
            if (Running)
            {
                invl -= Format;
                invl += Format;
                Format();
            }
        }

        public override void Resume()
        {
            base.Resume();
            Format();
        }
        #endregion
    }
}