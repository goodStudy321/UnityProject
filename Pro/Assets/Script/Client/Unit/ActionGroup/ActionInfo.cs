#if UNITY_EDITOR
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif
namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:
    /// </summary>
    [Serializable]
    public class ActionInfo : IDisposable, IComparer<ActionInfo>, IComparable<ActionInfo>
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段

        [SerializeField]
        private ActionType aType = ActionType.PlayParticle;

        [SerializeField]
        private ActionPlayPaticle action = new ActionPlayPaticle();

        #endregion

        #region 属性

        /// <summary>
        /// 类型
        /// </summary>
        public ActionType AType
        {
            get { return aType; }
            set { aType = value; }
        }


        public ActionPlayPaticle Action
        {
            get { return action; }
            set { action = value; }
        }


        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ActionInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public int CompareTo(ActionInfo other)
        {
            return Action.CompareTo(other.Action);
        }

        public int Compare(ActionInfo lhs, ActionInfo rhs)
        {
            return lhs.CompareTo(rhs);
        }

        public void Dispose()
        {
            if (Action != null) Action.Dispose();
            Action = null;
            ObjPool.Instance.Add(this);
        }
        #endregion

#if UNITY_EDITOR
        private string[] typeStrArr = new string[] { "播放粒子特效" };
        public void Draw(Object obj, IList lst, int idx)
        {
            EditorGUI.BeginChangeCheck();
            ActionType newType = (ActionType)EditorGUILayout.Popup("类型:", (int)aType, typeStrArr);
            if (EditorGUI.EndChangeCheck())
            {
                EditUtil.RegisterUndo("PopupChanged", obj);
                //Undo.RegisterCompleteObjectUndo(obj, "PopupChanged");
                Debug.Log("发生改变");
                //action = ActionFty.Get(newType);
                action = ObjPool.Instance.Get<ActionPlayPaticle>();
                aType = newType;
            }
            Action.Draw(obj, lst, idx);
        }
#endif
    }
}
#endif