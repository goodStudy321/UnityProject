using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;
using Loong.Game;

public class Unit
{
    #region 私有成员变量
    // 单位唯一id
    private long mUnitUID;
    //单位类型Id
    private UInt32 mTypeId;
    //单位模型ID
    private ushort mModelId;
    //动作组Id
    private ushort mActGroupId;
    //单位名字
    private string mName;
    //单位当前血量
    private long mCurHP;
    //单位最大血量
    private long mMaxHP;
    //单位阵营
    private CampType mCamp = CampType.CampType1;
    //职业
    private int mCategory;
    //队伍Id
    private int mTeamId;
    //帮派Id
    private long mFamilyId;
    //头像条
    private TopBarBase topBar = null;
    //头像UI条
    private TopBarBase mHeadBar = null;
    //单位变换
    private Transform mUnitTrans;
    //单位默认武器模型
    private Transform mDefaultWeaponMod;
    //单位位置
    private Vector3 mPosition;
    //移动速度
    private float mMoveSpeed;
    //单位胶囊体碰撞
    private CapsuleCollider mCollider;
    //单位弧度
    private float mOrientation;
    //战斗模式
    private int mFightType;
    //Pk值时间
    private float mPkValueTime;
    //Pk值
    private float mPkValue;
    //服务器ID
    private int mServerId;
    //战斗力
    private float mFightVal;
    //动作状态机
    private ActionStatus mActionStatus = null;
    //攻击组件
    private HitComponent mHitComponent = null;
    //父体
    private Unit mParentUnit = null;
    //是否跟随父体
    private bool mFollowParent = false;
    //单位GameObject销毁状态
    private bool mDestroyState = false;
    //是否达到最高点
    private bool mOnHighest = false;
    //是否在掉落中
    private bool mOnFall = false;
    //子单位列表
    private List<Unit> children = new List<Unit>();
    //坐骑
    private Unit mMount;
    //宠物
    private Unit mPet;
    //法宝
    private Unit mMagicWeapon;
    // 翅膀
    private Unit mWing;
    //神兵
    private Unit mArtifact;
    //时装装备
    private Unit mFashionWp;
 
    #endregion

    #region 公有变量
    //在线状态
    public UnitStateOnline mStateOnLine = UnitStateOnline.Normal;
    //单位基础属性信息
    public UnitAttInfo mUnitAttInfo = new UnitAttInfo();
    //骨骼信息
    public UnitBoneInfo mUnitBoneInfo = new UnitBoneInfo();
    //buff状态
    public UnitBuffStateInfo mUnitBuffStateInfo = new UnitBuffStateInfo();
    //单位模型大小
    public UnitTransScale mUnitTransScale = new UnitTransScale();
    //单位动画
    public UnitAnimation mUnitAnimation = new UnitAnimation();
    //单位要切换的技能
    public UnitSkill mUnitSkill = new UnitSkill();
    //单位特效
    public UnitEffects mUnitEffects = new UnitEffects();
    //单位受击
    public UnitOnHit mUnitOnHit = new UnitOnHit();
    //单位移动
    public UnitMove mUnitMove = new UnitMove();
    //网络单位移动
    public NetUnitMove mNetUnitMove = new NetUnitMove();
    //单位buff管理
    public BuffManager mBuffManager = new BuffManager();
    //单位红名信息
    public UnitRedNameInfo mUnitRedNameInfo = new UnitRedNameInfo();
    //单位溶解
    public UnitDissolve mUnitDissolve = new UnitDissolve();
    //单位外发光
    public UnitOutLine mUnitOutline = new UnitOutLine();
    //单位计时类
    public UnitTimer mUnitTimer = new UnitTimer();
    /// <summary>
    /// 使用旧养成单位类型ID字典
    /// </summary>
    public Dictionary<uint, uint> OldPendantDic = new Dictionary<uint, uint>();
    //挂载类实例
    public IPendant mPendant;
    // 时装ID
    public uint mFashionID = 0;
    //宠物坐骑
    public PetMount mPetMount;
    //足迹外观
    public FootPrint mFootPrint;

    //脚下光圈
    public Aperture mAperture;
    //最新攻击者
    public Unit mLastAttacker;
    #endregion

    #region 属性

    /// <summary>
    /// 单位唯一ID
    /// </summary>
    public long UnitUID
    {
        get { return mUnitUID; }
        set { mUnitUID = value; }
    }

