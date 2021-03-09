using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:手势基类
    /// </summary>
    public class GestureBase
    {
        #region 字段

        private bool onUI = false;

        private bool alock = false;

        private ProcessState process = ProcessState.None;

        #endregion

        #region 属性

        /// <summary>
        /// 锁定
        /// </summary>
        public bool Lock
        {
            get
            {
                return alock;
            }
            set
            {
                alock = value;
                SetLock(value);
            }
        }

        /// <summary>
        /// 流程状态
        /// </summary>
        public ProcessState Process
        {
            get { return process; }
            protected set { process = value; }
        }

        #endregion

        #region 委托事件
        /// <summary>
        /// 进入事件
        /// </summary>
        public event Action enter = null;

        /// <summary>
        /// 进入事件,如果在UI上不执行
        /// </summary>
        public event Action enterNotOnUI = null;

        /// <summary>
        /// 更新事件
        /// </summary>
        public event Action update = null;

        /// <summary>
        /// 更新事件,如果进入的时候,检查到在UI上,则此事件不执行
        /// </summary>
        public event Action updateNotOnUI = null;

        /// <summary>
        /// 离开事件
        /// </summary>
        public event Action exit = null;

        /// <summary>
        /// 离开事件,如果进入的时候,检查到在UI上,则此事件不执行
        /// </summary>
        public event Action exitNotOnUI = null;

        #endregion

        #region 构造方法
        public GestureBase()
        {

        }
        #endregion

        #region 私有方法
        private void None()
        {
            GestureNone();
            if (Process == ProcessState.Enter)
            {
                onUI = UITool.On ? true : false;
            }
        }

        private void Enter()
        {
            GestureEnter();
            if (enter != null) enter();
            if (onUI) return;
            if (enterNotOnUI != null) enterNotOnUI();
        }

        private void Execute()
        {
            GestureExecute();
            if (update != null) update();
            if (!onUI) if (updateNotOnUI != null) updateNotOnUI();
        }

        private void Exit()
        {
            GestureExit();
            if (exit != null) exit();
            if (!onUI) if (exitNotOnUI != null) exitNotOnUI();
            onUI = false;

        }
        #endregion

        #region 保护方法

        /// <summary>
        /// 无手势
        /// </summary>
        protected virtual void GestureNone()
        {

        }

        /// <summary>
        /// 进入
        /// </summary>
        protected virtual void GestureEnter()
        {

        }

        /// <summary>
        /// 解析
        /// </summary>
        protected virtual void GestureExecute()
        {

        }

        /// <summary>
        /// 离开
        /// </summary>
        protected virtual void GestureExit()
        {

        }

        /// <summary>
        /// 设置锁定
        /// </summary>
        /// <param name="value"></param>
        protected virtual void SetLock(bool value)
        {
            if (value) process = ProcessState.None;
        }
        #endregion

        #region 公开方法
        public void Update()
        {
            if (Lock) return;
            switch (process)
            {
                case ProcessState.None:
                    None();
                    break;
                case ProcessState.Enter:
                    Process = ProcessState.Execute;
                    Enter();
                    break;
                case ProcessState.Execute:
                    Execute();
                    break;
                case ProcessState.Exit:
                    Exit();
                    Process = ProcessState.None;
                    break;
                default: break;
            }
        }
        #endregion
    }
}