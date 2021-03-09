/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/6/14 00:00:00
 ============================================================================*/

#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 编辑器场景视图工具
    /// </summary>
    public static class SceneViewUtil
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 从场景视图中心位置发射射线碰撞到地面的位置
        /// </summary>
        /// <param name="view">场景视图</param>
        /// <param name="beg">开始位置</param>
        /// <returns></returns>
        private static Vector3 GetPosGround(SceneView view, Vector2 beg)
        {
            int layer = LayerMask.NameToLayer("Ground");
            return GetPos(view, beg, 1 << layer);
        }

        /// <summary>
        /// 从场景视图中心位置发射射线碰撞到指定层的位置
        /// </summary>
        /// <param name="view">场景视图</param>
        /// <param name="beg">发射位置</param>
        /// <param name="layer">层</param>
        /// <returns></returns>
        private static Vector3 GetPos(SceneView view, Vector2 beg, int layer)
        {
            if (view == null) return Vector3.zero;
            view.MoveToView();
            beg.Set(Mathf.Abs(beg.x), Mathf.Abs(beg.y));
            RaycastHit hit = CheckHit(beg, layer);
            if (hit.collider == null) return Vector3.zero;
            return hit.point;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 从场景视图发射射线检查是否碰撞
        /// </summary>
        /// <param name="pos">发射位置</param>
        /// <param name="layer">碰撞层级遮罩</param>
        /// <returns></returns>
        public static RaycastHit CheckHit(Vector2 pos, int layer)
        {
            RaycastHit hit = default(RaycastHit);
            SceneView view = Open(false, false);
            if (view == null) return hit;
            Ray ray = HandleUtility.GUIPointToWorldRay(pos);
            //Ray ray = view.camera.ScreenPointToRay(pos);
            Physics.Raycast(ray, out hit, 10000, layer);
            return hit;
        }

        /// <summary>
        /// 从场景视图发射射线检查是否碰撞到地面
        /// </summary>
        /// <param name="pos">发射位置</param>
        /// <returns></returns>
        public static RaycastHit HitGround(Vector2 pos)
        {
            int layer = LayerMask.NameToLayer("Ground");
            RaycastHit hit = CheckHit(pos, 1 << layer);
            if (hit.collider == null) UIEditTip.Warning("没有碰到层为:Ground的物体");
            return hit;
        }

        /// <summary>
        /// 获取场景视图
        /// </summary>
        /// <param name="create">true:没有场景视图时创建</param>
        /// <returns></returns>
        public static SceneView Get(bool create = true)
        {
            SceneView view = SceneView.currentDrawingSceneView;
            if (view == null) view = SceneView.lastActiveSceneView;
            if (view == null) if (SceneView.sceneViews.Count > 0) view = SceneView.sceneViews[0] as SceneView;
            if (create && (view == null)) view = SceneView.CreateInstance<SceneView>();
            return view;
        }

        /// <summary>
        /// 打开场景视图
        /// </summary>
        /// <param name="create">true:没有场景视图时创建</param>
        /// <param name="focus">true:聚焦到场景视图</param>
        /// <returns></returns>
        public static SceneView Open(bool create = true, bool focus = true)
        {
            SceneView view = Get(create);
            if (view == null) return null;
            view.Show();
            if (focus) view.Focus();
            return view;
        }

        /// <summary>
        /// 聚焦到变换组件
        /// </summary>
        /// <param name="target">变换组件</param>
        /// <param name="create">true:没有场景视图时创建</param>
        /// <param name="focus">true:没有场景视图时创建</param>
        public static void Focus(Transform target, bool create = true, bool focus = false)
        {
            if (target == null) return;
            Selection.activeGameObject = target.gameObject;
            SceneView view = Open(create, focus);
            if (view == null) return;
            view.LookAt(target.position);
        }

        /// <summary>
        /// 聚焦位置
        /// </summary>
        /// <param name="pos">位置</param>
        /// <param name="create">true:没有场景视图时创建</param>
        /// <param name="focus">true:聚焦到场景视图</param>
        public static void Focus(Vector3 pos, bool create = true, bool focus = false)
        {
            SceneView view = Open(create, focus);
            if (view != null) view.LookAt(pos);
        }

        /// <summary>
        /// 显示提示
        /// </summary>
        /// <param name="msg"></param>
        public static void ShowTip(string msg)
        {
            SceneView view = Open(false, false);
            if (view != null) UIEditTip.Log(msg);
        }

        /// <summary>
        /// 从场景视图中心位置发射射线碰撞到地面的位置
        /// </summary>
        /// <returns></returns>
        public static Vector3 GetCenterPosGround()
        {
            int layer = LayerMask.NameToLayer("Ground");
            return GetCenterPos(1 << layer);
        }

        /// <summary>
        /// 从场景视图中心位置发射射线碰撞到指定层的位置
        /// </summary>
        /// <param name="layer">层</param>
        /// <returns></returns>
        public static Vector3 GetCenterPos(int layer)
        {
            SceneView view = Open(false, false);
            if (view == null) return Vector3.zero;
            return GetPos(view, view.position.center, layer);
        }

        /// <summary>
        /// 将从屏幕鼠标位置发射射线碰撞到的地面层的位置设置到变换组件的位置
        /// </summary>
        /// <param name="target">目标变换组件</param>
        public static void SetPos(Transform target)
        {
            int ground = LayerMask.NameToLayer("Ground");
            SetPos(target, 1 << ground);
        }

        /// <summary>
        /// 将从屏幕鼠标位置发射射线碰撞到的指定层的位置设置到变换组件的位置
        /// </summary>
        /// <param name="target">目标变换组件</param>
        /// <param name="layer">指定层级</param>
        public static void SetPos(Transform target, int layer)
        {
            Vector3 pos = Event.current.mousePosition;
            RaycastHit hit = CheckHit(pos, layer);
            if (hit.collider == null) return;
            Focus(target, false, false);
            target.position = hit.point;
            ShowTip(string.Format("成功设置:{0}的位置:{1}", target.name, target.position));
        }

        /// <summary>
        /// 获取当前鼠标位置沿着场景视图视角到指定Y坐标坐标的位置
        /// </summary>
        /// <param name="view">场景视图</param>
        /// <param name="coordY">Y轴坐标</param>
        /// <returns></returns>
        public static Vector3 GetPos(SceneView view, float coordY)
        {
            if (Event.current == null)
            {
                return Vector3.zero;
            }
            return GetPos(view, Event.current.mousePosition, coordY);
        }

        /// <summary>
        /// 获取场景视图指定位置沿着视角到指定Y坐标坐标的位置
        /// </summary>
        /// <param name="view">场景视图</param>
        /// <param name="viewPos">视图位置</param>
        /// <param name="coordY">Y轴坐标</param>
        /// <returns></returns>
        public static Vector3 GetPos(SceneView view, Vector2 viewPos, float coordY)
        {
            if (view == null) return Vector3.zero;
            Camera cam = view.camera;
            viewPos.y = cam.pixelHeight - viewPos.y;
            Vector3 begPos = cam.ScreenToWorldPoint(viewPos);
            float angle = Vector3.Angle(cam.transform.forward, Vector3.down);
            float height = begPos.y - coordY;
            float radian = Mathf.Deg2Rad * angle;
            float distance = height / Mathf.Cos(radian);
            Vector3 endPos = begPos + distance * cam.transform.forward;
            return endPos;
        }
        #endregion

    }
}
#endif