    /// <summary>
    /// 单位类型Id
    /// </summary>
    public UInt32 TypeId
    {
        get { return mTypeId; }
        set { mTypeId = mUnitAttInfo.UnitTypeId = value; }
    }
    /// <summary>
    /// 单位模型ID
    /// </summary>
    public ushort ModelId
    {
        get { return mModelId; }
        set { mModelId = value; }
    }

    /// <summary>
    /// 动作组ID
    /// </summary>
    public ushort ActGroupId
    {
        get { return mActGroupId; }
        set { mActGroupId = value; }
    }

    /// <summary>
    /// 单位名字
    /// </summary>
    public string Name
    {
        get { return mName; }
        set { mName = value; }
    }

    /// <summary>
    /// 单位当前血量
    /// </summary>
    public long HP
    {
        get { return mCurHP; }
        set {
            mCurHP = value <= MaxHP ? value : MaxHP;
            EventMgr.Trigger(EventKey.OnChangeUnitHP, mUnitUID, mCurHP, mMaxHP);
        }
    }

    /// <summary>
    /// 最大血量
    /// </summary>
    public long MaxHP
    {
        get { return mMaxHP; }
        set {
            mMaxHP = value;
            EventMgr.Trigger(EventKey.OnChangeUnitHP, mUnitUID, mCurHP, mMaxHP);
        }
    }

    /// <summary>
    /// 死亡状态
    /// </summary>
    public bool Dead
    {
        get { return HP <= 0; }
    }

    /// <summary>
    /// 单位阵营
    /// </summary>
    public CampType Camp
    {
        get { return mCamp; }
        set { mCamp = value; }
    }

    /// <summary>
    /// 职业
    /// </summary>
    public int Category
    {
        get { return mCategory; }
        set { mCategory = value; }
    }

    /// <summary>
    /// 队伍ID
    /// </summary>
    public int TeamId
    {
        get { return mTeamId; }
        set { mTeamId = value; }
    }

    /// <summary>
    /// 帮派Id
    /// </summary>
    public long FamilyId
    {
        get { return mFamilyId; }
        set { mFamilyId = value; }
    }

    /// <summary>
    /// 单位头顶条
    /// </summary>
    public TopBarBase TopBar
    {
        get { return topBar; }
        set { topBar = value; }
    }

    /// <summary>
    /// 单位头像UI条
    /// </summary>
    public TopBarBase HeadBar
    {
        get { return mHeadBar; }
        set { mHeadBar = value; }
    }

    /// <summary>
    /// 单位变换
    /// </summary>
    public Transform UnitTrans
    {
        get { return mUnitTrans; }
        set { mUnitTrans = value; }
    }

    /// <summary>
    /// 默认武器
    /// </summary>
    public Transform DefaultWeaponMod
    {
        get { return mDefaultWeaponMod; }
        set { mDefaultWeaponMod = value; }
    }

    /// <summary>
    /// 单位位置
    /// </summary>
    public Vector3 Position
    {
        get
        {
            if (mUnitTrans != null)
                mPosition = mUnitTrans.position;
            return mPosition;
        }
        set
        {
            if (mUnitTrans == null)
                return;
            mUnitTrans.position = value;
            if (Global.Mode == PlayMode.Local) return;
            if (this.UnitUID != User.instance.MapData.UID) return;
            EventMgr.Trigger("OnPlayerMove", value.x, value.z);
        }
    }

    /// <summary>
    /// 移动速度
    /// </summary>
    public float MoveSpeed
    {
        get { return mMoveSpeed; }
        set
        {
            mMoveSpeed = value;
            mUnitMove.SetPathFindingSpeed(value);
            if(Mount != null)
                Mount.MoveSpeed = value;
            if (Pet != null)
                Pet.MoveSpeed = value;
            if (MagicWeapon != null)
                MagicWeapon.MoveSpeed = value;
        }
    }

    /// <summary>
    /// 单位碰撞
    /// </summary>
    public CapsuleCollider Collider
    {
        get
        {
            if (mCollider == null && UnitTrans != null)
            {
                mCollider = UnitTrans.GetComponent<CapsuleCollider>();
                if (mCollider == null)
                    Loong.Game.iTrace.Error("Error", UnitTrans.name + "CapsuleCollider is null!");
            }
            return mCollider;
        }
    }

    /// <summary>
    /// 单位弧度
    /// </summary>
    public float Orientation
    {
        get { return mOrientation; }
    }

