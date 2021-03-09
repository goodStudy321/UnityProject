using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;

public class ActorData
{
    #region 唯一ID
    private Int64 mUID;
    /// <summary>
    /// 唯一ID
    /// </summary>
    public Int64 UID
    {
        set
        {
            mUID = value;
        }
        get
        {
            return mUID;
        }
    }

    public string UIDStr
    {
        get { return mUID.ToString(); }
        set { mUID = Convert.ToInt64(value); }
    }
    #endregion

    #region 职业
    private Int32 mCategory;
    /// <summary>
    /// 职业
    /// </summary>
    public Int32 Category
    {
        set { mCategory = value; }
        get { return mCategory; }
    }
    #endregion

    #region 性别
    private Int32 mSex;
    /// <summary>
    /// 性别 0为女性，1为男性
    /// </summary>
    public Int32 Sex { set { mSex = value; } get { return mSex; } }
    #endregion

    #region 等级
    /// <summary>
    /// 需要同步更新其他数据 赋值用Level
    /// </summary>
    private Int32 mLevel = 0;
    /// <summary>
    /// 等级
    /// </summary>
    public Int32 Level
    {
        get
        {
            return mLevel;
        }
        set
        {
            if(!User.instance.IsInitLoadScene && mLevel < value)
            {
                if(mLevel > 0 && UID == User.instance.MapData.UID) UnitUpLvEffect.Start();
                mLevel = value;
                AddExp = LimitExp - Exp;
                UpdateLimitLevel();
                if (User.instance.MapData != null && UID != User.instance.MapData.UID) return;
                EventMgr.Trigger(EventKey.OnChangeLv, mLevel);
#if UNITY_EDITOR
                ShowInConsole();
#endif
                return;
            }
            AddExp = 0;
            mLevel = value;
            UpdateLimitLevel();
        }
    }

    #endregion

    #region 角色类型ID
    /// <summary>
    /// 角色类型ID
    /// </summary>
    public uint UnitTypeId
    {
        get { return (UInt32)((Category * 10 + Sex) * 1000 + Level); }
    }
    #endregion

    #region 单位外观
    private PendantStateEnum pdState;
    /// <summary>
    /// 挂件状态
    /// </summary>
    public PendantStateEnum PdState
    {
        get { return pdState; }
    }

    
    private List<int> mSkinList = new List<int>();
    /// <summary>
    /// 外观挂件列表
    /// </summary>
    public List<int> SkinList
    {
        get { return mSkinList; }
        set { mSkinList = value; }
    }

    private List<int> mOrnamentList = new List<int>();
    /// <summary>
    /// 外观配饰列表
    /// </summary>
    public List<int> OrnamentList
    {
        get { return mOrnamentList; }
        set { mOrnamentList = value; }
    }
    #endregion

    #region 守护信息 是否可以自动拾取
    private bool isAutoPick;
    public bool IsAutoPick
    {
        get
        {
            return isAutoPick;
        }
        set
        {
            isAutoPick = value;
        }
    }
    #endregion

    #region 名字
    private string mName;
    /// <summary>
    /// 名字
    /// </summary>
    public string Name
    {
        set { mName = value; }
        get { return mName; }
    }
    #endregion

    #region 服务器名

    protected int mServerID;
    /// <summary>
    /// 服务器ID
    /// </summary>
    public int ServerID
    {
        get { return mServerID; }
        set { mServerID = value; }
    }

    private string mServerName;
    /// <summary>
    /// 服务器名
    /// </summary>
    public string ServerName
    {
        set { mServerName = value; }
        get { return mServerName; }
    }
    #endregion

    #region 仙侣
    private long mMarryID;
    /// <summary>
    /// 服务器名
    /// </summary>
    public long MarryID
    {
        set { mMarryID = value; }
        get { return mMarryID; }
    }
    private string mMarryName;
    /// <summary>
    /// 服务器名
    /// </summary>
    public string MarryName
    {
        set { mMarryName = value; }
        get { return mMarryName; }
    }

    #endregion

    #region 经验
    /// <summary>
    /// 需要同步更新其他数据 赋值用Exp
    /// </summary>
    private Int64 mExp;
    private Int64 mLimitExp = 1;
    /// <summary>
    /// 经验
    /// </summary>
    public Int64 Exp
    {
        get
        {
            return mExp;
        }
    }

    public string ExpStr
    {
        get
        {
            return mExp.ToString();
        }
    }

