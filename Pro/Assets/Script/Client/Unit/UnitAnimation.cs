using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;

using Loong.Game;

public class UnitAnimation
{
    #region 私有成员变量
    //动画状态
    private AnimationState animationState = null;
    //动画组件
    private Animation animation = null;
    // 所有当前动画的权重
    private int totalWeight = 0;
    //动画曹数据
    private AnimSlotData activeSlot = null;
    //动作时间缩放
    private float actionTimeScale = 1.0f;
    private float CurrentAnimScale = 1;
    //动画速度
    private float animationSpeed = 1f;
    private float slowAnimationSpeed = 1f;
    private float straightSpeed = 0.001f;
    //单位Transform
    private GameObject UnitOject;
    //动画渲染剔除方式
    private AnimationCullingType cullintType = AnimationCullingType.BasedOnRenderers;
    private AnimationCullingType changeType;
    #endregion

    #region 属性

    /// <summary>
    /// 动画状态
    /// </summary>
    public AnimationState AnimationState
    {
        get { return animationState; }
    }

    /// <summary>
    /// 动画组件
    /// </summary>
    public Animation Animation
    {
        get
        {
            if (animation == null) 
                SetAnimCmpnt(); 
            return animation;
        }
    }

    /// <summary>
    /// 设置动画时间系数缩放（同步设置动画速度）
    /// </summary>
    public float ActionTimeScale
    {
        get { return actionTimeScale; }
        set
        {
            MultiplyAnimationSpeed(value);
            actionTimeScale = value;
        }
    }

    /// <summary>
    /// 动画速度
    /// </summary>
    public float AnimationSpeed
    {
        get { return animationSpeed; }
        set { animationSpeed = value; }
    }

    /// <summary>
    /// 迟缓动画速度
    /// </summary>
    public float SlowAnimationSpeed
    {
        get { return slowAnimationSpeed; }
        set { slowAnimationSpeed = value; }
    }

    /// <summary>
    /// 硬值动画速度
    /// </summary>
    public float StraightSpeed
    {
        get { return straightSpeed; }
    }

    #endregion

    #region 公开方法

    /// <summary>
    /// 设置单位Transform
    /// </summary>
    public void SetUnitObject(GameObject gameOject)
    {
        UnitOject = gameOject;
        SetAnimCmpnt();
    }

    /// <summary>
    /// 设置动画速度
    /// </summary>
    /// <param name="timeScale">时间缩放系数</param>
    public void MultiplyAnimationSpeed(float timeScale)
    {
        if (animationState == null) return;
        animationState.speed *= timeScale;
    }

    /// <summary>
    /// 设置动画速度
    /// </summary>
    /// <param name="action"></param>
    public void SetAnimationTimeScale(ActionData actionData)
    {
        if (AnimationState == null)
            return;
        if (actionData.ActionStatus == (int)ActionStatus.EActionStatus.EAS_Move)
            ActionTimeScale = Mathf.Min(CurrentAnimScale, 3);
        else
            ActionTimeScale = CurrentAnimScale;
    }

    /// <summary>
    /// 动画播放
    /// </summary>
    /// <param name="action"></param>
    public void PlayAnimation(ActionData actionData)
    {
        AnimationState animState = FetchAnimation(actionData, 0, null);
        if (animState == null)
            return;
        PlayAnim(animState, actionData.BlendTime, actionData.UpdateSkeleton);
    }

    /// <summary>
    /// 播放动画
    /// </summary>
    /// <param name="animState">动画状态</param>
    /// <param name="BlendTime">混合时间</param>
    /// <param name="bForceRender">强制渲染</param>
    public void PlayAnim(AnimationState animState, float BlendTime, bool bForceRender)
    {
        animationState = animState;
        float fadeLength = BlendTime * 0.001f;
        if (fadeLength == 0)
            Animation.Play(animState.name);
        else
            Animation.CrossFade(animState.name, fadeLength);

        //ChangeForceSkinAnimation(bForceRender);
    }

    public void SetAnimationSpeed(float animSpeed)
    {
        if (animationState == null) return;
        animationState.speed = animSpeed;
    }

    /// <summary>
    /// 进入pose时间
    /// </summary>
    public void OnEnterPoseTime()
    {
        SetAnimationSpeed(0.001f);
    }

    /// <summary>
    /// 开始硬值
    /// </summary>
    public void BeginStaight()
    {
        SetAnimationSpeed(StraightSpeed);
    }

    /// <summary>
    /// 结束硬值
    /// </summary>
    public void EndStaight(ActionStatus actionStatus)
    {
        ResetAnimationSpeed(actionStatus);
    }

    /// <summary>
    /// 开始迟缓
    /// </summary>
    /// <param name="speed"></param>
    public void BeginSlow(float speed)
    {
        SetAnimationSpeed(speed);
    }

    /// <summary>
    /// 结束迟缓
    /// </summary>
    public void EndSlow(ActionStatus actionStatus)
    {
        ResetAnimationSpeed(actionStatus);
    }

