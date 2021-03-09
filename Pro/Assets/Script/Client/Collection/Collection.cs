using System;
using ProtoBuf;
using UnityEngine;
using Phantom.Protocal;
using System.Collections;
using System.Collections.Generic;
namespace Loong.Game
{

    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        02898ea6-c5cb-4a76-81fb-6e404a6cbbc5
    */
    using Lang = Phantom.Localization;

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/12 15:26:52
    /// BG:
    /// </summary>
    public class Collection : CollectionBase
    {
        #region 字段
        /// <summary>
        /// 玩家
        /// </summary>
        private Unit hero = null;

        private CollFeedbackCfg fb = null;

        private Coroutine feedbackCorou = null;
        /// <summary>
        /// 动画组件
        /// </summary>
        private Animation animation = null;

        /// <summary>
        /// 中断计时器
        /// </summary>
        private Timer interruptTimer = null;

        /// <summary>
        /// 头顶显示
        /// </summary>
        private CommenNameBar nameBar = null;

        /// <summary>
        /// 区域逻辑状态
        /// </summary>
        private ProcessState state = ProcessState.None;

        #region 范围数据
        /// <summary>
        /// 自身半径
        /// </summary>
        private float selfRadius = 0;

        /// <summary>
        /// 英雄半径
        /// </summary>
        private float heroRadius = 0;

        /// <summary>
        /// 自身位置
        /// </summary>
        private Vector2 selfPos = Vector2.zero;

        /// <summary>
        /// 角色位置
        /// </summary>
        private Vector2 heroPos = Vector2.zero;

        /// <summary>
        /// 动作数据
        /// </summary>
        private ActionGroupData groupData = null;


        #endregion
        #endregion

        #region 属性

        /// <summary>
        /// 检查状态
        /// </summary>
        public ProcessState State
        {
            get { return state; }
            set { state = value; }
        }


        #endregion

