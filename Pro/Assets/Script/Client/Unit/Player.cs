#if UNITY_EDITOR
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:玩家
    /// </summary>
    [Serializable]
    public class Player
    {
        #region 字段
        private Animation anim = null;

        private Transform tranself = null;

        private static Player instance = null;

        private PlayerState state = PlayerState.Idle;

        [SerializeField]
        private StatusAction status = new StatusAction();

        #endregion

        #region 属性

        public PlayerState State
        {
            get { return state; }
            set { state = value; }
        }


        /// <summary>
        /// 动画组件
        /// </summary>
        public Animation Anim
        {
            get { return anim; }
            set { anim = value; }
        }

        /// <summary>
        /// 动作状态
        /// </summary>
        public StatusAction Status
        {
            get { return status; }
            set { status = value; }
        }

        /// <summary>
        /// 变换组件
        /// </summary>
        public Transform transform
        {
            get { return tranself; }
            set { tranself = value; }
        }


        public static Player Instance
        {
            get { return instance; }
            set { instance = value; }
        }


        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public Player()
        {

        }
        #endregion

        #region 私有方法
        private void ChangeStatus(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (State == PlayerState.Skill)
            {
#if UNITY_EDITOR
                UIEditTip.Error("在技能状态中无法,无法切换技能");
#endif
            }
            else
            {
                State = PlayerState.Skill;
                Status.Set(name);
            }
        }

        private void Control()
        {
            if (Input.GetKeyDown(KeyCode.Keypad1))
            {
                ChangeStatus(ActionGroupName.Skill1);
            }
            else if (Input.GetKeyDown(KeyCode.Keypad2))
            {
                ChangeStatus(ActionGroupName.Skill2);
            }
            else if (Input.GetKeyDown(KeyCode.Keypad3))
            {
                ChangeStatus(ActionGroupName.Skill3);
            }
            else if (iInputMgr.HV)
            {
                if (State == PlayerState.Idle)
                {
                    State = PlayerState.Move;
                    Status.Set(ActionGroupName.Move);
                }
            }
            else
            {
                if (State == PlayerState.Move)
                {
                    State = PlayerState.Idle;
                    Status.Set(ActionGroupName.Idle);
                }
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init()
        {
            instance = this;
            Status.Anim = anim;
            Status.Init();
            Status.Set(ActionGroupName.Idle);
        }

        public void Update()
        {
            if (transform == null) return;
            Status.Update();
            Control();
        }

        public void ChangeIdle()
        {
            State = PlayerState.Idle;
            Status.Set(ActionGroupName.Idle);
        }
        #endregion
    }
}
#endif