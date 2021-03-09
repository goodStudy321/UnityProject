using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:相机跟随安装一定偏移目标
    /// </summary>
    public class CameraFollow : CameraOperationBase
    {
        #region 字段
        private float speed = 6;

        private float rotateSpeed = 120;

        private float eulerY = 0;

        private bool rotating = false;

        private Transform target = null;

        private Vector3 offset = new Vector3(0, 3, -2);

        private Vector3 eulerOffset = new Vector3(-16, 0, 0);
        private Vector3 targetPos = Vector3.zero;
        private static CameraFollow instance = null;
        #endregion

        #region 属性
        /// <summary>
        /// 移动插值速度
        /// </summary>
        public float Speed
        {
            get { return speed; }
            set { speed = value; }
        }

        /// <summary>
        /// 旋转中
        /// </summary>
        public bool Rotating
        {
            get { return rotating; }
            private set { rotating = value; }
        }

        /// <summary>
        /// 旋转插值速度
        /// </summary>
        public float RotateSpeed
        {
            get { return rotateSpeed; }
            set { rotateSpeed = value; }
        }

        public Vector3 TargetPos
        {
            get { return targetPos; }
            set { targetPos = value; }
        }


        public static CameraFollow Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new CameraFollow();
                    instance.Camera = Camera.main;
                    instance.Init();
                }
                return instance;
            }
        }

        /// <summary>
        /// 偏移 与目标之间的位置
        /// </summary>
        public Vector3 Offset
        {
            get { return offset; }
            set { offset = value; }
        }

        /// <summary>
        /// 与目标之间角度的偏移
        /// </summary>
        public Vector3 EulerOffset
        {
            get { return eulerOffset; }
            set { eulerOffset = value; }
        }

        /// <summary>
        /// 跟随目标
        /// </summary>
        public Transform Target
        {
            get { return target; }
            set { target = value; Focus(); }
        }

        #endregion

        #region 构造方法
        public CameraFollow()
        {

        }

        public CameraFollow(Camera cam) : base(cam)
        {

        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 准备旋转
        /// </summary>
        private void RotateReady()
        {
            Rotating = true;
            eulerY = 0;
        }

        /// <summary>
        /// 旋转更新
        /// </summary>
        private void RotateUpdate()
        {
            if (GestureMgr.One.DeltaPos.x > 0)
            {
                eulerY = Time.deltaTime * rotateSpeed;
            }
            else if (GestureMgr.One.DeltaPos.x < 0)
            {
                eulerY = -Time.deltaTime * rotateSpeed;
            }
            Quaternion rotation = Quaternion.Euler(0, eulerY, 0);
            Vector3 cur = offset.normalized;
            Vector3 next = rotation * cur;
            float distance = offset.magnitude;
            offset = next * distance;
        }

        /// <summary>
        /// 旋转离开
        /// </summary>
        private void RotateExit()
        {
            Rotating = false;
        }

        /// <summary>
        /// 设置欧拉角
        /// </summary>
        private void SetEulerAngles()
        {
            transform.rotation = Quaternion.LookRotation(-offset);
            transform.eulerAngles += eulerOffset;
        }
        #endregion

        #region 保护方法
        protected override bool Check()
        {
            if (Target == null) return false;
            return true;
        }

        protected override void UpdateCustom()
        {
            if (Rotating)
            {
                RotateUpdate();
                SetEulerAngles();
            }
            TargetPos = target.position + offset;
            transform.position = Vector3.Lerp(transform.position, TargetPos, Time.deltaTime * Speed);
        }
        #endregion

        #region 公开方法

        public void Init()
        {
            GestureMgr.One.exitNotOnUI += RotateExit;
            GestureMgr.One.enterNotOnUI += RotateReady;
        }

        public override void Focus()
        {
            if (Target != null) Focus(Target.position);
        }

        public override void Focus(Vector3 position)
        {
            transform.position = position + offset;
            SetEulerAngles();
        }

        public override void FocusSelf()
        {
            Focus();
            TargetPos = transform.position;
        }

        public override void Refresh()
        {

        }
        #endregion
    }
}