    /// <summary>
    /// 清除时装
    /// </summary>
    public void Clear()
    {
        animation = null;
        //GameObject go = UnitOject;
        UnitOject = null;
        //Loong.Game.GbjPool.Instance.Add(go);
        animationState = null;
    }

    public void Dispose()
    {
        animationState = null;
        animation = null;
        totalWeight = 0;
        activeSlot = null;
        actionTimeScale = 1.0f;
        CurrentAnimScale = 1;
        animationSpeed = 1f;
        slowAnimationSpeed = 1f;
        straightSpeed = 0.001f;
        UnitOject = null;
        cullintType = AnimationCullingType.BasedOnRenderers;
        changeType = AnimationCullingType.AlwaysAnimate;
}

    #endregion

    #region 私有方法

    /// <summary>
    /// 设置动画组件
    /// </summary>
    private void SetAnimCmpnt()
    {
        if (UnitOject == null)
            return;
        animation = UnitOject.GetComponent<Animation>();
        if (animation == null) animation = UnitOject.GetComponentInChildren<Animation>();
        if (animation == null)
        {
            iTrace.Error("LY", "Can not find Animation component in unit object !!! " + UnitOject.name);
        }
    }

    /// <summary>
    /// 重置动画速度
    /// </summary>
    private void ResetAnimationSpeed(ActionStatus actionStatus)
    {
        if (animationState == null) return;
        if (actionStatus.IsStraightState())
            SetAnimationSpeed(StraightSpeed);
        else if (actionStatus.IsSlowState())
            SetAnimationSpeed(SlowAnimationSpeed);
        else
            animationState.speed = AnimationSpeed;
    }


    /// <summary>
    /// 改变动画
    /// </summary>
    /// <param name="action"></param>
    /// <param name="data"></param>
    private void ChangeAnimation(ActionData action, AnimSlotData data)
    {
        if (data == null || action == null) return;
        if (AnimationState != null && AnimationState.name == data.Animation) return;
        AnimationState animState = FetchAnimation(action, 0, data);
        if (animState == null) return;
        animState.wrapMode = WrapMode.Loop;
        PlayAnim(animState, action.BlendTime, action.UpdateSkeleton);
    }

    /// <summary>
    /// 获取动画
    /// </summary>
    /// <param name="action"></param>
    /// <param name="startTime"></param>
    /// <param name="data"></param>
    /// <returns></returns>
    private AnimationState FetchAnimation(ActionData action, float startTime, AnimSlotData data)
    {
        if (action == null || action.AnimSlotList.Count == 0 || Animation == null)
            return null;

        int animationIndex = 0;
        if (action.AnimSlotList.Count > 1)
        {
            int count = action.AnimSlotList.Count;
            for (int index = 0; index < count; index++)
            {
                totalWeight += action.AnimSlotList[index].Weight;
            }
            int weight = UnityEngine.Random.Range(0, totalWeight);
            int tempWeight = 0;
            for (int index = 0; index < count; index++)
            {
                tempWeight += action.AnimSlotList[index].Weight;
                if (weight < tempWeight)
                {
                    animationIndex = index;
                    break;
                }
            }
            totalWeight = 0;
        }
        AnimSlotData animSlot = action.AnimSlotList[animationIndex];
        if (action.MoveChange)
        {
            for (int i = 0; i < action.AnimSlotList.Count; ++i)
            {
                if (!action.AnimSlotList[i].UseDir)
                {
                    animSlot = action.AnimSlotList[i];
                    break;
                }
            }
            if (data != null)
                animSlot = data;

            if (activeSlot != null)
                animSlot = activeSlot;

            if (activeSlot != null
                && AnimationState != null
                && AnimationState.name == animSlot.Animation)
                startTime = AnimationState.normalizedTime;
        }

        if (animSlot == null)
            return null;

        AnimationState animState = null;
        animState = Animation[animSlot.Animation];
        if (animState == null)
        {
            string unitName = UnitOject != null ? UnitOject.name : "";
#if UNITY_EDITOR
            Debug.LogError(string.Format("{0}Fail to change animation: {1}/{2}", unitName, action.AnimID, animSlot.Animation));
#endif
            return null;
        }

        animState.normalizedTime = startTime == 0 ? animSlot.Start * 0.01f : startTime;
        int animTime = action.AnimTime;
        if (action.AnimTime <= 0)
        {
            animTime = 1;
#if UNITY_EDITOR
            Debug.LogError("setup.act has config an animation's time is 0");
#endif
        }
        float speed = (animSlot.End - animSlot.Start) * animState.length * 10.0f / animTime;
        animState.speed = speed;
        AnimationSpeed = speed;
        return animState;
    }

    /// <summary>
    /// 设置动画是否在不渲染时剔除
    /// </summary>
    /// <param name="bForce"></param>
    private void ChangeForceSkinAnimation(bool bForce)
    {
        changeType = bForce ? AnimationCullingType.AlwaysAnimate : AnimationCullingType.BasedOnRenderers;
        if (changeType == cullintType)
            return;
        cullintType = changeType;
        Animation.cullingType = cullintType;
    }

    #endregion
}
