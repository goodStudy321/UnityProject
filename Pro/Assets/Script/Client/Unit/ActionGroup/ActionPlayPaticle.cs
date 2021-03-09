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
    /// BG:播放粒子功能
    /// </summary>
    [Serializable]
    public class ActionPlayPaticle : ActionBase
    {
        #region 字段
        [SerializeField]
        private float duration = 2;

        private Transform target = null;

        [SerializeField]
        private GameObject prefab = null;

        [SerializeField]
        private Vector3 pos = Vector3.zero;
        #endregion

        #region 属性

        /// <summary>
        /// 粒子持续时间
        /// </summary>
        public float Duration
        {
            get { return duration; }
            set { duration = value; }
        }

        /// <summary>
        /// 相对位置
        /// </summary>
        public Vector3 Pos
        {
            get { return pos; }
            set { pos = value; }
        }

        /// <summary>
        /// 目标变换组件,用以解析相对位置
        /// </summary>
        public Transform Target
        {
            get { return target; }
            set { target = value; }
        }

        /// <summary>
        /// 预制件
        /// </summary>
        public GameObject Prefab
        {
            get { return prefab; }
            set { prefab = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ActionPlayPaticle()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Init()
        {
            Target = Player.Instance.transform;
        }

        public override void Execute()
        {
            if (Prefab == null)
            {
                iTrace.Error("Loong", "播放粒子特效时,没有指定预设");
            }
            else if (Target == null)
            {
                iTrace.Error("Loong", "没有设置目标变换组件");
            }
            else
            {
                GameObject go = GbjPool.Instance.Get(Prefab.name);
                if (go == null) go = GbjTool.Clone(prefab);
                go.transform.position = Target.TransformPoint(Pos);
                go.transform.forward = Target.forward;
                go.transform.parent = ParticleMgr.Root;
                GbjPoolTimer.Create(go, Duration);
            }
        }

        #endregion

        #region 编辑器
#if UNITY_EDITOR
        public override void Draw(Object obj, IList lst, int idx)
        {
            base.Draw(obj, lst, idx);
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.ObjectField<GameObject>("预设:", ref prefab, obj);
            if (prefab == null)
            {
                UIEditLayout.HelpError("不能为空");
            }
            else
            {
                UIEditLayout.Vector3Field("相对位置:", ref pos, obj);
                if (GUILayout.Button("将预设的位置设置为此位置"))
                {
                    Prefab.transform.position = Pos;
                }
                EditorGUILayout.Space();
                UIEditLayout.FloatField("特效持续时间:", ref duration, obj);
            }
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}
#endif