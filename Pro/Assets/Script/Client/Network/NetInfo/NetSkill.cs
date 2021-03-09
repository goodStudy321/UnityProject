using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;
using ProtoBuf;
using System;

public class NetSkill
{
    #region 私有方法
    /// <summary>
    /// 获取单位
    /// </summary>
    /// <param name="list"></param>
    private static Unit GetTargetFromList(List<long> list)
    {
        Unit target = null;
        for (int i = 0; i < list.Count; i++)
        {
            target = UnitMgr.instance.FindUnitByUid(list[0]);
            if (target == null)
                continue;
            if (target.Dead)
                continue;
            break;
        }
        return target;
    }
    #endregion
    #region Client --> Server
    /// <summary>
    /// 申请准备开始技能动作
    /// </summary>
    /// <param name="unit">释放单位</param>
    /// <param name="skillId">技能</param>
    /// <param name="actionId">动作ID数字部分</param>
    public static void RequestPrepareSkill(Unit unit, uint skillLvId, int actionId)
    {
        m_fight_prepare_tos fightPrepare = ObjPool.Instance.Get<m_fight_prepare_tos>();
        fightPrepare.skill_id = (int)skillLvId;
        fightPrepare.src_pos = NetMove.GetPointInfo(unit.Position, unit.UnitTrans.localEulerAngles.y);
        fightPrepare.step_id = actionId;
        NetworkClient.Send<m_fight_prepare_tos>(fightPrepare);
    }

    /// <summary>
    /// 请求施放技能
    /// </summary>
    /// <param name="unit">施放单位</param>
    /// <param name="skillId">技能Id</param>
    /// <param name="targetIdList">目标列表</param>
    /// <param name="section">技能伤害段</param>
    public static void RequestPlaySkill(Unit unit, uint skillLvId, List<long> targetIdList, Vector3 skillPos, float eulerAngle)
    {
        m_fight_attack_tos fightAttack = ObjPool.Instance.Get<m_fight_attack_tos>();
        fightAttack.skill_id = (int)skillLvId;
        for (int i = 0; i < targetIdList.Count; i++)
            fightAttack.dest_id_list.Add(targetIdList[i]);
        fightAttack.skill_pos = NetMove.GetPointInfo(skillPos, eulerAngle);
        NetworkClient.Send<m_fight_attack_tos>(fightAttack);
    }
    #endregion

    #region Server --> Client
    /// <summary>
    /// 上线技能推送角色技能,以及技能开放
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponseSkillOnline(object obj)
    {
        m_role_skill_toc roleSkill = obj as m_role_skill_toc;
        List<p_skill> skillInfoList = roleSkill.skill_list;
        bool hasRoleSkill = false;
        List<SkillBelongEnum> list = new List<SkillBelongEnum>();
        for (int i = 0; i < skillInfoList.Count; i++)
        {
            SkillBelongEnum belongEnum = (SkillBelongEnum)(skillInfoList[i].skill_id / 1000000);
            AddSkill(skillInfoList[i], belongEnum);
            if (!list.Contains(belongEnum))
                list.Add(belongEnum);
            if (belongEnum != SkillBelongEnum.RoleSkill)
                continue;
            hasRoleSkill = true;
            AutoPlaySkill.instance.AddSkill((uint)skillInfoList[i].skill_id);
        }
        RefreshPendantSkill(list);
        EventMgr.Trigger(EventKey.SkillUpdate);
        if (!hasRoleSkill)
            return;
        RefreshSkills();
    }

