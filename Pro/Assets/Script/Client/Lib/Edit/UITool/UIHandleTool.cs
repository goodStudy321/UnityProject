#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.10.16
    /// BG:编辑器场景中绘制3DUI的工具
    /// </summary>
    public static class UIHandleTool
    {
        #region 字段
        /// <summary>
        /// 绘制矩形的4个点
        /// </summary>
        private static Vector3[] rectPoints = new Vector3[4];
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 开始场景视图左下角自动布局
        /// </summary>
        public static void Begin()
        {
            Handles.BeginGUI();
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.BeginVertical();
            GUILayout.FlexibleSpace();
            EditorGUILayout.BeginVertical(StyleTool.Win);
        }

        /// <summary>
        /// 结束场景视图左下角自动布局
        /// </summary>
        public static void End()
        {
            EditorGUILayout.EndVertical();
            GUILayout.Space(20);
            EditorGUILayout.EndVertical();
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndHorizontal();
            Handles.EndGUI();
        }

        /// <summary>
        /// 在场景中根据中心点和长度半径宽度半径绘制矩形
        /// </summary>
        /// <param name="point"></param>
        /// <param name="lengthRadius"></param>
        /// <param name="widthRadius"></param>
        /// <param name="instanceID"></param>
        /// <param name="showCenter"></param>
        /// <param name="des"></param>
        public static void DrawRectangle(Vector3 point, int lengthRadius, int widthRadius, int instanceID, bool showCenter = true, string des = "区域中心")
        {
            if (showCenter)
            {
                Handles.Label(point, des);
                Handles.SphereHandleCap(instanceID, point, Quaternion.identity, 1f, EventType.Repaint);
            }
            Vector3 p1 = point; p1.Set(p1.x - lengthRadius, p1.y, p1.z + widthRadius);
            Vector3 p2 = point; p2.Set(p2.x + lengthRadius, p2.y, p2.z + widthRadius);
            Vector3 p3 = point; p3.Set(p3.x + lengthRadius, p3.y, p3.z - widthRadius);
            Vector3 p4 = point; p4.Set(p4.x - lengthRadius, p4.y, p4.z - widthRadius);
            Handles.DrawLine(p1, p2);
            Handles.DrawLine(p2, p3);
            Handles.DrawLine(p3, p4);
            Handles.DrawLine(p4, p1);
        }

        /// <summary>
        /// 在场景中根据左下角点和右上角点 绘制矩形
        /// </summary>
        /// <param name="leftDownPoint">左下角点</param>
        /// <param name="rightUpPoint">右上角点</param>
        /// <param name="obj">所在对象</param>
        public static void DrawRectangle(Vector3 leftDownPoint, Vector3 rightUpPoint, Object obj)
        {
            Vector3 leftUpPoint = leftDownPoint;
            leftUpPoint.Set(leftUpPoint.x, leftUpPoint.y, rightUpPoint.z);
            Vector3 rightDownPoint = rightUpPoint;
            rightDownPoint.Set(rightUpPoint.x, rightUpPoint.y, leftDownPoint.z);
            Handles.DrawLine(leftDownPoint, rightDownPoint);
            Handles.DrawLine(rightDownPoint, rightUpPoint);
            Handles.DrawLine(rightUpPoint, leftUpPoint);
            Handles.DrawLine(leftUpPoint, leftDownPoint);
            Handles.Label(leftDownPoint, "左下角点");
            Handles.SphereHandleCap(obj.GetInstanceID(), leftDownPoint, Quaternion.identity, 1f, EventType.Repaint);
            Handles.Label(rightUpPoint, "右上角点");
            Handles.SphereHandleCap(obj.GetInstanceID(), rightUpPoint, Quaternion.identity, 1f, EventType.Repaint);
        }

        /// <summary>
        /// 在场景视图中根据左下角点和右上角点绘制实心矩形
        /// </summary>
        /// <param name="leftDownPoint">左下角点</param>
        /// <param name="rightUpPoint">右上角点</param>
        /// <param name="face">表面颜色</param>
        /// <param name="outline">轮廓颜色</param>
        public static void DrawRectangle(Vector3 leftDownPoint, Vector3 rightUpPoint, Color face, Color outline)
        {
            Vector3 leftUpPoint = leftDownPoint;
            leftUpPoint.Set(leftUpPoint.x, leftUpPoint.y, rightUpPoint.z);
            Vector3 rightDownPoint = rightUpPoint;
            rightDownPoint.Set(rightUpPoint.x, rightUpPoint.y, leftDownPoint.z);
            rectPoints[0] = leftDownPoint;
            rectPoints[1] = leftUpPoint;
            rectPoints[2] = rightUpPoint;
            rectPoints[3] = rightDownPoint;
            Handles.DrawSolidRectangleWithOutline(rectPoints, face, outline);
        }

        /// <summary>
        /// 绘制网格
        /// </summary>
        /// <param name="leftDownPoint">左下角点</param>
        /// <param name="rightUpPoint">右上角点</param>
        /// <param name="rowMax">行数</param>
        /// <param name="columnMax">列数</param>
        /// <param name="color">颜色</param>
        /// <param name="lingWidth">线宽度</param>
        public static void DrawGrid(Vector3 leftDownPoint, Vector3 rightUpPoint, int rowMax, int columnMax, Color color, int lingWidth = 6)
        {
            if (rowMax < 1) return;
            if (columnMax < 1) return;
            Color ori = Handles.color;
            Handles.color = color;
            float width = (rightUpPoint.x - leftDownPoint.x) / columnMax;
            float height = (rightUpPoint.z - leftDownPoint.z) / rowMax;
            Vector3 p1 = leftDownPoint;
            Vector3 p2 = rightUpPoint;
            p1.z = p2.z;
            Handles.DrawAAPolyLine(lingWidth, p1, p2);
            p1.x = p2.x;
            p1.z = leftDownPoint.z;
            Handles.DrawAAPolyLine(lingWidth, p1, p2);
            float temp = 0;

            for (int i = 0; i < rowMax; i++)
            {
                temp = leftDownPoint.z + i * height;
                p1.x = leftDownPoint.x;
                p1.z = temp;
                p2.x = rightUpPoint.x;
                p2.z = temp;
                Handles.DrawAAPolyLine(lingWidth, p1, p2);
            }

            for (int i = 0; i < columnMax; i++)
            {
                temp = leftDownPoint.x + i * width;
                p1.x = temp;
                p1.z = leftDownPoint.z;
                p2.x = temp;
                p2.z = rightUpPoint.z;
                Handles.DrawAAPolyLine(lingWidth, p1, p2);
            }

            Handles.color = ori;
        }

        /// <summary>
        /// 绘制位置操作
        /// </summary>
        /// <param name="obj">操作对象</param>
        /// <param name="pos">位置</param>
        /// <param name="changed">改变事件</param>
        public static void Position(Object obj, ref Vector3 pos, Action changed = null)
        {
            if (Tools.current != Tool.Move) return;
            Vector3 newVal = Handles.PositionHandle(pos, Quaternion.identity);
            if (newVal == pos) return;
            EditUtil.RegisterUndo("MovePosition", obj);
            pos = newVal;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制自由移动操作
        /// </summary>
        /// <param name="obj">操作对象</param>
        /// <param name="pos">位置</param>
        /// <param name="capFunc">绘制方法</param>
        /// <param name="changed">改变事件</param>
        public static void FreeMove(Object obj, ref Vector3 pos, Handles.CapFunction capFunc, Action changed = null)
        {
            float size = HandleUtility.GetHandleSize(pos) * 0.1f;
            Vector3 newVal = Handles.FreeMoveHandle(pos, Quaternion.identity, size, Vector3.zero, capFunc);
            if (newVal == pos) return;
            EditUtil.RegisterUndo("FreeMove", obj);
            if (changed != null) changed();
        }

        /// <summary>
        /// 判断世界坐标是否和屏幕鼠标位置重叠
        /// </summary>
        /// <param name="world">世界坐标</param>
        /// <param name="range">范围</param>
        /// <returns></returns>
        public static bool Overlaps(Vector3 world, float range = 9)
        {
            if (range < 1) range = 1;
            Vector2 screenPos = HandleUtility.WorldToGUIPoint(world);
            Vector2 dif = screenPos - Event.current.mousePosition;
            if (dif.magnitude > range) return false;
            return true;
        }
        #endregion
    }
}
#endif