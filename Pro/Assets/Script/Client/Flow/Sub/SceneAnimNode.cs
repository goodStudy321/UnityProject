using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Loong.Game;

#if UNITY_EDITOR
using Loong;
using UnityEditor;
#endif


namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.10.27,14:36:32
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class SceneAnimNode : FlowChartNode
    {
        /// <summary>
        /// ComponentBinding的Path
        /// </summary>
        public string key;

        /// <summary>
        /// 开始前隐藏
        /// </summary>
        public bool begHidden;

        /// <summary>
        /// 结束后隐藏
        /// </summary>
        public bool endHidden;

        /// <summary>
        /// 动画名称
        /// </summary>
        public string animName = "";

        /// <summary>
        /// 动画组件
        /// </summary>
        private Animation anim;

        /// <summary>
        /// 动画设计组件
        /// </summary>
        private Animator anit;

        private Coroutine coro;

        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void SetProperty()
        {
            anit = ComponentBind.Get<Animator>(key);
            anim = ComponentBind.Get<Animation>(key);
        }

        private void StopAnit()
        {
            if (anit != null) anit.speed = 0;
        }

        private void StopAnim()
        {
            if (anim == null) return;
            if (anim.clip == null) return;
            AnimationState anis = anim[anim.clip.name];
            anis.normalizedTime = 1f;
        }

        private void Clear()
        {
            if (coro != null) MonoEvent.Stop(coro);
            coro = null;
        }

        private void PlayAnit()
        {
            if (anit == null) return;
            anit.gameObject.SetActive(true);
            anit.speed = 1;
            anit.Play(animName);
            coro = MonoEvent.Start(YieldInvoke());
        }

        private IEnumerator YieldInvoke()
        {
            yield return new WaitForEndOfFrame();
            AnimatorStateInfo state = anit.GetCurrentAnimatorStateInfo(0);
            int cur = state.fullPathHash;
            int raw = Animator.StringToHash(string.Format("Base Layer.{0}", animName));
            if (cur != raw)
            {
                Debug.LogError(Format("Animator组件上没有发现名称为:{0}的动画片断", animName)); Complete();
            }
            else
            {
                yield return new WaitForSeconds(state.length);
                Complete();
            }
        }

        private IEnumerator YeildCB(float sec)
        {
            yield return new WaitForSeconds(sec);
            Complete();
        }

        private void PlayAnim()
        {
            if (anim == null) return;
            anim.gameObject.SetActive(true);
            AnimationClip clip = anim.GetClip(animName);
            if (clip == null)
            {
                Debug.LogError(Format(string.Format("Animation组件上没有发现名称为:{0}的动画片断", animName)));
                Complete(); return;
            }
            anim.CrossFade(animName, 0);
            coro = MonoEvent.Start(YeildCB(clip.length));
        }

        private void SetAvtive(bool active)
        {
            if (anit != null) anit.gameObject.SetActive(active);
            else if (anim != null) anim.gameObject.SetActive(active);
        }
        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            SetProperty();
            if (Check())
            {
                PlayAnit();
                PlayAnim();
            }
            else
            {
                Complete();
            }
        }



        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            SetAvtive(!endHidden);
        }


        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            ExString.Read(ref key, br);
            //key = br.ReadString();
            begHidden = br.ReadBoolean();
            endHidden = br.ReadBoolean();
            ExString.Read(ref animName, br);
            //animName = br.ReadString();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            ExString.Write(key, bw);
            //bw.Write(key);
            bw.Write(begHidden);
            bw.Write(endHidden);
            ExString.Write(animName, bw);
            //bw.Write(animName);
        }

        public override void Initialize()
        {
            base.Initialize();
            SetProperty();
            StopAnim();
            StopAnit();
            SetAvtive(!begHidden);
        }

        public override bool Check()
        {
            if (string.IsNullOrEmpty(key))
            {
                Debug.LogError(Format("绑定组件为空")); return false;
            }
            if (!ComponentBind.Exist(key))
            {
                string tip = string.Format("组件绑定没有发现键为:{0}的目标物体", key);
                Debug.LogError(Format(tip)); return false;
            }
            SetProperty();
            if (anit == null && anim == null)
            {
                string tip = string.Format("目标:{0}上既没有Animator组件,也没有Animation组件", key);
                Debug.LogError(Format(tip));
                return false;
            }
            if (string.IsNullOrEmpty(animName))
            {
                Debug.LogError(Format("播放动画名称为空")); return false;
            }
            return true;
        }

        public override void Dispose()
        {
            base.Dispose();
            Clear();

        }

        public override void Stop()
        {
            base.Stop();
            Clear();
        }
        #endregion


        #region 编辑器字段/属性/方法

#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as SceneAnimNode;
            if (node == null) return;
            key = node.key;
            begHidden = node.begHidden;
            endHidden = node.endHidden;
            animName = node.animName;
        }


        protected override void EditCompleteDynamicCustom()
        {
            Clear();
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.HelpBox("对于Animation组件:勾去Play Automatically\n对于Animator组件:创建一个空的默认状态,默认状态为黄色样式", MessageType.Warning);
            EditorGUILayout.Space();
            EditorGUILayout.BeginVertical(GUI.skin.box);
            EditorGUILayout.BeginHorizontal();
            key = EditorGUILayout.TextField("绑定组件:", key);
            if (GUILayout.Button("定位组件")) ComBindTool.Ping<ComponentBind>(key);
            EditorGUILayout.EndHorizontal();
            if (string.IsNullOrEmpty(key)) EditorGUILayout.HelpBox("必须输入绑定组件键值", MessageType.Error);
            begHidden = EditorGUILayout.Toggle("开始前隐藏", begHidden);
            endHidden = EditorGUILayout.Toggle("结束后隐藏:", endHidden);
            EditorGUILayout.Space();
            animName = EditorGUILayout.TextField("播放动画名称:", animName);
            if (string.IsNullOrEmpty(animName)) EditorGUILayout.HelpBox("动画名称不能为空", MessageType.Error);
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}