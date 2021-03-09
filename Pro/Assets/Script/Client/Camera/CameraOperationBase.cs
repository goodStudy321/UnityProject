using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:相机操作基类
    /// </summary>
    public abstract class CameraOperationBase
    {
        #region 字段
        private bool alock = false;

        private Camera camera = null;

        private Transform tranself = null;



        #endregion

        #region 属性
        public bool Lock
        {
            get { return alock; }
            set { alock = value; }
        }

        public Camera Camera
        {
            get { return camera; }
            set { camera = value; }
        }

        /// <summary>
        /// 变换组件
        /// </summary>
        public Transform transform
        {
            get { return tranself; }
            set { tranself = value; }
        }


        #endregion

        #region 构造方法
        public CameraOperationBase()
        {

        }
        public CameraOperationBase(Camera camera)
        {
            this.camera = camera;
            tranself = camera.transform;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 检查可否操作
        /// </summary>
        /// <returns></returns>
        protected abstract bool Check();

        /// <summary>
        /// 自定义更新
        /// </summary>
        protected abstract void UpdateCustom();
        #endregion

        #region 公开方法
        /// <summary>
        /// 更新
        /// </summary>
        public void Update()
        {
            if (alock) return;
            if (CameraMgr.CameraPull.IsPullingCam) return;
            if (!Check()) return;
            UpdateCustom();
        }
        /// <summary>
        /// 聚焦
        /// </summary>
        public abstract void Focus();
        /// <summary>
        /// 聚焦
        /// </summary>
        /// <param name="position">聚焦位置</param>
        public abstract void Focus(Vector3 position);

        /// <summary>
        /// 聚焦自己/停止插值动作
        /// </summary>
        public abstract void FocusSelf();

        /// <summary>
        /// 刷新
        /// </summary>
        public virtual void Refresh()
        {

        }

        #endregion
    }
}