    private Int32 mReliveLv;
    /// <summary>
    /// 转生等级
    /// </summary>
    public Int32 ReliveLV
    {
        get { return mReliveLv; }
        set
        {
            mReliveLv = value;
        }
    }

    private Int32 mLstCreateTime;
    /// <summary>
    /// 上次创建时间
    /// </summary>
    public Int32 LstCreateTime
    {
        get { return mLstCreateTime; }
        set { mLstCreateTime = value; }
    }

    private Int32 mLstLevUpTime;
    /// <summary>
    /// 上次上级时间
    /// </summary>
    public Int32 LstLevUpTime
    {
        get { return mLstLevUpTime; }
        set { mLstLevUpTime = value; }
    }

    private Int32 mOfflFTime;
    /// <summary>
    /// 离线战斗时间
    /// </summary>
    public Int32 OfflFTime
    {
        get { return mOfflFTime; }
        set { mOfflFTime = value;
            EventMgr.Trigger(EventKey.OfflFTimeChange);
        }
    }

    /// <summary>
    /// 升级经验 当前等级经验上限
    /// </summary>
    public Int64 LimitExp
    {
        get
        {
            return mLimitExp;
        }
        set
        {
            mLimitExp = value;
        }
    }


    private string tag;
    /// <summary>
    /// 角色model tag
    /// </summary>
    public string Tag
    {
        get { return tag; }
        set
        {
            tag = value;
            SetModelTag();
        }
    }

    /// <summary>
    /// 当前经验比率
    /// </summary>
    public float ExpRatio { get { return mExp / (float)mLimitExp; } }

    private Int64 AddExp = 0;
    #endregion

    #region 属性
    /// <summary>
    /// 基础属性
    /// </summary>
    public Dictionary<Int32, Int64> BaseProperty = new Dictionary<Int32, Int64>();
    /// <summary>
    /// ulong 属性
    /// </summary>
    public Dictionary<Int64, Int64> ValueProperty = new Dictionary<Int64, Int64>();
    /// <summary>
    /// string 属性
    /// </summary>
    public Dictionary<Int64, string> StringProperty = new Dictionary<Int64, string>();
    /// <summary>
    /// 个人ulong 属性
    /// </summary>
    public Dictionary<PersonalProType, Int64> ValPsnPro = new Dictionary<PersonalProType, Int64>();
    /// <summary>
    /// 个人string 属性
    /// </summary>
    public Dictionary<PersonalProType, string> StrPsnPro = new Dictionary<PersonalProType, string>();
    /// <summary>
    /// 战斗力
    /// </summary>
    public Dictionary<FightValEnum, Int32> FightValueDic = new Dictionary<FightValEnum, int>();
    #endregion

    #region 对象类型
    private Int32 mType;
    /// <summary>
    /// 对象类型
    /// </summary>
    public Int32 Type
    {
        set { mType = value; }
        get
        {
            return mType;
        }
    }
    #endregion

    #region 状态
    private Int32 mStatus;
    /// <summary>
    /// 状态，0为正常，1为死亡
    /// </summary>
    public Int32 Status
    {
        set
        {
            mStatus = value;
        }
        get
        {
            return mStatus;
        }
    }
    #endregion

    #region buff显示状态
    private Int32 mShowBuffStatus;
    /// <summary>
    /// buff显示状态
    /// </summary>
    public Int32 ShowBuffStatus
    {
        set { mShowBuffStatus = value; }
        get { return mShowBuffStatus; }
    }
    #endregion

    #region 移动速度
    private float mMoveSpeed;
    /// <summary>
    /// 移动速度
    /// </summary>
    public float MoveSpeed
    {
        set { mMoveSpeed = value; }
        get { return mMoveSpeed; }
    }
    #endregion

    #region 坐标位置
    private Int64 mPos;
    /// <summary>
    /// 坐标位置
    /// </summary>
    public Int64 Pos
    {
        set
        {
            mPos = value;
            SetPosition();
            isInitPos = true;

        }
        get { return mPos; }
    }

    private bool isInitPos = false;
    /// <summary>
    /// 是否已经初始化位置
    /// </summary>
    public bool HasInitPos
    {
        get { return isInitPos; }
        set { isInitPos = value; }
    }


    private void SetModelTag()
    {
        Unit owner = InputMgr.instance.mOwner;
        if (owner == null)
            return;
        if (owner.UnitUID != UID)
            return;
        owner.UnitTrans.tag = tag;
    }

