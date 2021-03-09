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
    /// BG:玩家移动
    /// </summary>
    public static class PlayerMove
    {
        #region 字段
        private static float speed = 0;

        private static Transform target = null;

        /// <summary>
        /// 上方
        /// </summary>
        private static Vector3 up = Vector3.up;

        /// <summary>
        /// 左前方
        /// </summary>
        private static Vector3 left = Vector3.zero;

        /// <summary>
        /// 正前方
        /// </summary>
        private static Vector3 forward = Vector3.zero;

        /// <summary>
        /// 人与相机间相对方向
        /// </summary>
        private static Vector3 relative = Vector3.zero;

        /// <summary>
        /// 移动方向
        /// </summary>
        private static Vector3 dir = Vector3.zero;

        /// <summary>
        /// 增量
        /// </summary>
        private static Vector3 delta = Vector3.zero;

        #endregion

        #region 属性

        /// <summary>
        /// 移动速度
        /// </summary>
        public static float Speed
        {
            get { return speed; }
            set { speed = value; }
        }

        /// <summary>
        /// 移动目标
        /// </summary>
        public static Transform Target
        {
            get { return target; }
            set { target = value; }
        }
        #endregion

        #region 构造方法
        static PlayerMove()
        {
            MonoEvent.update += Update;
        }
        #endregion

        #region 私有方法
        private static void Update()
        {
            if (Target == null) return;
            if (CameraFollow.Instance.transform == null) return;
            if (!iInputMgr.HV) return;

            relative = CameraFollow.Instance.transform.forward;
            relative.y = 0;
            left = Vector3.Cross(relative, up);
            forward = iInputMgr.Dir.y * relative;
            left = iInputMgr.Dir.x * left;
            dir = forward - left;
            delta = dir * Speed * Time.deltaTime;
            Target.position = Target.position + delta;
            Target.forward = dir;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Refresh()
        {
            CameraFollow follow = CameraFollow.Instance;
            relative = -follow.Offset;
            relative.y = 0;
            relative.Normalize();
        }
        #endregion
    }
}
#endif