        #region 构造方法
        public Collection()
        {

        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 检查
        /// </summary>
        /// <returns></returns>
        private bool Check()
        {
            if (CollectionMgr.State != CollectionState.None) return false;
            if (CollectionMgr.CurID != -1) if (CollectionMgr.CurID != UID) return false;
            if (Go == null) return false;
            if (!Go.activeSelf) return false;
            if (Info == null) return false;
            hero = InputMgr.instance.mOwner;
            if (hero == null) return false;
            if (hero.ActionStatus == null) return false;
            if (hero.Dead || hero.DestroyState) return false;
            return true;
        }

        /// <summary>
        /// 判断是否包含
        /// </summary>
        /// <returns></returns>
        private bool Contains()
        {
            groupData = hero.ActionStatus.ActionGroupData;
            if (groupData == null) return false;
            selfRadius = Info.distance * 0.01f;
            heroRadius = (groupData.BoundingLength > groupData.BoundingWidth) ? groupData.BoundingWidth : groupData.BoundingLength;
            heroRadius *= 0.01f;
            selfPos.Set(Go.transform.position.x, Go.transform.position.z);
            heroPos.Set(hero.Position.x, hero.Position.z);
            float distance = Vector2.Distance(selfPos, heroPos);
            selfRadius += heroRadius;
            if (distance < selfRadius) return true;
            return false;
        }

        #region 动画
        /// <summary>
        /// 检查动画剪辑是否存在
        /// </summary>
        /// <returns></returns>
        private bool CheckClip(string clipName)
        {
            if (animation == null) return false;
            if (string.IsNullOrEmpty(clipName)) return false;
            AnimationClip clip = animation.GetClip(clipName);
            if (clip == null) return false;
            return true;
        }

        /// <summary>
        /// 设置循环
        /// </summary>
        /// <param name="clipName"></param>
        private void SetLoop(string clipName)
        {
            if (!CheckClip(clipName)) return;
            AnimationState state = animation[clipName];
            state.wrapMode = WrapMode.Loop;
        }

        /// <summary>
        /// 直接播放动画
        /// </summary>
        /// <param name="clipName"></param>
        private void Play(string clipName)
        {
            if (CheckClip(clipName)) animation.Play(clipName);
        }

        private void Stop(string clipName)
        {
            if (CheckClip(clipName)) animation.Stop(clipName);
        }

        /// <summary>
        /// 淡入淡出动画
        /// </summary>
        /// <param name="clipName"></param>
        private void CrossFade(string clipName)
        {
            if (CheckClip(clipName)) animation.CrossFade(clipName);
        }

        /// <summary>
        /// 在队列中淡入淡出动画
        /// </summary>
        /// <param name="clipName"></param>
        private void CrossfadeQueued(string clipName)
        {
            if (CheckClip(clipName)) animation.CrossFadeQueued(clipName);
        }


        /// <summary>
        /// 检查反馈
        /// </summary>
        private void CheckFeedback()
        {
            if (fb == null) return;
            if (string.IsNullOrEmpty(fb.name)) return;
            var go = ComponentBind.Get(fb.name);
            if (go == null)
            {
                iTrace.Error("Loong", "采集物:{0} {1},无名为:{2}的反馈组件", Info.id, Info.model, fb.name);
            }
            else
            {
                bool at = fb.at == 0 ? false : true;
                go.SetActive(at);
                if (fb.time > 0)
                {
                    feedbackCorou = MonoEvent.Start(YeildFeedback());
                }
            }
        }

        private IEnumerator YeildFeedback()
        {
            float tm = fb.time * 0.001f;
            yield return new WaitForSeconds(tm);
            GameObject go = ComponentBind.Get(fb.name);
            feedbackCorou = null;
            if (go == null) yield break;
            bool at = fb.at == 0 ? true : false;
            go.SetActive(at);
        }
        #endregion

        #region 范围逻辑
        private void None()
        {
            if (!Check()) return;
            if (Contains())
            {
                if (CollectionMgr.State == CollectionState.Wait) return;
                State = ProcessState.Enter;
                CollectionMgr.CurID = UID;
                CollectionMgr.State = CollectionState.Wait;
                EventMgr.Trigger(EventKey.EnterCollect, UID, Info.id);
            }
        }

        private void Enter()
        {
            //UITip.eLog(string.Format("进入采集物范围:{0}", UID));
        }

        private void Execute()
        {
            //正在采集中
            if (CollectionMgr.State == CollectionState.Run)
            {
                if (InputMgr.instance.mOwner.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Move)
                {
                    CollectionMgr.State = CollectionState.Interupt;
                    EventMgr.Trigger(EventKey.ReqStopCollect);
                }
            }
            else if (CollectionMgr.State == CollectionState.Interupt)
            {
                if (!Contains())
                {
                    State = ProcessState.Exit;
                }
            }
            else if (CollectionMgr.State == CollectionState.Wait)
            {
                if (!Contains())
                {
                    UIMgr.Close(UIName.UICollection);
                    CollectionMgr.Reset();
                    State = ProcessState.Exit;
                }
            }
            else if (CollectionMgr.State == CollectionState.None)
            {
                if (state == ProcessState.Execute || (!Contains()))
                {
                    CollectionMgr.Reset();
                    State = ProcessState.None;
                }
            }
        }

        private void Exit()
        {
            //UITip.eLog(string.Format("离开采集物范围:{0}", UID));
        }

        /// <summary>
        /// 开始中断
        /// </summary>
        private void StartInterupt()
        {
            if (interruptTimer == null) interruptTimer = ObjPool.Instance.Get<Timer>();
            interruptTimer.Reset();
            interruptTimer.Seconds = 2;
            interruptTimer.complete += InteruptEndCb;
            interruptTimer.Start();
        }

        /// <summary>
        /// 中断结束回调
        /// </summary>
        private void InteruptEndCb()
        {
            if (interruptTimer != null)
            {
                interruptTimer.AutoToPool();
            }
            interruptTimer = null;
            CollectionMgr.Reset();
            State = ProcessState.None;
            UIMgr.Close(UIName.UICollection);
        }

        #endregion

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public override void ReqBegCollect()
        {
            m_collect_start_tos req = ObjPool.Instance.Get<m_collect_start_tos>();
            req.collect_id = UID;
            NetworkClient.Send<m_collect_start_tos>(req);
            CollectionMgr.State = CollectionState.Req;

#if UNITY_EDITOR
            //UITip.eLog(string.Format("请求[开始]采集:{0}", UID));
#endif
        }

        public override void RespBegCollect(m_collect_start_toc resp)
        {
            if (resp.err_code == 0)
            {
                hero.ActionStatus.ChangeAction(Info.runAni, 0);
                CollectionMgr.State = CollectionState.Run;
                Vector3 dir = Go.transform.position - hero.Position;
                dir.y = 0; dir.Normalize(); hero.SetForward(dir);
                if (Info.triTy == 0) CrossFade(Info.triAni);

#if UNITY_EDITOR
                UITip.eError("响应[开始]采集,成功,{0}", UID);
#endif
                if (fb != null && fb.ty == 1)
                {
                    CheckFeedback();
                    FlowChartMgr.Start(fb.flowName);
                }
            }
            else
            {
                CollectionMgr.Reset();
                State = ProcessState.None;
                var error = ErrorCodeMgr.GetError(resp.err_code);
                if (error == null) error = string.Format("{0} is NULL", resp.err_code);
                UITip.LocalError(618001, error);
            }
            EventMgr.Trigger(EventKey.RespBegCollect, resp.collect_id, resp.collect_time, resp.err_code);
        }

        public override void ReqStopCollect()
        {
            m_collect_stop_tos req = ObjPool.Instance.Get<m_collect_stop_tos>();
            NetworkClient.Send<m_collect_stop_tos>(req);
            //UITip.eLog(string.Format("请求[停止]采集:{0}", UID));
        }

        public override void RespStopCollect(m_collect_stop_toc resp)
        {
            if (resp.err_code == 0)
            {
                UITip.LocalLog(618000);
                CrossFade(Info.idleAni);
            }
            else
            {
                string error = ErrorCodeMgr.GetError(resp.err_code);
                UITip.LocalError(618001, error);
            }
            EventMgr.Trigger(EventKey.RespStopCollect, resp.collect_id, resp.err_code);
            StartInterupt();
        }

        public override void RespEndCollect(m_collect_succ_toc resp)
        {
            EventMgr.Trigger(EventKey.RespEndCollect, resp.collect_id, resp.err_code);
            State = ProcessState.None;
            hero.ActionStatus.ChangeAction("N0000", 0);
            CollectionMgr.Reset();
            if (resp.err_code == 0)
            {
                UITip.LocalLog(618002);
                /*if (Info.removeOnSuccess > 0)
                {
                    Dispose();
                }
                else
                {*/
                if (Info.triTy == 1) CrossfadeQueued(Info.triAni);
                CrossfadeQueued(Info.floAni);
                if (fb == null) return;
                if (fb.ty == 0)
                {
                    CheckFeedback();
                    FlowChartMgr.Start(fb.flowName);
                }
                /*}*/
            }
            else
            {
                string error = ErrorCodeMgr.GetError(resp.err_code);
                UITip.LocalError(618003, error);
            }
        }

        public override void Initilize()
        {
            animation = Go.GetComponentInChildren<Animation>();
            fb = CollFeedbackCfgManager.instance.Find(Info.id);
            CrossFade(Info.bornAni);
            CrossfadeQueued(Info.idleAni);
            SetLoop(Info.idleAni);
            if (nameBar == null) nameBar = CommenNameBar.Create(Go.transform, "", Info.name, TopBarFty.CollectBarStr);
            //Go.name = string.Format("{0}_{1}_{2}", UID, Info.id, Info.name);
            Go.name = UID.ToString();
        }

        public override void Update()
        {
            switch (state)
            {
                case ProcessState.None:
                    None();
                    break;
                case ProcessState.Enter:
                    Enter(); state = ProcessState.Execute;
                    break;
                case ProcessState.Execute:
                    Execute();
                    break;
                case ProcessState.Exit:
                    Exit(); state = ProcessState.None;

                    break;
                default:
                    break;
            }
            if (nameBar != null) nameBar.Update();
        }

        public override void Dispose()
        {

            fb = null;
            State = ProcessState.None;
            if (nameBar != null)
            {
                nameBar.Dispose();
                nameBar = null;
            }
            if (CollectionMgr.CurID == UID)
            {
                UIMgr.Close(UIName.UICollection);
                CollectionMgr.Reset();
            }
            if (interruptTimer != null)
            {
                interruptTimer.AutoToPool();
                interruptTimer = null;
            }
            if (feedbackCorou != null)
            {
                MonoEvent.Stop(feedbackCorou);
                feedbackCorou = null;
            }
            base.Dispose();
        }
        #endregion
    }
}