    /// <summary>
    /// 技能更新
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponseSkillUpdate(object obj)
    {
        m_skill_update_toc skillUpdate = obj as m_skill_update_toc;
        //skillUpdate.op_type == 1 角色技能开启推送；0 正常推送（包括角色，宠物，法宝，坐骑，翅膀等）
        for (int i = 0; i < skillUpdate.del_list.Count; i++)
        {
            DelSkill(skillUpdate.del_list[i]);
        }
        bool hasRoleSkill = false;
        List<SkillBelongEnum> list = new List<SkillBelongEnum>();
        for (int i = 0; i < skillUpdate.update_list.Count; i++)
        {
            p_skill skill = skillUpdate.update_list[i];
            SkillBelongEnum belongEnum = (SkillBelongEnum)(skill.skill_id / 1000000);
            AddSkill(skill, belongEnum);
            if (!list.Contains(belongEnum))
                list.Add(belongEnum);
            if (belongEnum != SkillBelongEnum.RoleSkill)
                continue;
            hasRoleSkill = true;
            AutoPlaySkill.instance.AddSkill((uint)skill.skill_id);
        }
        RefreshPendantSkill(list);
        EventMgr.Trigger(EventKey.SkillUpdate);
        if (!hasRoleSkill)
            return;
        RefreshSkills();
    }

    /// <summary>
    /// 技能动作回调
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponsePrepareSkill(object obj)
    {
        m_fight_prepare_toc fightPrepare = obj as m_fight_prepare_toc;
        int skLvId = fightPrepare.skill_id;
        int addTarNum = fightPrepare.add_num;
        //主角被动召唤技能
        if (skLvId >= 9001001 && skLvId < 9100999)
        {
            Unit atker = UnitMgr.instance.FindUnitByUid(fightPrepare.src_id);
            SkillManager.instance.PlayNoActSkill(atker, fightPrepare.dest_id, skLvId, addTarNum);
            return;
        }
        if (User.instance.MapData.UID == fightPrepare.src_id)
            return;
        Unit unit = UnitMgr.instance.FindUnitByUid(fightPrepare.src_id);
        if (!UnitHelper.instance.CanUseUnit(unit))
            return;
        if (PlayPendantSkill(unit, fightPrepare))
            return;
        NetMove.SetPositionFoward(unit, fightPrepare.src_pos, false);
        NetMove.SetMoveSpeed(unit, MoveType.Rush);
        if (unit.ActionStatus == null)
            return;
        Unit target = UnitMgr.instance.FindUnitByUid(fightPrepare.dest_id);
        if (target != null)
            unit.ActionStatus.FTtarget = target;
        string actId = GetActionID(skLvId, fightPrepare.step_id);
        string actionID = "W" + actId;
        if (!unit.ActionStatus.ChangeAction(actionID, 0))
            return;
        unit.mNetUnitMove.SetRotateSpeed(unit);
        unit.ActionStatus.SetSkill((uint)skLvId,addTarNum);
    }

    /// <summary>
    /// 释放技能回调
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponsePlaySkill(object obj)
    {
        m_fight_attack_toc fightAttack = obj as m_fight_attack_toc;
        ProcessSkillHarm(fightAttack);
    }

    /// <summary>
    /// 响应召唤体删除
    /// </summary>
    /// <param name="obj"></param>
    public static void RespSumRemove(object obj)
    {
        m_war_spirit_skill_toc info = obj as m_war_spirit_skill_toc;
        RemoveSmn(info.role_id, info.skill_id);
    }

    /// <summary>
    /// 技能目标改变
    /// </summary>
    /// <param name="obj"></param>
    public static void RespSkillTarAdd(object obj)
    {
        m_skill_target_add_toc info = obj as m_skill_target_add_toc;
        for(int i = 0; i < info.add_list.Count; i++)
        {
            uint skId = (uint)info.add_list[i].id;
            int tarNum = info.add_list[i].val;
            SkillManager.instance.MdfSkTarNum(skId,tarNum);
        }
    }