    /// <summary>
    /// 设置位置
    /// </summary>
    private void SetPosition()
    {
        Unit owner = InputMgr.instance.mOwner;
        if ( owner == null)
            return;
        if (owner.UnitUID != UID)
            return;
        Unit moveUnit = InputVectorMove.instance.MoveUnit;
        moveUnit.Position = NetMove.GetPositon(mPos);
        PendantMgr.instance.SetLocalPendantsShowState(owner, true, OpStateType.ChangeScene);
    }

    public Vector3 RealPos
    {
        get
        {
            if (InputVectorMove.instance.MoveUnit.UnitUID == UID)
            {
                if (InputVectorMove.instance.MoveUnit != null && InputVectorMove.instance.MoveUnit.UnitTrans != null)
                    return InputVectorMove.instance.MoveUnit.Position;
            }
            return Vector3.zero;
        }
    }
    #endregion

    #region 目标位置
    private Int64 mTargetPos;
    /// <summary>
    /// 目标位置
    /// </summary>
    public Int64 TargetPos
    {
        set { mTargetPos = value; }
        get { return mTargetPos; }
    }
    #endregion

    #region 血量HP
    /// <summary>
    /// 要同步更新其他数据 赋值用Hp
    /// </summary>
    private long mHp = 100000;
    private long mMaxHp = 100000;
    public string HpStr = "100000";
    public string MaxHpStr = "100000";
    /// <summary>
    /// 当前血量
    /// </summary>
    public long Hp
    {
        get
        {
            if (mHp < 0) mHp = 0;
            return mHp;
        }
        set
        {
            bool chg = mHp != value ? true : false;
            mHp = value;
            HpStr = mHp.ToString();
            if (chg)
                EventMgr.Trigger(EventKey.OnChangeHP);
        }
    }
    /// <summary>
    /// 最大血量
    /// </summary>
    public long MaxHp
    {
        get
        {
            return mMaxHp;
        }
        set
        {
            mMaxHp = value;
            MaxHpStr = mMaxHp.ToString();
        }
    }
    /// <summary>
    /// 当前血量比率
    /// </summary>
    public float HPRation
    {
        get
        {
            return mHp / (float)mMaxHp;
        }
    }
    #endregion

    #region 阵营
    private Int32 mCamp;
    public Int32 Camp
    {
        set { mCamp = value; }
        get { return mCamp; }
    }
    #endregion

    #region 技能列表
    /// <summary>
    /// 角色技能
    /// </summary>
    private List<p_skill> skillInfoList = new List<p_skill>();
    public List<p_skill> SkillInfoList
    {
        get { return skillInfoList; }
        set { skillInfoList = value; }
    }

    /// <summary>
    /// 宠物技能
    /// </summary>
    private List<p_skill> petSkillInfoList = new List<p_skill>();
    public List<p_skill> PetSkillInfoList
    {
        get { return petSkillInfoList; }
        set { petSkillInfoList = value; }
    }

    /// <summary>
    /// 坐骑技能
    /// </summary>
    private List<p_skill> mountSkillInfoList = new List<p_skill>();
    public List<p_skill> MountSkillInfoList
    {
        get { return mountSkillInfoList; }
        set { mountSkillInfoList = value; }
    }

    /// <summary>
    /// 法宝技能
    /// </summary>
    private List<p_skill> mgwpSkillInfoList = new List<p_skill>();
    public List<p_skill> MgwpSkillInfoList
    {
        get { return mgwpSkillInfoList; }
        set { mgwpSkillInfoList = value; }
    }

    /// <summary>
    /// 翅膀技能
    /// </summary>
    private List<p_skill> wingSkillInfoList = new List<p_skill>();
    public List<p_skill> WingSkillInfoList
    {
        get { return wingSkillInfoList; }
        set { wingSkillInfoList = value; }
    }
    /// <summary>
    /// 时装技能
    /// </summary>
    private List<p_skill> fashionSkillInfoList = new List<p_skill>();
    public List<p_skill> FashionSkillInfoList
    {
        get { return fashionSkillInfoList; }
        set { fashionSkillInfoList = value; }
    }
    #endregion

    #region 当前场景战斗模式
    protected FightType mFightType;
    /// <summary>
    /// 战斗类型
    /// </summary>
    public int FightType
    {
        get { return (int)mFightType; }
        set { mFightType = (FightType)value; }
    }

