#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.7.14
    /// BG:编辑器事件工具
    /// </summary>
    public static class EventTool
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
        /// 事件操作的前提条件
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <param name="e">事件</param>
        /// <param name="condition">条件</param>
        /// <param name="button">按钮</param>
        /// <param name="type">事件类型</param>
        /// <returns></returns>
        public static bool Precondition(bool ctrlID, Event e, bool condition, int button, EventType type)
        {
            if (!condition) return false;
            if (ctrlID) HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));
            return Mousecondition(e, button, type);
        }

        /// <summary>
        /// 鼠标事件条件
        /// </summary>
        /// <param name="e">事件</param>
        /// <param name="button">按钮</param>
        /// <param name="type">事件类型</param>
        /// <returns></returns>
        public static bool Mousecondition(Event e, int button, EventType type)
        {
            if (e == null) return false;
            if (e.type != type) return false;
            if (e.button != button) return false;
            return true;
        }

        /// <summary>
        /// 鼠标左键按下
        /// </summary>
        /// <returns></returns>
        public static bool LefDown()
        {
            return Mousecondition(Event.current, 0, EventType.MouseDown);
        }

        /// <summary>
        /// 鼠标左键弹起
        /// </summary>
        /// <returns></returns>
        public static bool LefUp()
        {
            return Mousecondition(Event.current, 0, EventType.MouseUp);
        }

        /// <summary>
        /// 鼠标中键按下
        /// </summary>
        /// <returns></returns>
        public static bool MidDown()
        {
            return Mousecondition(Event.current, 2, EventType.MouseDown);
        }

        /// <summary>
        /// 鼠标中键弹起
        /// </summary>
        /// <returns></returns>
        public static bool MidUp()
        {
            return Mousecondition(Event.current, 2, EventType.MouseUp);
        }

        /// <summary>
        /// 鼠标右键按下
        /// </summary>
        /// <returns></returns>
        public static bool RigDown()
        {
            return Mousecondition(Event.current, 1, EventType.MouseDown);
        }

        /// <summary>
        /// 鼠标右键弹起
        /// </summary>
        /// <returns></returns>
        public static bool RigUp()
        {
            return Mousecondition(Event.current, 1, EventType.MouseUp);
        }

        /// <summary>
        /// Alt+鼠标左键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool AltLefDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.alt, 0, EventType.MouseDown);
        }

        /// <summary>
        /// Alt+鼠标左键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool AltLefUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.alt, 0, EventType.MouseUp);
        }

        /// <summary>
        /// Alt+鼠标中键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool AltMidDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.alt, 2, EventType.MouseDown);
        }

        /// <summary>
        /// Alt+鼠标中键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool AltMidUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.alt, 2, EventType.MouseUp);
        }

        /// <summary>
        /// Alt+鼠标右键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool AltRigDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.alt, 1, EventType.MouseDown);
        }

        /// <summary>
        /// Alt+鼠标右键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool AltRigUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.alt, 1, EventType.MouseUp);
        }

        /// <summary>
        /// Ctrl+鼠标左键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool CtrlLefDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.control, 0, EventType.MouseDown);
        }

        /// <summary>
        /// Ctrl+鼠标左键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool CtrlLefUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.control, 0, EventType.MouseUp);
        }

        /// <summary>
        /// Ctrl+鼠标中键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool CtrlMidDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.control, 2, EventType.MouseDown);
        }

        /// <summary>
        /// Ctrl+鼠标中键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool CtrlMidUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.control, 2, EventType.MouseUp);
        }

        /// <summary>
        /// Ctrl+鼠标右键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool CtrlRigDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.control, 1, EventType.MouseDown);
        }

        /// <summary>
        /// Ctrl+鼠标右键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool CtrlRigUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.control, 1, EventType.MouseUp);
        }

        /// <summary>
        /// Shift+鼠标左键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool ShiftLefDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.shift, 0, EventType.MouseDown);
        }

        /// <summary>
        /// Shift+鼠标左键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool ShiftLefUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.shift, 0, EventType.MouseUp);
        }

        /// <summary>
        /// Shift+鼠标中键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool ShiftMidDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.shift, 2, EventType.MouseDown);
        }

        /// <summary>
        /// Shift+鼠标中键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool ShiftMidUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.shift, 2, EventType.MouseUp);
        }

        /// <summary>
        /// Shift+鼠标右键按下
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool ShiftRigDown(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.shift, 1, EventType.MouseDown);
        }

        /// <summary>
        /// Shift+鼠标右键弹起
        /// </summary>
        /// <param name="ctrlID"></param>
        /// <returns></returns>
        public static bool ShiftRigUp(bool ctrlID)
        {
            Event e = Event.current;
            return Precondition(ctrlID, e, e.shift, 1, EventType.MouseUp);
        }

        /// <summary>
        /// 吃掉事件
        /// </summary>
        public static void Use()
        {
            if (Event.current != null) Event.current.Use();
        }
        #endregion
    }
}
#endif