    /// <summary>
    /// 战斗类型
    /// </summary>
    public int FightType
    {
        get { return mFightType; }
        set
        {
            mFightType = value;
            PendantHelper.instance.SetPendantFightType(this);
        }
    }

    /// <summary>
    /// PK值时间
    /// </summary>
    public float PkValueTime
    {
        get { return mPkValueTime; }
        set { mPkValueTime = value; }
    }

    /// <summary>
    /// PK值
    /// </summary>
    public float PkValue
    {
        get { return mPkValue; }
        set { mPkValue = value; }
    }

    /// <summary>
    /// 服务器ID
    /// </summary>
    public int ServerId
    {
        get { return mServerId; }
        set { mServerId = value; }
    }

    /// <summary>
    /// 战斗力
    /// </summary>
    public float FightVal
    {
        get { return mFightVal; }
        set { mFightVal = value; }
    }

    /// <summary>
    /// 动作状态机
    /// </summary>
    public ActionStatus ActionStatus
    {
        get { return mActionStatus; }
        set { mActionStatus = value; }
    }

    /// <summary>
    /// 攻击组件
    /// </summary>
    public HitComponent HitComponent
    {
        get { return mHitComponent; }
    }

    /// <summary>
    /// 父体
    /// </summary>
    public Unit ParentUnit
    {
        get { return mParentUnit; }
        set { mParentUnit = value; }
    }

    /// <summary>
    /// 销毁状态
    /// </summary>
    public bool DestroyState
    {
        get { return mDestroyState; }
    }

    /// <summary>
    /// 是否达到最大高度
    /// </summary>
    public bool OnHighest
    {
        get { return mOnHighest; }
    }

    /// <summary>
    /// 是否下落过程中
    /// </summary>
    public bool OnFall
    {
        get { return mOnFall; }
        set { mOnFall = value; }
    }
    
    /// <summary>
    /// 是否跟随父体
    /// </summary>
    public bool FollowParent
    {
        get { return mFollowParent; }
        set { mFollowParent = value; }
    }

    /// <summary>
    /// 子单位列表
    /// </summary>
    public List<Unit> Children
    {
        get { return children; }
        set { children = value; }
    }

    /// <summary>
    /// 坐骑
    /// </summary>
    public Unit Mount
    {
        get { return mMount; }
        set { mMount = value; }
    }

    /// <summary>
    /// 宠物
    /// </summary>
    public Unit Pet
    {
        get { return mPet; }
        set { mPet = value; }
    }

    /// <summary>
    /// 法宝
    /// </summary>
    public Unit MagicWeapon
    {
        get { return mMagicWeapon; }
        set { mMagicWeapon = value; }
    }

    /// <summary>
    /// 翅膀
    /// </summary>
    public Unit Wing
    {
        get { return mWing; }
        set { mWing = value; }
    }

    /// <summary>
    /// 神兵
    /// </summary>
    public Unit Artifact
    {
        get { return mArtifact; }
        set { mArtifact = value; }
    }

    /// <summary>
    /// 时装武器
    /// </summary>
    public Unit FashionWp
    {
        get { return mFashionWp; }
        set { mFashionWp = value; }
    }

    #endregion

    #region 公开方法
    /// <summary>
    /// 初始化单位
    /// </summary>
    public void Init(Transform trans)
    {
        SetUnitTransInfo(trans);
        mUnitRedNameInfo.Init(this);
        mUnitMove.Init(this);
        mNetUnitMove.Init(this);
        mUnitBuffStateInfo.Init(this);
        mBuffManager.Init(this);
        //mUnitDissolve.init(this);
        InitActionstatus();
        InitHitComponent();
        InitEventLsnr();
    }

    /// <summary>
    /// 设置单位变换
    /// </summary>
    /// <param name="trans"></param>
    public void SetUnitTransInfo(Transform trans)
    {
        UnitTrans = trans;
        mUnitBoneInfo.InitBoneInfo(trans);
        mUnitAnimation.SetUnitObject(trans.gameObject);
    }

    public void InitEventLsnr()
    {
        if (mUnitAttInfo.UnitType == UnitType.Role)
        {
            EventMgr.Add(EventKey.OnChgConfine, ChgConfine);
            EventMgr.Add(EventKey.OnChgTitle, ChgTitle);
            EventMgr.Add(EventKey.OnChgTtileState, ChgTitleState);
            EventMgr.Add(EventKey.OnReName, ChangeName);
        }    
    }

