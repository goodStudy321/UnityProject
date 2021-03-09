using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        0721b895-b50e-46fc-bad0-f3c42e1296be
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/4 11:57:39
    /// BG:单位属性监听
    /// </summary>
    public abstract class UnitPropLsnr : IDisposable
    {
        #region 字段

        /// <summary>
        /// 结束
        /// </summary>
        private bool isOver = false;

        /// <summary>
        /// 校验事件
        /// </summary>
        private Func<bool> checkEvent = null;

        /// <summary>
        /// 结束事件
        /// </summary>
        private Action completeEvent = null;

        /// <summary>
        /// 单位属性信息
        /// </summary>
        private UnitPropertyInfo info = null;

        #endregion

        #region 属性


        public bool IsOver
        {
            get { return isOver; }
            set
            {
                isOver = value;
                if (isOver) ExeComplete();
            }
        }

        public UnitPropertyInfo Info
        {
            get { return info; }
        }
        #endregion

        #region 构造方法
        public UnitPropLsnr(UnitPropertyInfo info)
        {
            this.info = info;
        }
        #endregion

        #region 私有方法
        
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public abstract void Add();

        public virtual void Dispose()
        {
            completeEvent = null;
            checkEvent = null;
        }

        /// <summary>
        /// 添加结束事件
        /// </summary>
        /// <param name="value"></param>
        public void AddCompleteEvent(Action value)
        {
            completeEvent += value;
        }

        /// <summary>
        /// 移除结束事件
        /// </summary>
        /// <param name="value"></param>
        public void RemoveCompleteEvent(Action value)
        {
            completeEvent -= value;
        }

        /// <summary>
        /// 解析结束事件
        /// </summary>
        public void ExeComplete()
        {
            if (completeEvent != null) completeEvent(); completeEvent = null;
        }

        /// <summary>
        /// 添加校验事件
        /// </summary>
        /// <param name="value"></param>
        public void AddCheckEvent(Func<bool> value)
        {
            checkEvent += value;
        }

        /// <summary>
        /// 移除校验事件
        /// </summary>
        /// <param name="value"></param>
        public void RemoveCheckEvent(Func<bool> value)
        {
            checkEvent -= value;
        }

        /// <summary>
        /// 执行校验事件 返回true 可以通过
        /// </summary>
        /// <returns></returns>
        public bool ExecuteCheckEvent()
        {
            if (checkEvent == null) return true;
            return checkEvent();
        }
        #endregion
    }
}