    protected float mPkValueTime;
    /// <summary>
    /// pk值时间
    /// </summary>
    public float PkValueTime
    {
        get { return mPkValueTime; }
        set { mPkValueTime = value; }
    }

    protected float mPkValue;
    /// <summary>
    /// pk值
    /// </summary>
    public float PkValue
    {
        get { return mPkValue; }
        set { mPkValue = value; }
    }
    #endregion

    #region 帮派
    protected long mFamilyId;
    /// <summary>
    /// 帮派ID
    /// </summary>
    public long FamilyID
    {
        get { return mFamilyId; }
        set { mFamilyId = value; }
    }

    protected string mFamilyName;
    /// <summary>
    /// 帮派名
    /// </summary>
    public string FamlilyName
    {
        get { return mFamilyName; }
        set { mFamilyName = value; }
    }

    protected int mFamilyTitle; 
    /// <summary>
    /// 道庭职位
    /// </summary>
    public int FamilyTitle
    {
        get { return mFamilyTitle; }
        set { mFamilyTitle = value; }
    }
    #endregion

    #region 队伍ID
    protected int mTeamId;
    /// <summary>
    /// 队伍ID
    /// </summary>
    public int TeamID
    {
        get { return mTeamId; }
        set { mTeamId = value; }
    }
    #endregion

    protected int mFightVal;
    /// <summary>
    /// 总战斗力
    /// </summary>
    public int AllFightValue
    {
        get { return mFightVal; }
        set
        {
            mFightVal = value;
            EventMgr.Trigger(EventKey.OnChangeFight);
        }
    }

    private int mConfine;
    /// <summary>
    /// 境界
    /// </summary>
    public int Confine
    {
        get { return mConfine; }
        set
        {
            mConfine = value;
            if (value <= 0)
                return;
            EventMgr.Trigger(EventKey.OnChgConfine,this);
        }
    }


    private int mTitle;
    public int Title
    {
        get { return mTitle; }
        set
        {
            mTitle = value;
            EventMgr.Trigger(EventKey.OnChgTitle, this);
        }
    }

    /// <summary>
    /// 初始buff列表
    /// </summary>
    private List<int> mBuffList = new List<int>();
    public List<int> BuffList { get { return mBuffList; } }

    #region 独有类型
    /// <summary>
    /// 怪物独有数据
    /// </summary>
    public p_map_monster MonsterExtra;
    /// <summary>
    /// 采集物独有数据
    /// </summary>
    public p_map_collection CollectionExtra;
    /// <summary>
    /// 陷阱独有字段
    /// </summary>
    public p_map_trap TrapExtra;
    /// <summary>
    /// 掉落物独有字段
    /// </summary>
    public p_map_drop DropExtra;

    #endregion

    public ActorData()
    {
    }

    #region 角色登入更新属性

    /// <summary>
    /// 更新角色登陆数据
    /// </summary>
    public void UpdateRoleData(p_role_data data)
    {
        if (data == null)
        {
            Loong.Game.iTrace.eError("HS", "p_role_data 数据结构体为null");
            return;
        }
        this.mUID = data.role_id;
        UpdateRoleAttr(data.attr);
        UpdateRoleBase(data.@base);
        NetAttr.RoleFightValueUpdate(data.powers);
    }

    /// <summary>
    /// 角色属性信息
    /// </summary>
    public void UpdateRoleAttr(p_role_attr attr)
    {
        if (attr == null) return;
        this.mName = attr.role_name;
        this.mSex = attr.sex;
        this.mCategory = attr.category;
        this.Level = attr.level;
        UpdateCate(mCategory);
        UpdateName(mName);
        UpdateExp(attr.exp, false);
        this.LstCreateTime = attr.create_time;
        this.LstLevUpTime = attr.last_level_time;
        this.OfflFTime = attr.offline_fight_time;
    }

    /// <summary>
    /// 角色战斗属性
    /// </summary>
    public void UpdateRoleBase(List<p_kdv> list)
    {
        if (list == null) return;

        var info = list.GetEnumerator();
        while (info.MoveNext())
        {
           UpdateBaseProperty(info.Current.id, info.Current.val);
        }
    }
    #endregion

