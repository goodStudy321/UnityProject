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
    /// BG:动作状态 注:释放时不可保留引用
    /// </summary>
    [Serializable]
    public class StatusAction : IDisposable
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段
        private Animation anim = null;

        private Transform target = null;

        private ActionGroup current = null;

        [SerializeField]
        private List<ActionGroup> groups = new List<ActionGroup>()
        {
            new ActionGroup() { Name=ActionGroupName.Idle,Des="待机", Loop=true},
            new ActionGroup() { Name=ActionGroupName.Move,Des="移动", Loop=true},
            new ActionGroup() { Name=ActionGroupName.Skill1,Des="技能1,小键盘数字按键1可触发"},
            new ActionGroup() { Name=ActionGroupName.Skill2,Des="技能2,小键盘数字按键2可触发"},
            new ActionGroup() { Name=ActionGroupName.Skill3,Des="技能3,小键盘数字按键3可触发"},
        };

        /// <summary>
        /// 功能组字典
        /// </summary>
        private Dictionary<string, ActionGroup> dic = new Dictionary<string, ActionGroup>();
        #endregion

        #region 属性

        /// <summary>
        /// 动画组件
        /// </summary>
        public Animation Anim
        {
            get { return anim; }
            set { anim = value; }
        }

        /// <summary>
        /// 变换组件
        /// </summary>
        public Transform Target
        {
            get { return target; }
            set { target = value; }
        }

        /// <summary>
        /// 当前动作组
        /// </summary>
        public ActionGroup Current
        {
            get { return current; }
            set { current = value; }
        }

        /// <summary>
        /// 动作组列表
        /// </summary>
        public List<ActionGroup> Groups
        {
            get { return groups; }
            set { groups = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init()
        {
            int length = Groups.Count;
            for (int i = 0; i < length; i++)
            {
                ActionGroup group = Groups[i];
                dic.Add(group.Name, group);
                group.Anim = Anim;
                group.Init();
            }
        }

        public void Update()
        {
            if (Current != null) Current.Update();
        }

        /// <summary>
        /// 设置当前动作组
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public bool Set(string name)
        {
            if (string.IsNullOrEmpty(name)) return false;
            if (dic.ContainsKey(name))
            {
                if (Current != null) Current.Reset();
                Current = dic[name];
                Current.Start();
                return false;
            }
            iTrace.Error("Loong", string.Format("不包含名为:{0}的动作组", name));
            return false;
        }

        /// <summary>
        /// 获取
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public ActionGroup Get(string name)
        {
            if (string.IsNullOrEmpty(name)) return null;
            if (dic.ContainsKey(name)) return dic[name];
            return null;
        }

        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="name">名称</param>
        public void Add(string name, ActionGroup group)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (group == null) return;
            if (dic.ContainsKey(name))
            {
                iTrace.Error("Loong", string.Format("以包含名称为:{0}的动作组", name));
            }
            else
            {
                group.Name = name;
                group.Init();
                Groups.Add(group);
                dic.Add(name, group);
            }
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="name"></param>
        public void Remove(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (dic.ContainsKey(name))
            {
                ActionGroup group = dic[name];
                Groups.Remove(group);
                dic.Remove(name);
                group.Dispose();
            }
        }

        public void Dispose()
        {
            dic.Clear();
            Anim = null;
            Target = null;
            Current = null;
            while (Groups.Count != 0)
            {
                ActionGroup group = Groups[0];
                Groups.RemoveAt(0);
                group.Dispose();
            }
            ObjPool.Instance.Add(this);
        }

        #endregion

        #region 编辑器
#if UNITY_EDITOR
        public void Draw(Object obj, IList lst, int idx)
        {
            UIDrawTool.IDrawLst<ActionGroup>(obj, groups, "groups", "功能组列表");
        }
#endif
        #endregion
    }
}
#endif