    /// <summary>
    /// 技能CD缩减
    /// </summary>
    /// <param name="obj"></param>
    public static void RespSkillCDReduce(object obj)
    {
        m_skill_cd_reduce_toc info = obj as m_skill_cd_reduce_toc;
        for (int i = 0; i < info.cd_list.Count; i++)
        {
            uint skId = (uint)info.cd_list[i].id;
            int rdcTime = info.cd_list[i].val;
            SkillManager.instance.MdfSkCD(skId, rdcTime);
        }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 移除召唤体
    /// </summary>
    /// <param name="unitId"></param>
    /// <param name="skLvId"></param>
    private static void RemoveSmn(long unitId,int skLvId)
    {
        Unit unit = UnitMgr.instance.FindUnitByUid(unitId);
        Unit summon = GetSmnUnit(unit, skLvId);
        if (summon == null)
            return;
        summon.Destroy();
    }
    /// <summary>
    /// 检查召唤体技能
    /// </summary>
    private static void CheckSmnSk(Unit atker, long tarId, int skLvId)
    {
        if (skLvId >= 9001001 && skLvId < 9100999)
        {
            Unit summon = GetSmnUnit(atker, skLvId);
            if (summon != null)
                return;
            SkillManager.instance.PlayNoActSkill(atker, tarId, skLvId,0);
            return;
        }
    }

    /// <summary>
    /// 获取召唤体
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="skLvId"></param>
    private static Unit GetSmnUnit(Unit unit, int skLvId)
    {
        if (UnitHelper.instance.UnitIsNull(unit))
            return null;
        uint smnId = UnitHelper.instance.GetSummonTypeId(skLvId);
        Unit summon = unit.Children.Find((Unit u) => { return u.TypeId == smnId; });
        return summon;
    }

    /// <summary>
    /// 获取动作Id
    /// </summary>
    /// <param name="skillLvId"></param>
    /// <param name="step_id"></param>
    /// <returns></returns>
    private static string GetActionID(int skillLvId,int step_id)
    {
        if (step_id >= 10000)
            return step_id.ToString();
        if (step_id == 1)
            return SkillHelper.instance.GetActIDFTbl((uint)skillLvId);
        else if (step_id == 2)
            return "10010";
        else if (step_id == 3)
            return "10020";
        else if (step_id == 4)
            return "10030";
        return step_id.ToString();
    }

    /// <summary>
    /// 释放挂件技能
    /// </summary>
    /// <param name="parent"></param>
    /// <param name="stepId"></param>
    /// <param name="skillID"></param>
    /// <returns></returns>
    private static bool PlayPendantSkill(Unit parent, m_fight_prepare_toc fightPrepare)
    {
        int skLvId = fightPrepare.skill_id;
        int skillID = skLvId / 1000;
        SkillBelongEnum belongEnum = (SkillBelongEnum)(skillID/1000);
        Unit unit = null;
        bool resule = false;
        if(belongEnum == SkillBelongEnum.MagicWeaponSkill)
        {
            unit = parent.MagicWeapon;
            resule = true;
        }
        else if (belongEnum == SkillBelongEnum.MountSkill)
        {
            unit = parent.Mount;
            resule = true;
        }
        else if (belongEnum == SkillBelongEnum.PetSkill)
        {
            unit = parent.Pet;
            resule = true;
        }
        else if (belongEnum == SkillBelongEnum.Wing)
        {
            unit = parent.MagicWeapon;
            resule = true;
        }
        if(resule)
        {
            if (unit == null)
                return true;
            if (unit.ActionStatus == null)
                return true;
            Unit target = UnitMgr.instance.FindUnitByUid(fightPrepare.dest_id);
            if (target != null)
            {
                unit.ActionStatus.FTtarget = target;
                Vector3 forward = UnitHelper.instance.GetForward(unit.Position, target.Position);
                unit.mNetUnitMove.SetMoveFoward(forward);
            }
            else
            {
                Vector3 forward = NetMove.GetForward(fightPrepare.src_pos);
                unit.mNetUnitMove.SetMoveFoward(forward);
            }
            string step = fightPrepare.step_id == 0 ? "10000" : fightPrepare.step_id.ToString();
            string actionID = "W" + step;
            if (!unit.ActionStatus.ChangeAction(actionID, 0))
                return true;
            unit.mNetUnitMove.SetRotateSpeed(unit);
            return true;
        }
        return false;
    }

    /// <summary>
    /// 处理技能伤害
    /// </summary>
    /// <param name="resultList"></param>
    private static void ProcessSkillHarm(m_fight_attack_toc fightAttack)
    {
        if(fightAttack.err_code != 0)
        {
            //iTrace.Error("m_fight_attack_toc Error", fightAttack.err_code.ToString());
            return;
        }
        List<p_result> resultList = fightAttack.effect_list;
        if (resultList == null)
            return;
        Unit attacker = UnitMgr.instance.FindUnitByUid(fightAttack.src_id);
        if (attacker == null)
            return;
        long uid = User.instance.MapData.UID;
        for (int i = 0; i < resultList.Count; i++)
        {
            long tarId = resultList[i].actor_id;
            Unit unit = UnitMgr.instance.FindUnitByUid(tarId);
            if (unit == null)
                continue;
            unit.mLastAttacker = attacker;
            if (unit.DestroyState)
                continue;
            CheckSmnSk(attacker, tarId, fightAttack.skill_id);
            int resultType = resultList[i].result_type;
            long harmValue = resultList[i].value;
            if ((resultType & (byte)HarmType.Cure) != 0)
                unit.HP += harmValue;
            else
                unit.HP -= harmValue;
            bool isOwner = false;
            if (unit.UnitUID == uid)
            {
                User.instance.MapData.Hp = unit.HP;
                isOwner = true;
            }
            User.instance.UpdateMonsterHP(unit.TypeId, unit.HP, unit.MaxHP);
            if (!CanShowSymbol(attacker, unit))
                continue;
            bool isRole = false;
            if (unit.mUnitAttInfo.UnitType == UnitType.Role)
                isRole = true;
            UnitOutLine.SetOutlineSkin(unit);
            OffLineBatMgr.instance.SetOffineBatHp(attacker, unit);
            if (resultList[i].show_value > 0)
                harmValue = resultList[i].show_value;
            if (isOwner)
            {
                PendantHelper.instance.AddPetHitTarget(unit.Pet, attacker);
                UnitMgr.instance.UpdateAtkSelfUnit(attacker);
                BossBatMgr.instance.AddTarget(attacker.UnitUID);
            }
            if ((resultType & (byte)HarmType.Normal) != 0)
            {
                UnitEventMgr.ExecuteChange(unit, harmValue);
                bool relative = IsInCmrLeft(attacker, unit);
                SymbolMgr.Damage(unit, harmValue, isOwner, isRole, relative);
            }
            if ((resultType & (byte)HarmType.Dodge) != 0)
                SymbolMgr.ShanBi(unit);
            if ((resultType & (byte)HarmType.Critical) != 0)
            {
                UnitEventMgr.ExecuteChange(unit, harmValue);
                bool relative = IsInCmrLeft(attacker, unit);
                SymbolMgr.BaoJi(unit, harmValue,relative);
            }
            if ((resultType & (byte)HarmType.Cure) != 0)
                SymbolMgr.RestoreHp(unit, harmValue);
            if ((resultType & (byte)HarmType.Parry) != 0)
                SymbolMgr.GeDang(unit);
            if ((resultType & (byte)HarmType.Absorb) != 0)
                SymbolMgr.Absorb(unit);
            if (isOwner)
                LockTarMgr.instance.CrtLockTopBar(attacker, attacker.Name);
            if (attacker.UnitUID == uid)
                LockTarMgr.instance.CrtLockTopBar(unit, unit.Name);
        }
    }

    /// <summary>
    /// 是否在摄像机的左边
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    private static bool IsInCmrLeft(Unit atker, Unit atkee)
    {
        if (atker == null)
            return false;
        if (atkee == null)
            return false;
        Vector3 pos = Vector3.zero;
        long ownerID = User.instance.MapData.UID;
        if (atker.UnitUID == ownerID)
            pos = atkee.Position;
        else if (atkee.UnitUID == ownerID)
            pos = atker.Position;
        Vector3 cPos = CameraMgr.Main.WorldToScreenPoint(pos);
        cPos.z = 0;
        Vector3 scrPos = UICamera.mainCamera.ScreenToWorldPoint(cPos);
        if (scrPos.x < 0)
            return true;
        return false;
    }

    /// <summary>
    /// 是否可以显示伤害符号
    /// </summary>
    /// <param name="atker"></param>
    /// <param name="atkee"></param>
    /// <returns></returns>
    private static bool CanShowSymbol(Unit atker,Unit atkee)
    {
        SceneSubType ssType = GameSceneManager.instance.MapSubType;
        if (ssType == SceneSubType.ImmotalSoul)
            return true;
        long uid = User.instance.MapData.UID;
        if (atker.UnitUID != uid && atkee.UnitUID != uid)
        {
            Unit parent = atker.ParentUnit;
            if (parent != null && parent.UnitUID == uid)
                return true;
            return false;
        }
        return true;
    }

    /// <summary>
    /// 处理受击特效和声音
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="attackee"></param>
    /// <param name="position"></param>
    /// <param name="section"></param>
    private static void ProcessHitedEffectAndSound(Unit attacker, Unit attackee, Vector3 position, uint skillId, int section)
    {
        if (attacker == null)
            return;
        if (attacker.ActionStatus == null)
            return;
        if (attacker.ActionStatus.ActionGroupData == null)
            return;
        string animName = ActionHelper.GetInterruptAnimIDBySkillID(attacker, skillId);
        ActionData actionData = ActionHelper.GetActionByID(attacker.ActionStatus.ActionGroupData, animName);
        if (actionData == null)
        {
            iTrace.Error("ActionId", " ActionID is null!");
            return;
        }
        AttackDefData attackDefData = ActionHelper.GetAttackDefDataByIndex(actionData, section - 1);
        attackee.mUnitEffects.CreateOnHitEffectAndSoundEvent(attacker, attackee, attackDefData, attackee.Position);
    }

    /// <summary>
    /// 删除技能
    /// </summary>
    /// <param name="skillLvID"></param>
    private static void DelSkill(int skillLvID)
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        ActorData actData = User.instance.MapData;
        List<p_skill> skInfoList = null;
        uint skId = (uint)skillLvID;
        Unit objUnit = null;
        SkillBelongEnum belongEnum = (SkillBelongEnum)(skillLvID/1000000);
        if (belongEnum == SkillBelongEnum.RoleSkill)
        {
            objUnit = unit;
            skInfoList = actData.SkillInfoList;
            AutoPlaySkill.instance.RemoveSkill(skId);
        }
        else if (belongEnum == SkillBelongEnum.PetSkill)
        {
            Unit pet = unit.Pet;
            if (pet == null)
                return;
            objUnit = pet;
            skInfoList = actData.PetSkillInfoList;
        }
        else if (belongEnum == SkillBelongEnum.MountSkill)
        {
            Unit mount = unit.Mount;
            if (mount == null)
                return;
            objUnit = mount;
            skInfoList = actData.MountSkillInfoList;
        }
        else if (belongEnum == SkillBelongEnum.MagicWeaponSkill)
        {
            Unit magicWeapon = unit.MagicWeapon;
            if (magicWeapon == null)
                return;
            objUnit = magicWeapon;
            skInfoList = actData.MgwpSkillInfoList;
        }
        else if (belongEnum == SkillBelongEnum.Wing)
        {
            Unit wing = unit.Wing;
            if (wing == null)
                return;
            objUnit = wing;
            skInfoList = actData.WingSkillInfoList;
        }
        else if (belongEnum == SkillBelongEnum.Fashion)
        {
            skInfoList = actData.FashionSkillInfoList;
            p_skill fskill = skInfoList.Find((sk) => { return sk.skill_id == skillLvID; });
            if (fskill != null) skInfoList.Remove(fskill);
        }
        if (skInfoList == null || objUnit == null) return;
        SkillManager.instance.RemoveSkill(objUnit, skId);
        p_skill skill = skInfoList.Find((sk) => { return sk.skill_id == skillLvID; });
        if (skill != null) skInfoList.Remove(skill);
    }
    public static void Check()
    {

    }
    /// <summary>
    /// 添加技能
    /// </summary>
    /// <param name="skill"></param>
    private static void AddSkill(p_skill skill,SkillBelongEnum belongEnum)
    {
        p_skill pSkill = new p_skill();
        pSkill.skill_id = skill.skill_id;
        pSkill.time = skill.time;
        pSkill.seal_id = skill.seal_id;
        ActorData actData = User.instance.MapData;
        if (belongEnum == SkillBelongEnum.RoleSkill)
        {
        for (int i = 0; i < skill.seal_id_list.Count; i++)
        {
            int id = skill.seal_id_list[i];
            pSkill.seal_id_list.Add (id);
        }
            List<p_skill> SkillInfoList = actData.SkillInfoList;
            bool isb = true;
            for (int i = 0; i < SkillInfoList.Count; i++)
            {
                if (SkillInfoList[i].skill_id == pSkill.skill_id)
                {
                    SkillInfoList[i] = pSkill;
                    isb = false;
                    break;
                }
            }
            if (isb)
            {
                actData.SkillInfoList.Add(pSkill);
            }
        }
        else if (belongEnum == SkillBelongEnum.PetSkill)
        {
            actData.PetSkillInfoList.Add(pSkill);
        }
        else if (belongEnum == SkillBelongEnum.MountSkill)
        {
            actData.MountSkillInfoList.Add(pSkill);
        }
        else if (belongEnum == SkillBelongEnum.MagicWeaponSkill)
        {
            actData.MgwpSkillInfoList.Add(pSkill);
        }
        else if (belongEnum == SkillBelongEnum.Wing)
        {
            actData.WingSkillInfoList.Add(pSkill);
        }
        else if (belongEnum == SkillBelongEnum.Fashion)
        {
            actData.FashionSkillInfoList.Add(pSkill);
        }
    }