    #region 角色进入地图属性
    /// <summary>
    /// 在地图中的物体数据
    /// </summary>
    public void UpdateActor(p_map_actor data)
    {
        if (data == null)
        {
            Loong.Game.iTrace.eError("HS", "p_map_actor 数据结构体为null");
            return;
        }
        this.UID = data.actor_id;
        this.Type = data.actor_type;
        this.Name = data.actor_name;
        this.MaxHp = data.max_hp;
        this.Hp = data.hp;
        this.Status = data.status;
        //this.ShowBuffStatus = data.show_buff_status;
        this.MoveSpeed = data.move_speed;
        this.Pos = data.pos;
        this.TargetPos = data.target_pos;
        this.Camp = data.camp_id;
        UpdateMapRole(data.role_extra);
        UpdateMonster(data.monster_extra);
        UpdateCollection(data.collection_extra);
        UpdateTrap(data.trap_extra);
        UpdateDrop(data.drop_extra);
        UpdateBuff(data.buff_id_list);
    }

    /// <summary>
    /// 角色独有的数据
    /// </summary>
    public void UpdateMapRole(p_map_role data)
    {
        if (data == null) return;
        this.ServerName = data.server_name;
        this.MarryID = data.couple_id;
        this.MarryName = data.couple_name;
        this.mSex = data.sex;
        this.mCategory = data.category;
        this.Level = data.level;
        this.ReliveLV = data.relive_level;
        this.pdState = (PendantStateEnum)data.weapon_state;
        this.mFamilyId = data.family_id;
        this.mFamilyName = data.family_name;
        this.mFamilyTitle = data.family_title;
        this.mTeamId = data.team_id;
        this.AllFightValue = data.power;
        this.Confine = data.confine;
        this.Title = data.title;
        this.PkValue = data.pk_value;
        this.ServerID = data.server_id;
        UpdateSkinList(data.skin_list);
        UpdateOrnaments(data.ornament_list);
    }

    /// <summary>
    /// 怪物独有的数据
    /// </summary>
    public void UpdateMonster(p_map_monster data)
    {
        if (data == null) return;
        this.MonsterExtra = data;
        this.Level = data.level;
        p_world_boss_owner info = data.world_boss_owner;
        long ownerId = 0;
        int level = 0;
        string name = "";
        int teamId = 0;
        long familyId = 0;
        if (info != null)
        {   
            ownerId = info.owner_id;
            level = info.owner_level;
            name = info.owner_name;
            teamId = info.team_id;
            familyId = info.family_id;
        }
        EventMgr.Trigger(EventKey.MonsterExtra, ownerId);
        EventMgr.Trigger(EventKey.BossBelonger, ownerId, level, name, teamId, familyId);
        if (ownerId != 0)
        {
            PickIcon.CheckShowIcon(UID, ownerId);
        }
    }

    /// <summary>
    /// 更新挂件
    /// </summary>
    /// <param name="skinList"></param>
    public void UpdateSkinList(List<int> skinList)
    {
        int count = skinList.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
        {
            int skin = skinList[i];
            if (mSkinList.Contains(skin))
                continue;
            mSkinList.Add(skin);
        }
    }

    /// <summary>
    /// 更新配饰
    /// </summary>
    /// <param name="ornaments"></param>
    public void UpdateOrnaments(List<int> ornaments)
    {
        int count = ornaments.Count;
        if (count == 0)
            return;
        for(int i = 0; i < count; i++)
        {
            int ornament = ornaments[i];
            if (mOrnamentList.Contains(ornament))
                continue;
            OrnamentList.Add(ornament);
        }
    }

    /// <summary>
    /// 采集物独有字段
    /// </summary>
    public void UpdateCollection(p_map_collection data)
    {
        if (data == null) return;
        this.CollectionExtra = data;
    }

    /// <summary>
    /// 陷阱独有字段
    /// </summary>
    public void UpdateTrap(p_map_trap data)
    {
        if (data == null) return;
        this.TrapExtra = data;
    }

    /// <summary>
    /// 掉落物独有字段
    /// </summary>
    public void UpdateDrop(p_map_drop data)
    {
        if (data == null) return;
        this.DropExtra = data;
    }

    /// <summary>
    /// 更新buff列表
    /// </summary>
    /// <param name="buffList"></param>
    public void UpdateBuff(List<int> buffList)
    {
        if (buffList == null)
            return;
        mBuffList.Clear();
        for(int i = 0; i < buffList.Count; i++)
        {
            mBuffList.Add(buffList[i]);
        }
    }

    #endregion

    #region 其他更新属性