    private void RemoveLsnr()
    {
        if (mUnitAttInfo.UnitType == UnitType.Role)
        {
            EventMgr.Remove(EventKey.OnChgConfine, ChgConfine);
            EventMgr.Remove(EventKey.OnChgTitle, ChgTitle);
            EventMgr.Remove(EventKey.OnChgTtileState, ChgTitleState);
            EventMgr.Remove(EventKey.OnReName, ChangeName);
        }
    }

    /// <summary>
    /// 设置数据
    /// </summary>
    public void SetData(long uid,uint typeId,string name,CampType camp)
    {
        Reset();
        UnitUID = uid;
        TypeId = typeId;
        Name = name;
        MaxHP = 100000;
        HP = 100000;
        Camp = camp;
        FightType = 1;
        ushort modeId = UnitHelper.instance.GetUnitModeId(typeId);
        ModelId = modeId;
        ActGroupId = modeId;
    }

    /// <summary>
    /// 加载模型
    /// </summary>
    public void LoadMod(Vector3 pos, float eulerAngleY, string bornAction, Action<Unit> callBack)
    {
        string modelName = null;
        RoleBase roleInfo = RoleBaseManager.instance.Find(ModelId);
        if (roleInfo != null) modelName = roleInfo.modelPath;
        if (string.IsNullOrEmpty(modelName))
            return;
        UnitLD unitLD = ObjPool.Instance.Get<UnitLD>();
        unitLD.SetData(this, pos, eulerAngleY, bornAction, callBack);
        AssetMgr.LoadPrefab(modelName, unitLD.LoadDone);
    }

    public void Reset()
    {
        mUnitUID = 0;
        mTypeId = 0;
        mModelId = 0;
        mActGroupId = 0;
        mName = "";
        mCurHP = 0;
        mMaxHP = 0;
        mCamp = CampType.CampType1;
        mCategory = 0;
        mTeamId = 0;
        mFamilyId = 0;
        topBar = null;
        mHeadBar = null;
        mUnitTrans = null;
        mDefaultWeaponMod = null;
        mPosition = Vector3.zero;
        mMoveSpeed = 0;
        mCollider = null;
        mOrientation = 0;
        mFightType = 0;
        mPkValueTime = 0;
        mPkValue = 0;
        mFightVal = 0;
        mActionStatus = null;
        mHitComponent = null;
        mParentUnit = null;
        mFollowParent = false;
        mDestroyState = false;
        mOnHighest = false;
        mOnFall = false;
        mMount = null;
        mPet = null;
        mMagicWeapon = null;
        mWing = null;
        mArtifact = null;
        mFashionWp = null;
        mUnitTimer.Stop();
        mPendant = null;
        mFashionID = 0;
        mLastAttacker = null;
        children.Clear();
    }

    /// <summary>
    /// 境界改变
    /// </summary>
    /// <param name="args"></param>
    public void ChgConfine(params object[] args)
    {
        if (args.Length == 0)
            return;
        if (topBar == null)
            return;
        CommenNameBar bar = topBar as CommenNameBar;
        if (bar == null)
            return;
        ActorData actData = (ActorData)args[0];
        if (actData.UID != this.UnitUID)
            return;
        bar.Name = UnitHelper.instance.GetUnitFullName(actData);
        //mAperture.PutOn(this, actData);
    }

    /// <summary>
    /// 称号改变
    /// </summary>
    /// <param name="args"></param>
    public void ChgTitle(params object[] args)
    {
        if (args.Length == 0)
            return;
        if (topBar == null)
            return;
        CommenNameBar bar = topBar as CommenNameBar;
        if (bar == null)
            return;
        ActorData actData = (ActorData)args[0];
        if (actData.UID != this.UnitUID)
            return;
        bar.TitleId = actData.Title;
    }


    /// <summary>
    /// 改变称号显示状态
    /// </summary>
    /// <param name="args"></param>
    public void ChgTitleState(params object[] args)
    {
        if (args.Length == 0)
            return;
        if (topBar == null)
            return;
        CommenNameBar bar = topBar as CommenNameBar;
        if (bar == null)
            return;
        bool state = (bool)args[0];
        if (mUnitUID != User.instance.MapData.UID)
        {
            bar.ChgTitleState(state);
        }
    }

