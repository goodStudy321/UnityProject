using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;

using Loong.Game;

public class UnitAnimation
{
    #region ˽�г�Ա����
    //����״̬
    private AnimationState animationState = null;
    //�������
    private Animation animation = null;
    // ���е�ǰ������Ȩ��
    private int totalWeight = 0;
    //����������
    private AnimSlotData activeSlot = null;
    //����ʱ������
    private float actionTimeScale = 1.0f;
    private float CurrentAnimScale = 1;
    //�����ٶ�
    private float animationSpeed = 1f;
    private float slowAnimationSpeed = 1f;
    private float straightSpeed = 0.001f;
    //��λTransform
    private GameObject UnitOject;
    //������Ⱦ�޳���ʽ
    private AnimationCullingType cullintType = AnimationCullingType.BasedOnRenderers;
    private AnimationCullingType changeType;
    #endregion

    #region ����

    /// <summary>
    /// ����״̬
    /// </summary>
    public AnimationState AnimationState
    {
        get { return animationState; }
    }

    /// <summary>
    /// �������
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
    /// ���ö���ʱ��ϵ�����ţ�ͬ�����ö����ٶȣ�
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
    /// �����ٶ�
    /// </summary>
    public float AnimationSpeed
    {
        get { return animationSpeed; }
        set { animationSpeed = value; }
    }

    /// <summary>
    /// �ٻ������ٶ�
    /// </summary>
    public float SlowAnimationSpeed
    {
        get { return slowAnimationSpeed; }
        set { slowAnimationSpeed = value; }
    }

    /// <summary>
    /// Ӳֵ�����ٶ�
    /// </summary>
    public float StraightSpeed
    {
        get { return straightSpeed; }
    }

    #endregion

    #region ��������

    /// <summary>
    /// ���õ�λTransform
    /// </summary>
    public void SetUnitObject(GameObject gameOject)
    {
        UnitOject = gameOject;
        SetAnimCmpnt();
    }

    /// <summary>
    /// ���ö����ٶ�
    /// </summary>
    /// <param name="timeScale">ʱ������ϵ��</param>
    public void MultiplyAnimationSpeed(float timeScale)
    {
        if (animationState == null) return;
        animationState.speed *= timeScale;
    }

    /// <summary>
    /// ���ö����ٶ�
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
    /// ��������
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
    /// ���Ŷ���
    /// </summary>
    /// <param name="animState">����״̬</param>
    /// <param name="BlendTime">���ʱ��</param>
    /// <param name="bForceRender">ǿ����Ⱦ</param>
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
    /// ����poseʱ��
    /// </summary>
    public void OnEnterPoseTime()
    {
        SetAnimationSpeed(0.001f);
    }

    /// <summary>
    /// ��ʼӲֵ
    /// </summary>
    public void BeginStaight()
    {
        SetAnimationSpeed(StraightSpeed);
    }

    /// <summary>
    /// ����Ӳֵ
    /// </summary>
    public void EndStaight(ActionStatus actionStatus)
    {
        ResetAnimationSpeed(actionStatus);
    }

    /// <summary>
    /// ��ʼ�ٻ�
    /// </summary>
    /// <param name="speed"></param>
    public void BeginSlow(float speed)
    {
        SetAnimationSpeed(speed);
    }

    /// <summary>
    /// �����ٻ�
    /// </summary>
    public void EndSlow(ActionStatus actionStatus)
    {
        ResetAnimationSpeed(actionStatus);
    }

    /// <summary>
    /// ���ʱװ
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

    #region ˽�з���

    /// <summary>
    /// ���ö������
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
    /// ���ö����ٶ�
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
    /// �ı䶯��
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
    /// ��ȡ����
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
    /// ���ö����Ƿ��ڲ���Ⱦʱ�޳�
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