    /// <summary>
    /// 经验/等级改变返回
    /// </summary>
    public void UpdateExpAndLevel(m_role_level_toc data)
    {
        this.Level = data.level;
        long exp = data.exp;
        bool isMonster_add = data.is_monster_add;
        UpdateExp(exp, isMonster_add);
    }

    /// <summary>
    /// 更新名字
    /// </summary>
    /// <param name="name"></param>
    private void UpdateName(string name)
    {
        EventMgr.Trigger(EventKey.OnChangeName, name);
    }

    private void UpdateCate(int cate)
    {
        EventMgr.Trigger(EventKey.OnChangeCate, cate);
    }

    private void UpdateExp(long exp, bool isKillMonster = false)
    {
        if (mExp < exp)
        {
            Int64 add = exp - mExp;
            if (add > 0)
            {
                UpdateAddExp(add, isKillMonster);
            }
            mExp = exp;
            if (User.instance.MapData != null && User.instance.MapData.UID == UID)
                EventMgr.Trigger(EventKey.OnChangeExp);
            return;
        }
        if(exp > mExp)
            UpdateAddExp(exp, isKillMonster);
        mExp = exp;
        if (User.instance.MapData != null && User.instance.MapData.UID == UID)
            EventMgr.Trigger(EventKey.OnChangeExp);
    }

    #endregion

    #region 更新当前等级经验上限
    public void UpdateLimitLevel()
    {
        uint key = (uint)((Category * 10 + Sex) * 1000 + mLevel);
        RoleAtt att = RoleAttManager.instance.Find(key);
        if (att != null) LimitExp = att.exp;
        EventMgr.Trigger(EventKey.OnUpdateLv);
    }
    #endregion

    #region 更新属性
    /// <summary>
    /// 显示到控制台（给数值用）
    /// </summary>
    Loong.Game.Timer mShowTimer = null;
    public void ShowInConsole()
    {
        if(mShowTimer == null)
        {
            mShowTimer = new Loong.Game.Timer();
            mShowTimer.complete += ShowAttrInConsole;
        }
        if (mShowTimer.Running)
            mShowTimer.Stop();
        mShowTimer.Seconds = 0.5f;
        mShowTimer.Start();

    }
    /// <summary>
    /// 显示属性到控制台(给数值用）
    /// </summary>
    public void ShowAttrInConsole()
    {
        string context = string.Format("{0}级->",this.Level);
        foreach(KeyValuePair<int,long> item in BaseProperty)
        {
            RolePro info = RoleProManager.instance.Find((uint)item.Key);
            if (info == null)
                continue;
            string name = info.proName;
            string str = string.Format(" {0}: {1}", name, item.Value);
            context += str;
        }
        foreach (KeyValuePair<long, long> item in ValueProperty)
        {
            RolePro info = RoleProManager.instance.Find((uint)item.Key);
            if (info == null)
                continue;
            string name = info.proName;
            string str = string.Format(" {0}: {1}", name, item.Value);
            context += str;
        }
        Debug.LogWarning(context);
    }

    /// <summary>
    /// 更新基础属性
    /// </summary>
    /// <param name="type"> 属性类型 </param>
    /// <param name="value"> 属性值 </param>
    public void UpdateBaseProperty(int type, long value, bool isFly = false)
    {
        if (BaseProperty.ContainsKey(type))
        {
            long up = value - BaseProperty[type];
            if (up > 0)
                EventMgr.Trigger(EventKey.OnUpdatePro, type, BaseProperty[type].ToString(), value.ToString());
            BaseProperty[type] = value;
            if (isFly && up > 0)
            {
                EventMgr.Trigger(EventKey.OnUpdateBaseProperty, type, up.ToString());
            }
        }
        else BaseProperty.Add(type, value);

    }

    /// <summary>
    /// 更新战斗力
    /// </summary>
    /// <param name="key"></param>
    /// <param name="value"></param>
    public void UpdateFightValue(FightValEnum key, int value)
    {
        if(FightValueDic.ContainsKey(key))
        {
            FightValueDic[key] = value;
        }
        else
        {
            FightValueDic.Add(key, value);
        }
    }

    /// <summary>
    /// 获取战力
    /// </summary>
    /// <param name="key"></param>
    /// <returns></returns>
    public Int32 GetFightValue(Byte key)
    {
        FightValEnum fve = (FightValEnum)key;
        return GetFightValue(fve);
    }