    /// <summary>
    /// 名字改变
    /// </summary>
    /// <param name="args"></param>
    public void ChangeName(params object[] args)
    {
        if (this.UnitUID != Convert.ToInt64(args[0])) return;
        if (topBar == null) return;
        CommenNameBar bar = topBar as CommenNameBar;
        if (bar == null)
            return;
        bar.Name = Convert.ToString(args[1]);
    }

    /// <summary>
    /// 设置方向
    /// </summary>
    /// <param name="forward"></param>
    public void SetForward(Vector3 forward)
    {
        float orientation = Mathf.Atan2(forward.x, forward.z);
        SetOrientation(orientation);
    }

    /// <summary>
    /// 设置方向
    /// </summary>
    /// <param name="orient">方向弧度</param>
    public void SetOrientation(float orient)
    {
        /// LY add 判断空引用 ///
        if (UnitTrans == null)
            return;

        mOrientation = orient;
        UnitTrans.rotation = Quaternion.Euler(0, mOrientation * Mathf.Rad2Deg, 0);
    }

    /// <summary>
    /// 设置方向
    /// </summary>
    /// <param name="orient">方向弧度</param>
    /// <param name="rotateSpeed">旋转速度</param>
    public void SetOrientation(float orient, float rotateSpeed)
    {
        mOrientation = orient;
        UnitTrans.rotation = Quaternion.Lerp(UnitTrans.rotation, Quaternion.Euler(0, mOrientation * Mathf.Rad2Deg, 0), Time.deltaTime * rotateSpeed);
    }

    /// <summary>
    /// 直接设置弧度
    /// </summary>
    public void DirectlySetOrientation()
    {
        mOrientation = Mathf.Atan2(UnitTrans.forward.x, UnitTrans.forward.z);
    }

    /// <summary>
    /// 初始化动作状态
    /// </summary>
    public void InitActionstatus()
    {
        ActionStatus = new ActionStatus(this);
    }

    /// <summary>
    /// 初始化攻击脚本
    /// </summary>
    public void InitHitComponent()
    {
        mHitComponent = UnitTrans.GetComponent<HitComponent>();
        if (mHitComponent == null)
            mHitComponent = UnitTrans.gameObject.AddComponent<HitComponent>();
        mHitComponent.mOwner = this;
    }

    /// <summary>
    /// 处理单位动画
    /// </summary>
    public void ProcessActiveAnimation(ActionData actionData)
    {
        mUnitAnimation.SetAnimationTimeScale(actionData);
        mUnitAnimation.PlayAnimation(actionData);
    }

    /// <summary>
    /// 设置动画速度
    /// </summary>
    public void SetAnimationSpeed(float animSpeed)
    {
        mUnitAnimation.SetAnimationSpeed(animSpeed);
    }

    /// <summary>
    /// 开始动作检查
    /// </summary>
    /// <param name="actionType"></param>
    public void OnActionCheck(ActionRunningState actionType)
    {
        mUnitEffects.OnActionEffectCheck(actionType);
    }

    /// <summary>
    /// 移除动作检查
    /// </summary>
    /// <param name="strAction"></param>
    public void RemoveActionCheck(string strAction)
    {
        mUnitEffects.RemoveActionEffectCheck(strAction);
    }

    /// <summary>
    /// 到达最高点
    /// </summary>
    /// <param name="value"></param>
    public void OnReachHighest(bool value)
    {
        mOnHighest = value;
    }

    /// <summary>
    /// 销毁单位
    /// </summary>
    public void Destroy()
    {
        if (mDestroyState)
            return;
        if (ParentUnit != null)
        {
            PendantMgr.instance.RemoveFromPendantUnitListByUnit(this);
            ParentUnit.RemoveChildUnit(this);
            ParentUnit = null;
        }

        for (int i = 0; i < children.Count; i++)
        {
            PendantMgr.instance.RemoveFromPendantUnitListByUnit(children[i]);
            children[i].ParentUnit = null;
            children[i].Destroy();
        }

        HP = 0;
        mDestroyState = true;
        PathTool.PathMoveMgr.instance.CheckRemoveInPathUnit(this);
        UnitMgr.instance.RemoveUnit(this);
        mUnitEffects.Destroy();
        mBuffManager.DestoryAllBuffs();
        mUnitTimer.Stop();
        OrnamentsMgr.instance.RemoveOrnament(this, -1);
        PendantMgr.instance.TakeOffAllPendant(this);
        SettingMgr.instance.HandleOfView(this);
        if (UnitTrans != null)
        {
            DealGbj();
            //GameObject.Destroy(UnitTrans.gameObject);
            UnitMgr.instance.UpdAtkUnitList(this, false);
            BossBatMgr.instance.RemoveTarget(this.UnitUID);
        }
        mUnitDissolve.Clear();
        mUnitOutline.Clear();
        if (topBar != null)
        {
            topBar.Dispose();
            topBar = null;
            LockTarMgr.instance.DisTopBar(this);
        }
        DestroyHitDef();
        RemoveLsnr();
        Dispose();
        ObjPool.Instance.Add(this);
    }

