/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/10/16 00:00:00
 ============================================================================*/

#if UNITY_EDITOR
using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    /// <summary>
    ///编辑器在场景中绘制三维向量的工具
    /// </summary>
    public static class UIVectorUtil
    {
        #region 字段

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
        /// 绘制三维向量结构列表
        /// </summary>
        /// <param name="obj">列表所在对象</param>
        /// <param name="lst">三位向量列表</param>
        /// <param name="key">键值</param>
        /// <param name="title">标题</param>
        /// <param name="changed">改变事件,参数-1:新增 -2减少 其它对应索引值改变</param>
        public static void Draw(Object obj, List<Vector3> lst, string key, string title, Action<int> changed = null)
        {
            if (lst == null) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            if (EditorGUILayout.Foldout(EditorPrefs.GetBool(key), title))
            {
                EditorPrefs.SetBool(key, true);
                if (GUILayout.Button("", StyleTool.Plus, UIOptUtil.plusWd))
                {
                    EditUtil.RegisterUndo(key, obj);
                    lst.Add(Vector3.zero);
                    Event.current.Use();
                    if (changed != null) changed(-1);
                }
            }
            else
            {
                EditorPrefs.SetBool(key, false);
            }
            EditorGUILayout.EndHorizontal();
            if (EditorPrefs.GetBool(key))
            {
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    EditorGUILayout.BeginHorizontal();
                    string tip = string.Format("点{0}:", i);
                    EditorGUI.BeginChangeCheck();
                    Vector3 newVal = EditorGUILayout.Vector3Field(tip, lst[i]);
                    if (EditorGUI.EndChangeCheck())
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst[i] = newVal;
                        if (changed != null) changed(i);
                    }
                    if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst.RemoveAt(i);
                        Event.current.Use();
                        if (changed != null) changed(-2);
                        break;
                    }
                    EditorGUILayout.EndHorizontal();
                }
            }
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 向三维向量列表中添加项
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">列表</param>
        /// <param name="tip">提示</param>
        /// <param name="condition">条件</param>
        /// <param name="btn">按钮/默认左键</param>
        /// <param name="changed">改变事件</param>
        public static void Add(Object obj, List<Vector3> lst, string tip, bool condition, int btn = 0, Action changed = null)
        {
            if (!EventTool.Precondition(true, Event.current, condition, btn, EventType.MouseDown)) return;
            RaycastHit hit = SceneViewUtil.HitGround(Event.current.mousePosition);
            if (hit.collider == null) return;
            EditUtil.RegisterUndo("AddVector", obj);
            lst.Add(hit.point);
            Event.current.Use();
            if (changed != null) changed();
            SceneViewUtil.ShowTip(string.Format("添加第{0}个{1}位置成功", lst.Count, tip));
        }

        /// <summary>
        /// 设置三位向量列表中某项的值
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="target">修改坐标</param>
        /// <param name="tip">提示</param>
        /// <param name="condition">条件</param>
        /// <param name="btn">默认右键</param>
        /// <param name="changed">改变事件</param>
        public static void Set(Object obj, ref Vector3 target, string tip, bool condition, int btn = 1, Action changed = null)
        {
            if (!EventTool.Precondition(true, Event.current, condition, btn, EventType.MouseDown)) return;
            RaycastHit hit = SceneViewUtil.HitGround(Event.current.mousePosition);
            if (hit.collider == null) return;
            if (hit.point != target)
            {
                EditUtil.RegisterUndo("SetVector", obj);
                target = hit.point;
                Event.current.Use();
                if (changed != null) changed();
            }
            SceneViewUtil.ShowTip(string.Format("设置{0}成功为:{1}", tip, hit.point));
        }

        /// <summary>
        /// 设置三位向量列表中某项的值
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">列表</param>
        /// <param name="index">索引</param>
        /// <param name="tip">提示</param>
        /// <param name="condition">条件</param>
        /// <param name="btn">默认右键</param>
        /// <param name="changed">改变事件</param>
        public static void Set(Object obj, List<Vector3> lst, int index, string tip, bool condition, int btn = 1, Action changed = null)
        {
            if (!EventTool.Precondition(true, Event.current, condition, btn, EventType.MouseDown)) return;
            if (lst.Count == 0)
            {
                UIEditTip.Error("{0}列表为空", tip); return;
            }
            var hit = SceneViewUtil.HitGround(Event.current.mousePosition);
            if (hit.collider == null) return;
            if (hit.point != lst[index])
            {
                EditUtil.RegisterUndo("SetVectorInfo", obj);
                lst[index] = hit.point;
                Event.current.Use();
                if (changed != null) changed();
            }
            SceneViewUtil.ShowTip(string.Format("设置第{0}个{1}位置成功", index, tip));
        }

        /// <summary>
        /// 在场景视图中绘制三维向量列表
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">列表</param>
        /// <param name="color">颜色</param>
        /// <param name="tip">提示</param>
        /// <param name="index">指定索引绘制位置操作</param>
        /// <param name="line">true:连线</param>
        /// <param name="changed">改变事件,参数-1:新增 -2减少 其它对应索引值改变</param>
        public static void Draw(Object obj, List<Vector3> lst, Color color, string tip, int index, bool line = false, Action<int> changed = null)
        {
            if (lst.Count == 0) return;
            Color oldColor = Handles.color;
            Handles.color = color;
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                if (line) { int next = i + 1; if (next < length) Handles.DrawLine(lst[i], lst[next]); }
                Handles.SphereHandleCap(obj.GetInstanceID(), lst[i], Quaternion.identity, 1f, EventType.Repaint);
                Handles.Label(lst[i], string.Format("{0}:{1}", tip, i));
                if (i != index) continue;
                if (Tools.current == Tool.Move)
                {
                    Vector3 newVal = Handles.PositionHandle(lst[i], Quaternion.identity);
                    if (newVal != lst[i])
                    {
                        EditUtil.RegisterUndo("MovePosition", obj);
                        lst[i] = newVal;
                        if (changed != null) changed(i);
                    }
                }
            }
            Handles.color = oldColor;
        }

        /// <summary>
        /// 向VectorInfo列表中添加项
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">列表</param>
        /// <param name="tip">提示</param>
        /// <param name="condition">条件</param>
        /// <param name="btn">按钮/默认左键</param>
        /// <param name="changed">改变事件</param>
        public static void AddInfo<T>(Object obj, List<T> lst, string tip, bool condition, int btn = 0, Action changed = null) where T : VectorInfo, new()
        {
            if (!EventTool.Precondition(true, Event.current, condition, btn, EventType.MouseDown)) return;
            RaycastHit hit = SceneViewUtil.HitGround(Event.current.mousePosition);
            if (hit.collider == null) return;
            EditUtil.RegisterUndo("AddVectorInfo", obj);
            lst.Add(new T() { pos = hit.point });
            Event.current.Use();
            if (changed != null) changed();
            SceneViewUtil.ShowTip(string.Format("添加第{0}个{1}位置成功", lst.Count, tip));
        }

        /// <summary>
        /// 设置三位向量列表中某项的值
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">列表</param>
        /// <param name="index">索引</param>
        /// <param name="tip">提示</param>
        /// <param name="condition">条件</param>
        /// <param name="btn">默认右键</param>
        /// <param name="changed">改变事件</param>
        public static void SetInfo<T>(Object obj, List<T> lst, int index, string tip, bool condition, int btn = 1, Action changed = null) where T : VectorInfo
        {
            if (!EventTool.Precondition(true, Event.current, condition, btn, EventType.MouseDown)) return;
            if (lst == null || lst.Count == 0)
            {
                UIEditTip.Error("{0}列表为空", tip); return;
            }
            RaycastHit hit = SceneViewUtil.HitGround(Event.current.mousePosition);
            if (hit.collider == null) return;
            if (lst[index].pos != hit.point)
            {
                EditUtil.RegisterUndo("SetVectorInfo", obj);
                lst[index].pos = hit.point;
                Event.current.Use();
                if (changed != null) changed();
            }
            SceneViewUtil.ShowTip(string.Format("设置第{0}个{1}位置成功", index, tip));
        }

        /// <summary>
        /// 在场景视图中绘制VectorInfo
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">列表</param>
        /// <param name="color">颜色</param>
        /// <param name="tip">提示</param>
        /// <param name="index">索引</param>
        /// <param name="line">true:连线</param>
        /// <param name="changed">改变事件</param>
        public static void DrawInfos<T>(Object obj, List<T> lst, Color color, string tip, int index, bool line = false, Action changed = null) where T : VectorInfo
        {
            int length = lst.Count;
            if (length == 0) return;
            int next = 0;
            Color oldColor = Handles.color;
            Handles.color = color;
            for (int i = 0; i < length; i++)
            {
                VectorInfo info = lst[i];
                Handles.SphereHandleCap(obj.GetInstanceID(), info.pos, Quaternion.identity, 0.5f, EventType.Repaint);
                Handles.Label(info.pos, string.Format("{0}:{1}", tip, i));
                info.OnSceneGUI(obj);
                if (line)
                {
                    next = i + 1;
                    if (next < length) Handles.DrawLine(info.pos, lst[next].pos);
                }
                if (i != index) continue;
                if (Tools.current == Tool.Move)
                {
                    Vector3 newVal = Handles.PositionHandle(info.pos, Quaternion.identity);
                    if (newVal != info.pos)
                    {
                        EditUtil.RegisterUndo("MovePosition", obj);
                        info.pos = newVal;
                        if (changed != null) changed();
                    }
                }
            }
            Handles.color = oldColor;
        }

        /// <summary>
        /// 在场景视图中绘制VectorInfo
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">列表</param>
        /// <param name="color">颜色</param>
        /// <param name="tip">提示</param>
        /// <param name="index">索引</param>
        /// <param name="line">true:连线</param>
        public static void DrawInfos<T>(Object obj, List<T> lst, Color color, string tip, ref int index, bool line = false) where T : VectorInfo
        {
            int length = lst.Count;
            if (length == 0) return;
            int next = 0;
            Color oldColor = Handles.color;
            Handles.color = color;
            for (int i = 0; i < length; i++)
            {
                VectorInfo info = lst[i];
                string simple = info.Simple();
                string detail = null;
                if (string.IsNullOrEmpty(simple))
                {
                    detail = string.Format("{0}:{1}", tip, i);
                }
                else
                {
                    detail = string.Format("{0}:{1} {2}", tip, i, simple);
                }
                Handles.Label(info.pos, detail);
                info.OnSceneGUI(obj);
                if (EventTool.LefDown())
                {
                    if (UIHandleTool.Overlaps(info.pos)) index = i;
                }
                else if (EventTool.RigDown())
                {
                    if (UIHandleTool.Overlaps(info.pos)) info.OnSceneContext<T>(obj, lst, i);
                }
                if (line)
                {
                    next = i + 1;
                    if (next < length) Handles.DrawLine(info.pos, lst[next].pos);
                }
                if (Tools.current != Tool.Move) continue;
                UIHandleTool.FreeMove(obj, ref info.pos, Handles.RectangleHandleCap, info.OnPosChanged);
                if (i != index) continue;
                UIHandleTool.Position(obj, ref info.pos, info.OnPosChanged);
            }
            Handles.color = oldColor;
        }
        #endregion
    }
}
#endif