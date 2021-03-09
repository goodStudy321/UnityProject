using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.9
    /// BG:射线工具
    /// </summary>
    public static class RaycastTool
    {
        #region 字段

        private static int groundMask = -1;

        private static Ray mainRay = default(Ray);

        private static RaycastHit groundHit = default(RaycastHit);
        #endregion

        #region 属性

        /// <summary>
        /// 地面射线层
        /// </summary>
        public static int GroundMask { get { return groundMask; } }

        /// <summary>
        /// 地面射线撞击
        /// </summary>
        public static RaycastHit GroundHit { get { return groundHit; } }
        #endregion

        #region 构造方法
        static RaycastTool()
        {
            groundMask = 1 << LayerTool.Ground;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 检查[主相机]鼠标位置射线是否碰撞到地面
        /// </summary>
        /// <param name="notTip">未检测到地面的提示</param>
        /// <returns></returns>
        public static bool HitGround(string notTip = "")
        {
            return HitGround(CameraMgr.Main);
        }

        /// <summary>
        /// 检查[相机]鼠标位置射线是否碰撞到地面
        /// </summary>
        /// <param name="camera">发射射线的相机</param>
        /// <param name="notTip">未检测到地面的提示</param>
        /// <returns></returns>
        public static bool HitGround(Camera camera, string notTip = "")
        {
            if (camera == null) return false;
            mainRay = camera.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(mainRay, out groundHit, 10000, groundMask)) return true;
            if (!string.IsNullOrEmpty(notTip)) iTrace.Error("Loong", string.Format("{0},没有检查到地面层"));
            return false;
        }

        /// <summary>
        /// 检查[主相机]鼠标位置射线检测到地面位置
        /// </summary>
        /// <param name="tip">未检测到地面的提示</param>
        /// <returns></returns>
        public static Vector3 HitGroundPos(string tip = "")
        {
            if (HitGround(tip)) return groundHit.point;
            return Vector3.zero;
        }

        /// <summary>
        /// 检查[相机]鼠标位置射线检测到地面位置
        /// </summary>
        /// <param name="camera">发射射线的相机</param>
        /// <param name="tip">未检测到地面的提示</param>
        /// <returns></returns>
        public static Vector3 HitGroundPos(Camera camera, string tip = "")
        {
            if (HitGround(camera, tip)) return groundHit.point;
            return Vector3.zero;

        }

        /// <summary>
        /// 从起始点位置上方500米处发射一条射线检测与地面的碰撞体
        /// </summary>
        /// <param name="beg">起始点位置</param>
        /// <param name="showError">如果没有检测到地面碰撞体是否显示错误</param>
        /// <returns></returns>
        public static RaycastHit CheckGroundHit(Vector3 beg, bool showError = true)
        {
            Ray ray = new Ray(beg + Vector3.up * 500, Vector3.down);
            RaycastHit hit = default(RaycastHit);
            if (!Physics.Raycast(ray, out hit, 10000, 1 << LayerTool.Ground))
            {
                if (showError) iTrace.Error("Loong", string.Format("没有检测到地面层:{0}", LayerTool.Ground));
            }
            return hit;
        }

        /// <summary>
        /// 从起始点位置上方500米处发射一条射线检测与地面的碰撞体
        /// </summary>
        /// <param name="beg">起始点位置</param>
        /// <param name="showError">如果没有检测到地面碰撞体是否显示错误</param>
        /// <returns></returns>
        public static Vector3 GetGroundHitPos(Vector3 beg, bool showError = true)
        {
            RaycastHit hit = CheckGroundHit(beg, showError);
            if (hit.collider == null) return beg;
            return hit.point;
        }
        #endregion
    }
}