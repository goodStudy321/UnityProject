using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;
using Loong.Game;

public class UnitEffects
{
    #region ˽�б���
    /// ������Ч���б�
    protected List<PlayEffectEvent> behitEffectInfoList = new List<PlayEffectEvent>();
    // ������Ч�б�
    protected List<PlayEffectEvent> playEffectList = new List<PlayEffectEvent>();
    /// <summary>
    /// ����Ч������ʱ��
    /// </summary>
    private float mHitedEffectLimit = 0;
    #endregion

    #region ����
    #endregion

    #region ��������
    /// <summary>
    /// ��ӵ�λ��Ч
    /// </summary>
    /// <param name="effectEvent"></param>
    /// <returns></returns>
    public bool AddPlayerEffectEvent(PlayEffectEvent effectEvent)
    {
        if (effectEvent.StopMode == 0x10 &&
            playEffectList.Count > 0 &&
            playEffectList.FindIndex(delegate (PlayEffectEvent eff) { return (eff.StopMode == 0x10 && eff.Resname == effectEvent.Resname); }) != -1)
            return false;
        playEffectList.Add(effectEvent);
        return true;
    }

    /// <summary>
    /// ��ӵ�λ������Ч
    /// </summary>
    /// <param name="effectEvent"></param>
    public void AddPlayBehitEffectEvent(PlayEffectEvent effectEvent)
    {
        behitEffectInfoList.Add(effectEvent);
    }
    
    /// <summary>
    /// �Ƴ�������Ч���
    /// </summary>
    /// <param name="effectName"></param>
    public void RemoveActionEffectCheck(string effectName)
    {
        if (playEffectList.Count == 0)
            return;
        int idx = playEffectList.FindIndex(delegate (PlayEffectEvent eff) { return eff.StopMode == 0x10 && eff.Resname == effectName; });
        if (idx == -1) return;
        playEffectList[idx].StopEffect();
        playEffectList.RemoveAt(idx);
    }
    
    /// <summary>
    /// �Ƴ���Ч
    /// </summary>
    /// <param name="go"></param>
    /// <returns></returns>
    public void RemoveEffect(GameObject go)
    {
        if (RemoveEffectFromList(go, playEffectList))
            return;
        RemoveEffectFromList(go, behitEffectInfoList);
    }

    /// <summary>
    /// ��ʼ������Ч���
    /// </summary>
    /// <param name="actionType"></param>
    public void OnActionEffectCheck(ActionRunningState actionType)
    {
        for (int i = 0; i < playEffectList.Count;)
        {
            PlayEffectEvent effectEvent = playEffectList[i];
            if ((effectEvent.StopMode & (1 << 1)) != 0 && actionType == ActionRunningState.Finish ||
                (effectEvent.StopMode & (1 << 3)) != 0 && actionType == ActionRunningState.Interrupt ||
                (effectEvent.StopMode & (1 << 2)) != 0 && actionType == ActionRunningState.Hurt)
            {
                effectEvent.StopEffect();
                playEffectList.RemoveAt(i);
                continue;
            }
            i++;
        }
    }

    /// <summary>
    /// ������Ч
    /// </summary>
    public void Destroy()
    {
        ClearEffects(behitEffectInfoList);
        ClearEffects(playEffectList);
    }

