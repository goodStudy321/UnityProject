using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using LuaInterface;
using Loong.Game;

public class UISkill : IDisposable
{
    public static readonly UISkill instance = new UISkill();

    private UISkill()
    {

    }
    #region 私有变量
    /// <summary>
    /// 玩家
    /// </summary>
    private Unit mOwner = null;
    
    /// <summary>
    /// 技能信息字典
    /// </summary>
    private Dictionary<PreSkillEnum, UISkillInfo> mUISkillInfoDic = new Dictionary<PreSkillEnum, global::UISkillInfo>();
    
    private LuaTable mLuaTable = null;

    private LuaFunction mSetSkillIconFuc = null;
    #endregion

    #region 属性
    /// <summary>
    /// 玩家
    /// </summary>
    public Unit Owner
    {
        get { return mOwner; }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 打开面板回调
    /// </summary>
    /// <param name="uiName"></param>
    private void OpenCallback(string uiName)
    {
        InitSkillData();
    }

    public void InitSkillData()
    {
        RefreshSkill();
        SetSkillIcon();
    }

    /// <summary>
    /// 设置技能图标
    /// </summary>
    private void SetSkillIcon()
    {
        if (mLuaTable == null)
            mLuaTable = LuaTool.GetTable(LuaMgr.Lua, UIName.UISkill);
        string[] iconNames = new string[9];
        List<Phantom.Protocal.p_skill> list = User.instance.MapData.SkillInfoList;
        if (list == null) return;
        for(int i = 0; i < list.Count; i ++)
        {
            SkillLevelAttr attr = SkillLevelAttrManager.instance.Find((uint)(list[i].skill_id));
            if (attr == null) continue;
            SkillBase skill = SkillBaseManager.instance.Find(attr.baseid);
            if (skill == null) continue;
            if ((SkillEnum)attr.type != SkillEnum.Active) continue;
            int nameIndex = attr.skillUiIndex - 1;
            iconNames[nameIndex] = skill.pathicon;
        }
        if(mSetSkillIconFuc == null)
            mSetSkillIconFuc = LuaTool.GetFunc(mLuaTable, "SetSkillIcon");
        if (mSetSkillIconFuc == null)
            return;
        LuaTool.Call( mSetSkillIconFuc, mLuaTable, iconNames[1], iconNames[2], iconNames[3],iconNames[4], iconNames[5]);
    }

    /// <summary>
    /// 施放技能
    /// </summary>
    private void PlaySkill(PreSkillEnum preSkillEnum, GameObject go)
    {
        if (!UnitHelper.instance.PreConCanPass(Owner))
            return;
        CheckAndPlay(preSkillEnum, go);
    }

    /// <summary>
    /// 检测并施放技能
    /// </summary>
    private void CheckAndPlay(PreSkillEnum preSkillEnum, GameObject go)
    {
        if (!mUISkillInfoDic.ContainsKey(preSkillEnum))
            return;
        GameSkill skill = mUISkillInfoDic[preSkillEnum].skill;
        if (skill == null)
            return;
        HangupMgr.instance.ClearAutoInfo();
        User.instance.ResetMisTarID();
        SelectRoleMgr.instance.ResetTRUId();
        string actionID = SkillHelper.instance.GetItrptActID(mOwner, skill);
        if (string.IsNullOrEmpty(actionID))
            return;
        if (skill.isCding)
            return;
        float distance = skill.SkillLevelAttrTable.maxDistance * 0.01f;
        Unit target = FightModMgr.instance.GetTarget(mOwner, distance);
        if(target == null)
        {
            if (ActionHelper.IsPTPAttDefType(mOwner, actionID))
            {
                UITip.LocalLog(690015);
                return;
            }
        }
        string effectName = string.Empty;
        if (preSkillEnum != PreSkillEnum.NormalAttack)
        {
            if (!UnitHelper.instance.CanPlaySkillAttack(mOwner))
                return;
            effectName = "UI_Skill_Clik1";
            PlayAndSendSkill(mOwner, target, actionID, skill);
        }
        else
        {
            if (!UnitHelper.instance.CanPlayNormalAttack(mOwner))
                return;
            effectName = "UI_Skill_Clik2";
            if (target == null)
                PlayAndSendSkill(mOwner, target, actionID, skill);
            else
            {
                float skillDis = skill.SkillLevelAttrTable.maxDistance * 0.01f;
                bool inDistance = SkillHelper.instance.IsInDistance(mOwner, target, skillDis);
                if (inDistance)
                    PlayAndSendSkill(mOwner, target, actionID, skill);
                else
                    UnitAttackCtrl.instance.BeginAttackCtrl(mOwner, target, skill, actionID, false);
            }
        }
        ShowPressEffect(effectName, go);
    }

    /// <summary>
    /// 显示点击技能特效
    /// </summary>
    /// <param name="effectName"></param>
    /// <param name="go"></param>
    private void ShowPressEffect(string effectName, GameObject go)
    {
        if (string.IsNullOrEmpty(effectName))
            return;
        if (go == null)
            return;
        AssetMgr.LoadPrefab(effectName, (effect) =>
        {
            Transform trans = effect.transform;
            trans.parent = go.transform;
            trans.localPosition = Vector3.zero;
            trans.localScale = Vector3.one;
            effect.SetActive(true);
        });
    }

    /// <summary>
    /// 设置Cd图片
    /// </summary>
    /// <param name="go"></param>
    private void SetCdSprite(PreSkillEnum preSkillEnum, GameObject go)
    {
        if (go == null)
            return;
        if (!mUISkillInfoDic.ContainsKey(preSkillEnum))
            return;
        UISprite cdSprite = mUISkillInfoDic[preSkillEnum].cdSprite;
        if (cdSprite != null)
            return;
        Transform cd = go.transform.Find("CD");
        if (cd == null)
            return;
        UISprite uiSprite = cd.GetComponent<UISprite>();
        if (uiSprite == null)
            return;
        mUISkillInfoDic[preSkillEnum].cdSprite = uiSprite;
    }

    /// <summary>
    /// 设置技能
    /// </summary>
    /// <param name="skill"></param>
    private void SetSkill(GameSkill skill)
    {
        PreSkillEnum skillEnum = (PreSkillEnum)skill.SkillLevelAttrTable.skillUiIndex;
        if (!mUISkillInfoDic.ContainsKey(skillEnum))
            return;
        mUISkillInfoDic[skillEnum].skill = skill;
    }

    /// <summary>
    /// 显示技能CD完成
    /// </summary>
    /// <param name="go"></param>
    private void ShowCDDoneEffect(GameObject go)
    {
        if (go.transform.parent == null)
            return;
        string effectName = "UI_Skill_ColdDown";
        AssetMgr.LoadPrefab(effectName, (effect) =>
        {
            Transform trans = effect.transform;
            trans.parent = go.transform.parent;
            trans.localPosition = Vector3.zero;
            trans.localScale = Vector3.one;
            effect.SetActive(true);
        });
    }

    /// <summary>
    /// 初始化技能信息字典
    /// </summary>
    private void InitSkillInfoDic()
    {
        mUISkillInfoDic.Clear();
        for(int i = 1; i < 10; i++)
        {
            PreSkillEnum preSkillEnum = (PreSkillEnum)i;
            UISkillInfo uiSkillInfo = new UISkillInfo();
            mUISkillInfoDic.Add(preSkillEnum, uiSkillInfo);
        }
    }

    /// <summary>
    /// 增加事件
    /// </summary>
    private void AddEventKey()
    {
        EventMgr.Add(EventKey.Skill_1OnClick, Skill_1OnClick);
        EventMgr.Add(EventKey.Skill_2OnClick, Skill_2OnClick);
        EventMgr.Add(EventKey.Skill_3OnClick, Skill_3OnClick);
        EventMgr.Add(EventKey.Skill_4OnClick, Skill_4OnClick);
        EventMgr.Add(EventKey.Skill_5OnClick, Skill_5OnClick);
        EventMgr.Add(EventKey.SkillAttackOnClick, SkillAttackOnClick);
        EventMgr.Add(EventKey.SkillInit, SkillInit);
    }
    #endregion

    #region 共有方法

    /// <summary>
    /// 初始化
    /// </summary>
    public void Initialize()
    {
        InitSkillInfoDic();
        AddEventKey();
    }

    /// <summary>
    /// 初始化
    /// </summary>
    public void InitUnit(Unit unit)
    {
        mOwner = unit;
    }

    /// <summary>
    /// 播放并发送技能
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="actionID"></param>
    /// <param name="skill"></param>
    public void PlayAndSendSkill(Unit unit, Unit target, string actionID, GameSkill skill)
    {
        User.instance.MissionState = false;
        mOwner.mUnitMove.StopNav(false);
        UnitAttackCtrl.instance.Clear();
        UnitWildRush.instance.Clear();
        HgupPoint.instance.Clear();
        UnitHelper.instance.ResetUnitData(unit);
        PendantMgr.instance.TakeOffMount(unit);
        SetForward(unit, target);
        SkillHelper.instance.SetLockTarget(unit, target);
        if (!unit.ActionStatus.ChangeAction(actionID, 0))
            return;
        unit.ActionStatus.SetSkill(skill.SkillLevelID,skill.AddTarNum);
        if (Global.Mode == PlayMode.Local)
            return;
        if(unit.ActionStatus.ActiveAction != null && 
            unit.ActionStatus.ActiveAction.MoveSpeed > 0)
        {
            float angle = unit.UnitTrans.localEulerAngles.y;
            long point = NetMove.GetPointInfo(unit.Position, angle);
            NetMove.RequestStopMove(point);
        }
        int actionId = int.Parse(actionID.Remove(0, 1));
        NetSkill.RequestPrepareSkill(unit, skill.SkillLevelID, actionId);
    }
    
    /// <summary>
    /// 设置方向
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    public void SetForward(Unit attacker,Unit target)
    {
        if (target == null)
            return;
        Vector3 forward = target.Position - attacker.Position;
        attacker.SetOrientation(Mathf.Atan2(forward.x, forward.z));
    }

    /// <summary>
    /// 调用开启技能面板入口
    /// </summary>
    public void Open()
    {
        UIMgr.Open(UIName.UISkill, OpenCallback);
    }

    /// <summary>
    /// 关闭技能面板
    /// </summary>
    public void Close()
    {
        UIMgr.Close(UIName.UISkill);
    }

    /// <summary>
    /// 技能初始化
    /// </summary>
    public void SkillInit(params object[] args)
    {
        EventMgr.Remove(EventKey.SkillInit, SkillInit);
        for (int i = 0; i < 6; i++)
        {
            GameObject go = args[i] as GameObject;
            PreSkillEnum preSkillEnum = (PreSkillEnum)(i + 1);
            SetCdSprite(preSkillEnum, go);
        }
    }

    /// <summary>
    /// 技能1
    /// </summary>
    public void Skill_1OnClick(params object[] args)
    {
        GameObject go = args[0] as GameObject;
        PlaySkill(PreSkillEnum.Skill_1, go);
    }

    /// <summary>
    /// 技能2
    /// </summary>
    public void Skill_2OnClick(params object[] args)
    {
        GameObject go = args[0] as GameObject;
        PlaySkill(PreSkillEnum.Skill_2, go);
    }

    /// <summary>
    /// 技能3
    /// </summary>
    public void Skill_3OnClick(params object[] args)
    {
        GameObject go = args[0] as GameObject;
        PlaySkill(PreSkillEnum.Skill_3, go);
    }

    /// <summary>
    /// 技能4
    /// </summary>
    public void Skill_4OnClick(params object[] args)
    {
        GameObject go = args[0] as GameObject;
        PlaySkill(PreSkillEnum.Skill_4, go);
    }

    /// <summary>
    /// 技能5
    /// </summary>
    public void Skill_5OnClick(params object[] args)
    {
        GameObject go = args[0] as GameObject;
        PlaySkill(PreSkillEnum.Skill_5, go);
    }

    /// <summary>
    /// 普通攻击
    /// </summary>
    public void SkillAttackOnClick(params object[] args)
    {
        GameObject go = args[0] as GameObject;
        PlaySkill(PreSkillEnum.NormalAttack, go);
    }
    
    /// <summary>
    /// 刷新技能
    /// </summary>
    public void RefreshSkill()
    {
        if (mOwner == null)
            return;
        for (int i = 0; i < mOwner.mUnitSkill.Skills.Count; i++)
        {
            GameSkill skill = mOwner.mUnitSkill.Skills[i];
            SetSkills(skill);
        }
    }

    /// <summary>
    /// 添加技能
    /// </summary>
    /// <param name="skill"></param>
    public void SetSkills(GameSkill skill)
    {
        SkillLevelAttr skillLevAttr = skill.SkillLevelAttrTable;
        if (skillLevAttr == null)
            return;
        int skillType = skillLevAttr.type;
        if (skillType == (int)SkillEnum.passtive)
            return;
        SetSkill(skill);
    }
    
    /// <summary>
    /// UICD更新
    /// </summary>
    public void Update()
    {
        foreach(KeyValuePair<PreSkillEnum, UISkillInfo> item in mUISkillInfoDic)
        {
            PreSkillEnum skEnum = item.Key;
            if (skEnum == PreSkillEnum.NormalAttack)
            {
                UpdateUICD(item.Value);
                continue;
            }
            if (skEnum > PreSkillEnum.Skill_5)
                continue;
            UpdateUICD(item.Value);
        }
    }

    private void UpdateUICD(UISkillInfo info)
    {
        GameSkill skill = info.skill;
        UISprite cdSprite = info.cdSprite;
        if (skill == null)
            return;
        if (cdSprite == null)
            return;
        if (!skill.isCding && cdSprite.fillAmount != 0)
        {
            cdSprite.fillAmount = 0;
            ShowCDDoneEffect(cdSprite.gameObject);
            info.isShowCDDoneEffect = true;
        }
        if (!skill.isCding)
            return;
        cdSprite.fillAmount = skill.cdPercent;
        info.isShowCDDoneEffect = false;
    }

    public void Clear()
    {
        foreach (KeyValuePair<PreSkillEnum, UISkillInfo> item in mUISkillInfoDic)
        {
            UISprite cdSprite = item.Value.cdSprite;
            if (cdSprite != null)
                cdSprite.fillAmount = 1;
            item.Value.skill = null;
            item.Value.isShowCDDoneEffect = false;
        }
    }

    public void Dispose()
    {
        if (mOwner != null)
            mOwner = null;
        if(mLuaTable != null)
        {
            mLuaTable.Dispose();
            mLuaTable = null;
        }
        if(mSetSkillIconFuc != null)
        {
            mSetSkillIconFuc.Dispose();
            mSetSkillIconFuc = null;
        }
        Clear();
    }
    #endregion
}

/// <summary>
/// UI技能信息
/// </summary>
public class UISkillInfo
{
    public GameSkill skill { get; set; }
    public UISprite cdSprite { get; set; }
    public bool isShowCDDoneEffect { get; set; }
}