    /// <summary>
    /// 获取战力
    /// </summary>
    /// <param name="key"></param>
    /// <returns></returns>
    public Int32 GetFightValue(FightValEnum key)
    {
        if (!FightValueDic.ContainsKey(key))
            return 0;
        return FightValueDic[key];
    }

    public string GetFightStr(Byte key)
    {
        return GetFightValue(key).ToString();
    }

    /// <summary>
    /// 更新其他属性
    /// </summary>
    /// <param name="resp"> 服务器响应数据结构 </param>
    public void UpdateProperty(m_map_actor_attr_change_toc resp)
    {
        Unit unit = UnitMgr.instance.FindUnitByUid(UID);
        if (unit == null) return;
        //数值属性
        p_dkv pv = null;
        for (int i = 0; i < resp.kv_list.Count; i++)
        {
            pv = resp.kv_list[i];
            if (pv == null) continue;
            if (ValueProperty.ContainsKey(pv.id)) ValueProperty[pv.id] = pv.val;
            else ValueProperty.Add(pv.id, pv.val);
            //if ((UnitType)mType == UnitType.Monster && (PropertyBaseType)pv.id == PropertyBaseType.Kill_Monster_Pick)
            //{
            //    PickIcon.CheckShowIcon(UID, pv.val);
            //    EventMgr.Trigger(EventKey.MonsterExtra, pv.val);
            //}
            UnitPrptHelper.instance.PrptChange(this,unit,(PropertyType)pv.id, pv.val);
        }
        //字符串属性
        p_ks ps = null;
        for (int i = 0; i < resp.ks_list.Count; i++)
        {
            ps = resp.ks_list[i];
            if (ps == null) continue;
            if (StringProperty.ContainsKey(ps.id)) StringProperty[ps.id] = ps.str;
            else StringProperty.Add(ps.id, ps.str);
            PropertyType propertyType = (PropertyType)ps.id;
            if (propertyType == PropertyType.ATTR_RE_NAME) EventMgr.Trigger(EventKey.OnReName, UID, ps.str);
            UnitPrptHelper.instance.PrptChgStr(this, unit, (PropertyType)ps.id, ps.str);
        }

        //更新int属性列表,上线推送以及进入九宫格时的同步（所有挂件）
        for(int i = 0; i < resp.kl_list.Count; i++)
        {
            PropertyType propertyType = (PropertyType)resp.kl_list[i].id;
            if (propertyType == PropertyType.ATTR_PENDANT_CHANGE)
            {
                for (int k = 0; k < SkinList.Count; k++)
                {
                    int pendantId = SkinList[k];
                    if (resp.kl_list[i].list.Contains(pendantId))
                        continue;
                    SkinList.Remove(pendantId);
                    PendantMgr.instance.TakeOff(unit, (uint)pendantId,this);
                }
                for (int k = 0; k < resp.kl_list[i].list.Count; k++)
                {
                    int pendantId = resp.kl_list[i].list[k];
                    if (SkinList.Contains(pendantId))
                        continue;
                    SkinList.Add(pendantId);
                    if (PendantHelper.instance.ChkFbPdt((uint)pendantId))
                        continue;
                    PendantMgr.instance.PutOn(unit, (uint)pendantId,data:this);
                }
                PendantHelper.instance.CreateDefaultWeapon(unit, this);
            }
            else if(propertyType == PropertyType.ATTR_ORNAMENT_LIST)
            {
                for (int k = 0; k < OrnamentList.Count; k++)
                {
                    int ornamentId = OrnamentList[k];
                    if (resp.kl_list[i].list.Contains(ornamentId))
                        continue;
                    OrnamentList.Remove(ornamentId);
                    OrnamentsMgr.instance.RemoveOrnament(unit, ornamentId);
                }
                for (int k = 0; k < resp.kl_list[i].list.Count; k++)
                {
                    int ornamentId = resp.kl_list[i].list[k];
                    if (OrnamentList.Contains(ornamentId))
                        continue;
                    OrnamentList.Add(ornamentId);
                    OrnamentsMgr.instance.AddOrnament(unit, ornamentId);
                }
            }
            else
            {
                for (int k = 0; k < resp.kl_list[i].list.Count; k++)
                    UnitPrptHelper.instance.PrptChange(this, unit, propertyType, resp.kl_list[i].list[k]);
            }
        }
    }