    /// <summary>
    /// �����ܻ���Ч����Ч
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="attackee"></param>
    /// <param name="attackData"></param>
    /// <param name="targetPosition"></param>
    public void CreateOnHitEffectAndSoundEvent(Unit attacker, Unit attackee, AttackDefData attackData, Vector3 targetPosition)
    {
        if (!ShowEffectMgr.instance.CheckHitedEff(attacker,attackee))
            return;
        if (mHitedEffectLimit > 0)
            return;
        if (!ShowEffectMgr.instance.AddShowEffect(attackData.HitedEffect, attacker, attackee, true))
            return;
        mHitedEffectLimit = 0.2f;
        AttackDefData attData = attackData;
        // ������Ч
        if (!string.IsNullOrEmpty(attData.HitedSound))
        {
            //// LY edit begin ////
            //Audio.Instance.Play(attackData.HitedSound);
            if (attacker.CanPlaySound() == true || attackee.CanPlaySound() == true)
            {
                Audio.Instance.Play(attackData.HitedSound);
            }
            //// LY edit end ////
        }
        // ������Ч��
        if (string.IsNullOrEmpty(attData.HitedEffect))
            return;
        Vector3 hitPosition = Vector3.zero;
        Vector3 hitForward = Vector3.zero;

        float s = attData.HitedEffectScale * 0.01f;

        if (attData.HitedEffectOffset.Vector3Data_X != 0
            || attData.HitedEffectOffset.Vector3Data_Y != 0
            || attData.HitedEffectOffset.Vector3Data_Z != 0)
        {
            if (attackee.ActionStatus.HeightState == ActionCommon.HeightStatusFlag.Stand)
                Utility.Vector3_Copy(attData.HitedEffectOffset, ref hitPosition);
            else if (attackee.ActionStatus.HeightState == ActionCommon.HeightStatusFlag.LowAir)
                Utility.Vector3_Copy(attData.LowAirHitedEffectOffset, ref hitPosition);

            hitPosition *= 0.01f;
            Vector3 forward = (attacker.Position - targetPosition).normalized;
            hitForward = forward;
            Matrix4x4 matrix4x4 = new Matrix4x4();
            matrix4x4 = Matrix4x4.TRS(targetPosition, Quaternion.LookRotation(forward), Vector3.one);
            hitPosition = matrix4x4.MultiplyPoint(hitPosition);
        }
        else
        {
            Vector3 forward = (attacker.Position - targetPosition).normalized;
            hitForward = forward;
            hitPosition = targetPosition + forward * attackee.ActionStatus.Bounding.x * 0.5f;
            hitPosition = new Vector3(hitPosition.x, hitPosition.y + attackee.ActionStatus.Bounding.y * 0.7f, hitPosition.z);
        }

        GameEventManager.instance.EnQueue(
            new PlayEffectEvent(attData.HitedEffect, attackee, hitPosition,
            new Vector3(s, s, s), hitForward, 0, 0), true);
    }

    public void Update()
    {
        CheckBehitEffect();
        UpdateTime();
    }

    public void Dispose()
    {
        behitEffectInfoList.Clear();
        playEffectList.Clear();
        mHitedEffectLimit = 0;
}
    #endregion

    #region ˽�з���
    /// <summary>
    /// ����ʱ��
    /// </summary>
    private void UpdateTime()
    {
        if (mHitedEffectLimit <= 0)
            return;
        mHitedEffectLimit -= Time.deltaTime;
    }
    /// <summary>
    /// ��鱻����Ч���б�
    /// </summary>
    private void CheckBehitEffect()
    {
        for (int i = 0; i < behitEffectInfoList.Count; i++)
        {
            PlayEffectEvent playEffectEvent = behitEffectInfoList[i];
            if (!playEffectEvent.isEffectStop())
                return;
            behitEffectInfoList[i].StopEffect();
            behitEffectInfoList.Remove(behitEffectInfoList[i]);
        }
    }

    /// <summary>
    /// �Ƴ�������Ч
    /// </summary>
    /// <param name="go"></param>
    /// <returns></returns>
    private bool RemoveEffectFromList(GameObject go, List<PlayEffectEvent> effectList)
    {
        if (go == null)
            return false;
        if (effectList.Count == 0)
            return false;
        PlayEffectEvent effect = effectList.Find(delegate (PlayEffectEvent eff) { return eff.EffectObject == go; });
        if (effect == null)
            return false;
        effect.EffectObject = null;
        effectList.Remove(effect);
        return true;
    }

    /// <summary>
    /// �����Ч
    /// </summary>
    /// <param name="effectList"></param>
    private void ClearEffects(List<PlayEffectEvent> effectList)
    {
        int count = effectList.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
            effectList[i].StopEffect();
        effectList.Clear();
    }
    #endregion
}