    /// <summary>
    /// 处理对象
    /// </summary>
    public void DealGbj()
    {
        if (UnitTrans == null)
            return;
        RoleBase roleBase = RoleBaseManager.instance.Find(mModelId);
        if (roleBase == null)
        {
            GameObject.Destroy(UnitTrans.gameObject);
        }
        else
        {
            string name = roleBase.modelPath;
            UnitTrans.name = name;
            GbjPool.Instance.Add(UnitTrans.gameObject);
        }
    }

    /// <summary>
    /// 销毁攻击定义
    /// </summary>
    public void DestroyHitDef()
    {
        if (mHitComponent == null)
            return;
        mHitComponent.OnDestroy();
    }

    /// <summary>
    /// 销毁召唤体
    /// </summary>
    public void DestroySmmn()
    {
        for (int i = 0; i < children.Count; i++)
        {
            UnitType type = UnitHelper.instance.GetUnitType(children[i].TypeId);
            if (type != UnitType.Summon)
                continue;
            children[i].Destroy();
        }
    }

    /// <summary>
    /// 添加子单位
    /// </summary>
    /// <param name="unit"></param>
    public void AddChildUnit(Unit unit)
    {
        unit.ParentUnit = this;
        children.Add(unit);
    }

    /// <summary>
    /// 销毁子单位
    /// </summary>
    /// <param name="unit"></param>
    public void RemoveChildUnit(Unit unit)
    {
        children.Remove(unit);
    }

    /// <summary>
    /// 刷新单位动作数据
    /// </summary>
    public void RefreshUnitActionSetup()
    {
        if (UnitTrans == null)
            return;
        if (DestroyState)
            return;
        ActionStatus.ResetActionGroup();
    }

    /// <summary>
    /// 单位更新
    /// </summary>
    /// <param name="deltaTime"></param>
    public void Update(float deltaTime)
    {
        if (UnitTrans == null)
            return;
        if (DestroyState)
            return;
        mBuffManager.UpdateBufferList(deltaTime);
        mUnitTransScale.Update(UnitTrans, deltaTime);
        mUnitMove.Update();
        mNetUnitMove.UpdateMove(this);
        if (ActionStatus != null) ActionStatus.Update(deltaTime * mUnitAnimation.ActionTimeScale);
        //if (topBar != null) topBar.Update();
        if (mHeadBar != null) mHeadBar.Update();
        mUnitEffects.Update();
        mUnitSkill.Update(deltaTime);
        mUnitDissolve.Update();
        mUnitOutline.Update();
    }


    public void LateUpdate()
    {
        if (UnitTrans == null)
            return;
        if (DestroyState)
            return;
        if (topBar != null) topBar.Update();
    }

    public void Dispose()
    {
        mUnitAttInfo.Dispose();
        mUnitBoneInfo.Dispose();
        mUnitBuffStateInfo.Dispose();
        mUnitTransScale.Dispose();
        mUnitAnimation.Dispose();
        mUnitSkill.Dispose();
        mUnitEffects.Dispose();
        mUnitMove.Dispose();
        mNetUnitMove.Dispose();
        mBuffManager.Dispose();
        mUnitRedNameInfo.Dispose();
        mUnitTimer.Dispose();
        if (mAperture != null)
        {
            mAperture.Dispose();
            mAperture = null;
        }
    }

    //// LY add begin ////
    
    /// <summary>
    /// 是否可以播放音效
    /// </summary>
    /// <returns></returns>
    public bool CanPlaySound()
    {
        GlobalData gData = GlobalDataManager.instance.Find(123);
        if(gData == null || gData.num1 == "0")
        {
            return true;
        }

        return UnitHelper.instance.IsOwner(this);
    }

    //// LY add end ////

    #endregion
}
