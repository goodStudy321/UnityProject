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
    /// BG:功能基类 注:释放时不可保留引用
    /// </summary>
    [Serializable]
    public class ActionBase : IDisposable, IComparable<ActionBase>, IComparer<ActionBase>
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段

        [SerializeField]
        private float percent = 0;

        #endregion

        #region 属性

        /// <summary>
        /// 在总时间内百分比
        /// </summary>
        public float Percent
        {
            get { return percent; }
            set { percent = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ActionBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected virtual void DisposeCustom()
        {

        }

        #endregion

        #region 公开方法
        /// <summary>
        /// 初始化
        /// </summary>
        public virtual void Init()
        {

        }

        /// <summary>
        /// 执行
        /// </summary>
        public virtual void Execute()
        {

        }
        public void Dispose()
        {
            Percent = 0;
            DisposeCustom();
            ObjPool.Instance.Add(this);
        }

        public int CompareTo(ActionBase other)
        {
            if (other == null) return 1;
            if (Percent > other.Percent) return 1;
            if (Percent < other.Percent) return -1;
            return 0;
        }


        public int Compare(ActionBase lhs, ActionBase rhs)
        {
            return lhs.CompareTo(lhs);
        }
        #endregion

        #region 编辑器
#if UNITY_EDITOR
        public virtual void Draw(Object obj, IList lst, int idx)
        {
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.Slider("时间百分比:", ref percent, 0, 1, obj);

            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}
#endif