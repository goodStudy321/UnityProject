using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        dbe01d22-75e3-40a7-8284-7a961c1baa6d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/6 10:23:25
    /// BG:场景流程树触发基类
    /// </summary>
    public abstract class SceneTriggerBase : IDisposable
    {
        #region 字段
        private ProcessState state;

        private SceneTrigger data = null;

        #endregion

        #region 属性

        public ProcessState State
        {
            get { return state; }
            set { state = value; }
        }

        /// <summary>
        /// 场景触发器配置数据
        /// </summary>
        public SceneTrigger Data
        {
            get { return data; }
            set
            {
                data = value;
                SetData();
            }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 设置数据
        /// </summary>
        protected virtual void SetData()
        {

        }
        /// <summary>
        /// 包含
        /// </summary>
        protected virtual bool Contains()
        {
            return false;
        }

        /// <summary>
        /// 进入
        /// </summary>
        protected abstract void Enter();

        /// <summary>
        /// 执行
        /// </summary>
        protected abstract void Run();

        /// <summary>
        /// 离开
        /// </summary>
        protected abstract void Exit();
        #endregion

        #region 公开方法
        public void Update()
        {
            switch (State)
            {
                case ProcessState.None:
                    if (Contains()) State = ProcessState.Enter;
                    break;
                case ProcessState.Enter:
                    Enter(); State = ProcessState.Execute;
                    break;
                case ProcessState.Execute:
                    Run();
                    break;
                case ProcessState.Exit:
                    Exit(); State = ProcessState.None;
                    break;
                default:
                    break;
            }
        }

        public virtual void Dispose()
        {

        }

        #endregion
    }
}