    /// <summary>
    /// 刷新挂件技能
    /// </summary>
    /// <param name="list"></param>
    private static void RefreshPendantSkill(List<SkillBelongEnum> list)
    {
        int count = list.Count;
        if (count == 0)
            return;
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        ActorData actorData = User.instance.MapData;
        for (int i = 0; i < count; i++)
        {
            if(list[i] == SkillBelongEnum.MagicWeaponSkill)
            {
                if (unit.MagicWeapon == null)
                    continue;
                if (unit.MagicWeapon.mPendant == null)
                    continue;
                unit.MagicWeapon.mPendant.AddSkills(actorData.MgwpSkillInfoList);
            }
            if (list[i] == SkillBelongEnum.MountSkill)
            {
                if (unit.Mount == null)
                    continue;
                if (unit.Mount.mPendant == null)
                    continue;
                unit.Mount.mPendant.AddSkills(actorData.MountSkillInfoList);
            }
            if (list[i] == SkillBelongEnum.PetSkill)
            {
                if (unit.Pet == null)
                    continue;
                if (unit.Pet.mPendant == null)
                    continue;
                unit.Pet.mPendant.AddSkills(actorData.PetSkillInfoList);
            }
            if (list[i] == SkillBelongEnum.Wing)
            {
                if (unit.Wing == null)
                    continue;
                if (unit.Wing.mPendant == null)
                    continue;
                unit.Wing.mPendant.AddSkills(actorData.WingSkillInfoList);
            }
        }
    }

    /// <summary>
    /// 刷新技能
    /// </summary>
    private static void RefreshSkills()
    {
        UISkill.instance.InitSkillData();
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        SkillManager.instance.InitSkill(unit);
    }
#endregion
}
