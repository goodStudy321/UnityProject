using UnityEngine;
using Loong.Game;

public class UnitOnHit
{
    /// <summary>
    /// ��λ�ܻ�
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="attackee"></param>
    /// <param name="hitDefinition"></param>
    /// <param name="hitData"></param>
    public void OnHit(Unit attacker, Unit attackee, HitAction hitDefinition, ActionCommon.HitData hitData)
    {
        // setup position.
        Vector3 position = Vector3.zero;
        float rotate = 0;
        ActionHelper.Decode(hitData.HitX, hitData.HitY, hitData.HitZ, hitData.HitDir, ref position, ref rotate);
        UnitEventMgr.ExecuteHit(attackee, attacker, position);
        // setup lash time.
        SetOnHitLash(attacker, attackee, hitData);
        attackee.mUnitEffects.CreateOnHitEffectAndSoundEvent(attacker, attackee, hitDefinition.AttackData, attackee.Position);

        if (Global.Mode == PlayMode.Network)
            return;

        //��ȡ�����˺���������Ϣ
        DamageInfo info = GetDamageInfo(attacker, attackee, hitDefinition, hitData);
        attackee.HP += info.finalDamage;
        SetOffineBatHp(attacker,attackee,info.finalDamage);
        if (info.finalDamage > 0)
            SymbolMgr.RestoreHp(attackee, info.finalDamage);
        else
        {
            attackee.mLastAttacker = attacker;
            bool isOwner = attackee.UnitUID == User.instance.MapData.UID ? true : false;
            bool isRole = attackee.mUnitAttInfo.UnitType == UnitType.Role ? true : false;
            SymbolMgr.Damage(attackee, info.finalDamage, isOwner, isRole, true);
            UnitEventMgr.ExecuteChange(attackee, info.finalDamage);
        }
        if (attackee.HP <= 0)
        {
            UnitMgr.instance.SetUnitDead(attackee);
        }
    }

    /// <summary>
    /// ��������ս��Ѫ��
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="attackee"></param>
    /// <param name="damage"></param>
    public void SetOffineBatHp(Unit attacker,Unit attackee,int damage)
    {
        if (GameSceneManager.instance.CurCopyType != CopyType.Offl1v1)
            return;
        if (attackee.HP > 0)
        {
            EventMgr.Trigger(EventKey.ChangeOffLInfo,false, attackee.UnitUID.ToString(), attackee.HP);
            return;
        }
        if (attackee.FightVal < attacker.FightVal)
        {
            OffLineBatMgr.instance.Clear();
            EventMgr.Trigger(EventKey.ChangeOffLInfo, true, attackee.UnitUID.ToString(), 0);
            return;
        }
        else if(attackee.FightVal == attacker.FightVal)
        {
            if(attackee.UnitUID != InputMgr.instance.mOwner.UnitUID)
            {
                OffLineBatMgr.instance.Clear();
                EventMgr.Trigger(EventKey.ChangeOffLInfo, true, attackee.UnitUID.ToString(), 0);
            }
        }
        attackee.HP = 10;
        EventMgr.Trigger(EventKey.ChangeOffLInfo, false, attackee.UnitUID, attackee.HP);
    }

    /// <summary>
    /// �����ܻ����
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="attackee"></param>
    /// <param name="hitData"></param>
    void SetOnHitLash(Unit attacker, Unit attackee, ActionCommon.HitData hitData)
    {
        float lashTime = hitData.LashTime;
        if (lashTime <= 0)
            return;
        float lashX = hitData.LashX;
        float lashY = hitData.LashY;
        float lashZ = hitData.LashZ;
        if (lashX == 0 && lashY == 0 && lashZ == 0)
            return;
        //�����ܳ���ǳ���
        Vector3 forward = (attacker.Position - attackee.Position).normalized;
        attackee.UnitTrans.forward = forward;
        attackee.DirectlySetOrientation();
        lashX *= 0.01f;
        lashY *= 0.01f;
        lashZ *= 0.01f;
        lashTime *= 0.001f;
        forward = forward.normalized;
        attackee.ActionStatus.SetExternVelocity(lashX, lashY, lashZ, lashTime, forward);
    }

    /// <summary>
    /// ��ȡ��λ�˺���Ϣ
    /// </summary>
    public DamageInfo GetDamageInfo(Unit attacker,Unit attackee, HitAction hitDefinition, ActionCommon.HitData hitData)
    {
        DamageInfo info = new DamageInfo(attacker, attackee, hitData);
        return info;
    }
}