    /// <summary>
    /// 更新个人属性
    /// </summary>
    /// <param name="resp"></param>
    public void UpdatePersonalPro(m_role_attr_change_toc resp)
    {
        //数值属性
        p_dkv pv = null;
        for (int i = 0; i < resp.kv_list.Count; i++)
        {
            pv = resp.kv_list[i];
            if (pv == null)
                continue;
            PersonalProType key = (PersonalProType)pv.id;
            if (ValPsnPro.ContainsKey(key))
                ValPsnPro[key] = pv.val;
            else
                ValPsnPro.Add(key, pv.val);
            if (PersonalProType.ATTR_LSTLEVUP == key)
                LstLevUpTime = (int)pv.val;
            else if (PersonalProType.ATTR_OFFLFIGHTTIME == key)
                OfflFTime = (int)pv.val;
        }
        //字符串属性
        p_ks ps = null;
        for (int i = 0; i < resp.ks_list.Count; i++)
        {
            ps = resp.ks_list[i];
            if (ps == null)
                continue;
            PersonalProType key = (PersonalProType)pv.id;
            if (StrPsnPro.ContainsKey(key))
                StrPsnPro[key] = ps.str;
            else
                StrPsnPro.Add(key, ps.str);
        }
    }
    #endregion

    #region 获得属性名
    /// <summary>
    /// 通过属性枚举获得属性名
    /// </summary>
    /// <param name="type"></param>
    /// <returns></returns>
    public string GetPropertyName(PropertyBaseType type)
    {
        return GetPropertyName((UInt32)type);
    }
     
    /// <summary>
    /// 通过属性id获得属性名
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    public string GetPropertyName(UInt32 id)
    {
        PropertyName pro = PropertyNameManager.instance.Find(id);
        if (pro != null) return pro.propertyName;
        return string.Empty;
    }

    #endregion

    #region 是否有掉落物
    private bool hasDrop = false;

    public bool HasDrop
    {
        get
        {
            return hasDrop;
        }

        set
        {
            hasDrop = value;
        }
    }
    #endregion

    #region 更新增长经验

    private void UpdateAddExp(Int64 exp, bool isKillMonster)
    {
        Int64 add = exp + AddExp;
        if (!User.instance.IsInitLoadScene && User.instance.MapData != null && User.instance.MapData.UID == UID)
        {
            long buff = 0;
            if (BaseProperty.ContainsKey((int)PropertyBaseType.Kill_Monster_Exp_Add_Buff))
                buff = BaseProperty[(int)PropertyBaseType.Kill_Monster_Exp_Add_Buff] / 100;
            EventMgr.Trigger(EventKey.OnAddExp, add.ToString(), isKillMonster, buff.ToString());
        }
    }

    #endregion

    public string GetBaseProperty(int type)
    {
        if(BaseProperty.ContainsKey(type))
        {
            return BaseProperty[type].ToString();
        }
        return string.Empty;
    }


    public void Clear()
    {
        mUID = 0;
        mCategory = 0;
        mSex = 0;
        mLevel = 0;
        pdState = PendantStateEnum.Normal;
        mSkinList.Clear();
        mOrnamentList.Clear();
        mName = String.Empty;
        mExp = 0;
        mLimitExp = 1;
        mExp = 0;
        mReliveLv = 0;
        mLstCreateTime = 0;
        mLstLevUpTime = 0;
        mOfflFTime = 0;
        AddExp = 0;
        BaseProperty.Clear();
        ValueProperty.Clear();
        StringProperty.Clear();
        ValPsnPro.Clear();
        StrPsnPro.Clear();
        FightValueDic.Clear();
        mType = 0;
        mStatus = 0;
        mShowBuffStatus = 0;
        mMoveSpeed = 0;
        mPos = 0;
        isInitPos = false;
        mTargetPos = 0;
        mHp = 100000;
        mMaxHp = 100000;
        HpStr = mHp.ToString();
        MaxHpStr = mMaxHp.ToString();
        mCamp = 0;
        skillInfoList.Clear();
        petSkillInfoList.Clear();
        mountSkillInfoList.Clear();
        mgwpSkillInfoList.Clear();
        wingSkillInfoList.Clear();
        fashionSkillInfoList.Clear();
        mPkValueTime = 0;
        mFamilyId = 0;
        mFamilyName = string.Empty;
        mTeamId = 0;
        mFightVal = 0;
        MonsterExtra = null;
        CollectionExtra = null;
        TrapExtra = null;
        DropExtra = null;


    }
}
