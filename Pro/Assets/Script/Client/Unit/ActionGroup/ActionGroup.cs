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
    /// BG:动作组 注:释放时不可保留引用
    /// </summary>
    [Serializable]
    public class ActionGroup : IDisposable
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段
        /// <summary>
        /// 功能索引
        /// </summary>
        private int index = 0;

        /// <summary>
        /// 时间计数
        /// </summary>
        private float count = 0;

        /// <summary>
        /// 总时间
        /// </summary>
        private float total = 0;

        /// <summary>
        /// 临界值
        /// </summary>
        private float threshold = 0;

        [SerializeField]
        private string des = "";

        [SerializeField]
        private string name = "";

        [SerializeField]
        private bool loop = false;

        [SerializeField]
        private string animName = "";

        private bool running = false;

        private Animation anim = null;

        private ActionBase current = null;

        private AnimationState animState = null;

        [SerializeField]
        private List<ActionInfo> actions = new List<ActionInfo>();

        #endregion

        #region 属性

        /// <summary>
        /// 描述
        /// </summary>
        public string Des
        {
            get { return des; }
            set { des = value; }
        }

        /// <summary>
        /// true:循环
        /// </summary>
        public bool Loop
        {
            get { return loop; }
            set { loop = value; }
        }


        /// <summary>
        /// 动作组名称
        /// </summary>
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        /// <summary>
        /// 运行中
        /// </summary>
        public bool Running
        {
            get { return running; }
            set { running = value; }
        }

        /// <summary>
        /// 动画名称
        /// </summary>
        public string AnimName
        {
            get { return animName; }
            set { animName = value; }
        }

        /// <summary>
        /// 动画组件
        /// </summary>
        public Animation Anim
        {
            get { return anim; }
            set { anim = value; }
        }


        /// <summary>
        /// 动画状态
        /// </summary>
        public AnimationState AnimState
        {
            get { return animState; }
            set { animState = value; }
        }

        /// <summary>
        /// 当前功能
        /// </summary>
        public ActionBase Current
        {
            get { return current; }
            set { current = value; }
        }

        /// <summary>
        /// 功能列表
        /// </summary>
        public List<ActionInfo> Actions
        {
            get { return actions; }
            set { actions = value; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ActionGroup()
        {

        }
        #endregion

        #region 私有方法
        private void SetNext()
        {
            ++index;
            if (index < Actions.Count)
            {
                Current = Actions[index].Action;
            }
            else
            {
                Current = null;
                index = 0;
            }
        }

        private void SetAnimState()
        {
            if (string.IsNullOrEmpty(AnimName))
            {
                iTrace.Error("Loong", string.Format("动作组:{0},动画剪辑名称为空", Name));
            }
            else if (Anim == null)
            {
                iTrace.Error("Loong", string.Format("动作组:{0},动画组件为空", Name));
            }
            else
            {
                AnimState = Anim[AnimName];
                if (AnimState == null)
                {
                    iTrace.Error("Loong", string.Format("动作组:{0},没有名称为:{1}的动画剪辑", Name, AnimName));
                }
                else
                {
                    AnimState.wrapMode = (Loop) ? WrapMode.Loop : WrapMode.Once;
                }
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init()
        {
            Actions.Sort();
            SetAnimState();
            int length = Actions.Count;
            for (int i = 0; i < length; i++)
            {
                Actions[i].Action.Init();
            }
        }

        /// <summary>
        /// 开始
        /// </summary>
        /// <returns></returns>
        public bool Start()
        {
            if (Anim == null) return false;
            if (AnimState == null) return false;
            if (Running)
            {
                string error = string.Format("名称为:{0}的动作组已经在运行中,无法重复开始", Name);
                iTrace.Error("Loong", error);
                return false;
            }
            Running = true;
            if (Actions.Count > 0)
            {
                index = 0;
                Current = Actions[index].Action;
            }
            Anim.CrossFade(AnimName);
            return true;

        }

        /// <summary>
        /// 更新
        /// </summary>
        public void Update()
        {
            if (!running) return;
            count += Time.deltaTime;
            total = AnimState.length / AnimState.speed;
            if (Current != null)
            {
                threshold = Current.Percent * total;
                if (count > threshold)
                {
                    Current.Execute();
                    SetNext();
                }
            }
            if (count > total)
            {
                count = 0;
                index = 0;
                if (Loop)
                {
                    if (Actions.Count > 0) Current = Actions[0].Action;
                    Anim.CrossFade(AnimName);
                }
                else
                {
                    Running = false;
                    Player.Instance.ChangeIdle();
                }
            }
        }

        public void Dispose()
        {
            Reset();
            Des = "";
            Name = "";
            Anim = null;
            Loop = false;
            AnimName = "";
            threshold = 0;
            AnimState = null;
            while (Actions.Count != 0)
            {
                ActionInfo action = Actions[0];
                Actions.RemoveAt(0);
                action.Dispose();
            }
            ObjPool.Instance.Add(this);
        }

        public void Reset()
        {
            index = 0;
            count = 0;
            Running = false;
        }
        #endregion

        #region 编辑器
#if UNITY_EDITOR

        public string[] names = null;


        public int animIndex = -1;

        private void Sort(Object obj)
        {
            EditUtil.RegisterUndo("SortActions", obj);
            Actions.Sort();
        }
        private void SetNames()
        {
            if (names == null)
            {
                names = Anim.GetNames(); return;
            }
            int count = Anim.GetClipCount();
            if (names.Length != count)
            {
                names = Anim.GetNames();
            }
        }
        private void LoopChanged()
        {
            if (!Application.isPlaying) return;
            AnimState.wrapMode = (Loop) ? WrapMode.Loop : WrapMode.Once;
        }

        private void AnimIndexChanged()
        {
            animName = names[animIndex];
            if (!Application.isPlaying) return;
            AnimState = Anim[animName];
            AnimState.wrapMode = (Loop) ? WrapMode.Loop : WrapMode.Once;
        }
        public void Draw(Object obj, IList lst, int idx)
        {
            if (Anim == null)
            {
                UIEditLayout.HelpError("动画组件为空");
            }
            else
            {
                SetNames();
                UIEditLayout.Toggle("循环:", ref loop, obj, LoopChanged);
                UIEditLayout.Popup("动画名称:", ref animIndex, names, obj, AnimIndexChanged);
                UIEditLayout.TextArea("描述:", ref des, obj);

                EditorGUILayout.Space();
                if (Actions.Count > 1) if (GUILayout.Button("对功能列表重新排序")) Sort(obj);
                UIDrawTool.IDrawLst<ActionInfo>(obj, actions, "actions", "功能列表");
            }
        }
#endif
        #endregion
    }
}
#endif