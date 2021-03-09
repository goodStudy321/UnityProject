using System;
using System.Collections;
using System.Collections.Generic;
/*
  * CO:            
  * Copyright:   2017-forever
  * CLR Version: 4.0.30319.42000  
  * GUID:        59d2494f-83c7-4e1d-899b-332b5a02668e
 */

/// <summary>
/// AU:Loong
/// TM:2017/5/15 15:29:47
/// BG:事件键值定义
/// </summary>
public static class EventKey
{
    #region 字段
    #region 登入
    /// <summary>
    /// 登出
    /// </summary>
    public const string Logout = "LogoutSuc";
    public const string OnLoginCreate = "OnLoginCreate";
    // public const string OnLoginCreateSuccessful = "OnLoginCreateSuccessful";
    // public const string OnLoginSuccessful = "OnLoginSuccessful";
    #endregion
    #region 语音
    /// <summary>
    /// 登出
    /// </summary>
    public const string VoiceLogin = "VoiceLogin";


    #endregion


    #region 诛仙战场占领聚灵牌
    /// <summary>
    /// 占领聚灵牌
    /// </summary>
    public const string GetPolyCard = "GetPolyCard";
    #endregion

    #region  选角色
    public const string OnSelectPlayer = "OnSelectPlayer";
    public const string OnRestoreSelectPlayer = "OnRestoreSelectPlayer";
    public const string OnMoveUISelectPlayer = "OnMoveUISelectPlayer";
    public const string RoleLogin = "RoleLogin";
    #endregion

    #region 创建角色
    public const string OnUpdateUnit = "OnUpdateUnit";
    #endregion

    #region 属性
    public const string OnChangeFight = "OnChangeFight";
    public const string OnChangeName = "OnChangeName";
    public const string OnChangeCate = "OnChangeCate";
    public const string OnReName = "OnReName";
    public const string OnChangeHP = "OnChangeHP";
    public const string OnChangeLv = "OnChangeLv";
    public const string OnUpdateLv = "OnUpdateLv";
    public const string OnChangeExp = "OnChangeExp";
    public const string OnAddExp = "OnAddExp";
    public const string OnUpdateBaseProperty = "OnUpdateBaseProperty";
    public const string OnUpdatePro = "OnUpdatePro";
    public const string OnUpdateProEnd = "OnUpdateProEnd";
    public const string OnUpdateFightEnd = "OnUpdateFightEnd";
    public const string OnChgConfine = "OnChgConfine";
    public const string OnChgTitle = "OnChgTitle";
    public const string OnChgTtileState = "OnChgTtileState";


    public const string OnChangeUnitHP = "OnChangeUnitHP";

    public const string OnUpdateMonsterHP = "OnUpdateMonsterHP";

    public const string OnChangeFTtarget = "OnChangeFTtarget";
    #endregion

    #region 角色设置
    /// <summary>
    /// 屏蔽特效
    /// </summary>
    public const string OnShieldEff = "OnShieldEff";
    /// <summary>
    /// 改变同屏显示人数
    /// </summary>
    public const string OnChgShowNum = "OnChgShowNum";
    #endregion

    #region 队伍、仙盟
    /// <summary>
    /// 队伍Id改变
    /// </summary>
    public const string ChgTmOrFml = "ChgTmOrFml";
    #endregion

    #region UI
    /// <summary>
    /// 打开UI键值 参数1:UI名称 参数2:Lua UI对象 C#类型是(LuaTable)
    /// </summary>
    public const string UIOpen = "UIOpen";

    /// <summary>
    /// 打开UI键值 参数1:UI名称 参数2:Lua UI对象 C#类型是(LuaTable)
    /// </summary>
    public const string UIClose = "UIClose";

    /// <summary>
    /// 打开相机
    /// </summary>
    public const string CamOpen = "CamOpen";

    /// <summary>
    /// 关闭相机
    /// </summary>
    public const string CamClose = "CamClose";
    /// <summary>
    /// 技能更新完成
    /// </summary> 
    public const string SkillUpdate = "SkillUpdate";
    /// <summary>
    /// 技能点击事件
    /// </summary>
    public const string Skill_1OnClick = "Skill_1OnClick";
    public const string Skill_2OnClick = "Skill_2OnClick";
    public const string Skill_3OnClick = "Skill_3OnClick";
    public const string Skill_4OnClick = "Skill_4OnClick";
    public const string Skill_5OnClick = "Skill_5OnClick";
    public const string SkillAttackOnClick = "SkillAttackOnClick";
    public const string SkillInit = "SkillInit";

    /// <summary>
    /// 设置技能自动释放状态
    /// </summary>
    public const string SetSkState = "SetSkState";
    /// <summary>
    ///开启系统开启UI
    /// </summary>
    public const string UpdateOperation = "UpdateOperation";
    /// <summary>
    /// 开启系统并不开启UI
    /// </summary>
    public const string UpdateOperationNoUI = "UpdateOperationNoUI";

    /// <summary>
    /// 获取当前语言翻译
    /// </summary>
    public const string GetLocalString = "GetLocalString";
    #endregion

    #region 单位资源
    /// <summary>
    /// 单位资源
    /// </summary>
    public const string UpdateRoleAssets = "UpdateRoleAssets";
    //主角初始化
    public const string InitOwner = "InitOwner";
    #endregion

    #region 主界面
    /// <summary>
    /// 更新战斗模式
    /// </summary>
    public const string UpdateFightMode = "UpdateFightMode";
    #endregion

    #region 宠物
    public const string UpdatePetData = "UpdatePetData";
    /// <summary>
    /// 更新宠物激活
    /// </summary>
    public const string UpdatePetActive = "UpdatePetActive";
    /// <summary>
    /// 更新宠物进阶精魄
    /// </summary>
    public const string UpdatePetStepExp = "UpdatePetStepExp";
    /// <summary>
    /// 更新Info
    /// </summary>
    public const string UpdatePetInfo = "UpdatePetInfo";
    /// <summary>
    /// 更新宠物等级
    /// </summary>
    public const string UpdatePetLevel = "UpdatePetLevel";
    /// <summary>
    /// 更新宠物经验
    /// </summary>
    public const string UpdatePetExp = "UpdatePetExp";
    /// <summary>
    /// 更新宠物进阶
    /// </summary>
    public const string UpdatePetUpStep = "UpdatePetUpStep";
    /// <summary>
    /// 更新宠物使用精魄Num
    /// </summary>
    public const string UpdatePetUseJingpoItem = "UpdatePetUseJingpoItem";
    /// <summary>
    /// 宠物幻化
    /// </summary>
    public const string UpdatePetChange = "UpdatePetChange";
    #endregion

    #region 采集
    /// <summary>
    /// 进度采集物范围 参数1:采集物UID 参数2:采集物配置
    /// </summary>
    public const string EnterCollect = "EnterCollect";

    /// <summary>
    /// 请求开始采集
    /// </summary>
    public const string ReqBegCollect = "ReqBegCollect";

    /// <summary>
    /// 响应开始采集,参数1:UID 参数2:持续时间 参数3:错误码
    /// </summary>
    public const string RespBegCollect = "RespBegCollect";

    /// <summary>
    /// 请求停止采集
    /// </summary>
    public const string ReqStopCollect = "ReqStopCollect";

    /// <summary>
    /// 响应停止采集,参数1:UID 参数2:错误码
    /// </summary>
    public const string RespStopCollect = "RespStopCollect";

    /// <summary>
    /// 响应结束采集,参数1:UID 参数2:错误码
    /// </summary>
    public const string RespEndCollect = "RespEndCollect";

    #endregion

    #region 消息框
    /// <summary>
    /// 设置消息框按钮字符 参数1:Yes字符
    /// </summary>
    public const string MsgBoxYes = "MsgBoxYes";

    /// <summary>
    /// 设置消息框按钮字符 参数1:Yes字符 参数2:No字符
    /// </summary>
    public const string MsgBoxYesNo = "MsgBoxYesNo";

    /// <summary>
    /// 消息框点击Yes按钮
    /// </summary>
    public const string MsgBoxClickYes = "MsgBoxClickYes";

    /// <summary>
    /// 消息框点击No按钮
    /// </summary>
    public const string MsgBoxClickNo = "MsgBoxClickNo";

    #endregion

    #region 流程树
    /// <summary>
    /// 流程樹 啟動
    /// </summary>
    public const string FlowChartStart = "FlowChartStart";
    /// <summary>
    /// 流程树结束 参数1:流程树名称 参数2:true(胜利) false(失败)
    /// </summary>
    public const string FlowChartEnd = "FlowChartEnd";
    #endregion

    #region 场景
    public const string OnEnterLogin = "OnEnterLogin";
    /// <summary>
    /// 改变场景 
    /// </summary>
    public const string BegChgScene = "BegChgScene";
    public const string OnChangeScene = "OnChangeScene";
    public const string NavPathComplete = "NavPathComplete";
    #endregion

    #region 道具
    /// <summary>
    /// 更新道具
    /// </summary>
    public const string UpdateItemList = "UpdateItemList";
    /// <summary>
    /// 拾取装备
    /// </summary>
    public const string PickEquip = "PickEquip";
    /// <summary>
    /// 拾取掉落
    /// </summary>
    public const string PickDrop = "PickDrop";
    #endregion

    #region 副本
    /// <summary>
    /// 更新爬塔副本
    /// </summary>
    public const string UpdateCopyTowerData = "UpdateCopyTowerData";
    /// <summary>
    /// 跟新副本数据
    /// </summary>
    public const string UpdateCopyData = "UpdateCopyData";
    /// <summary>
    /// 更新副本星级
    /// </summary>
    public const string UpdateCopyStar = "UpdateCopyStar";
    /// <summary>
    /// 更新当前副本内信息
    /// </summary>
    public const string UpdateCopyInfo = "UpdateCopyInfo";
    public const string UpdateCopyCheerInfo = "UpdateCopyCheerInfo";
    public const string UpdateCopyExpInfo = "UpdateCopyExpInfo";
    public const string UpdateSuccessUpdate = "UpdateSuccessUpdate";
    public const string UpdateSuccessListUpdate = "UpdateSuccessListUpdate";
    public const string UpdateSuccessListEnd = "UpdateSuccessListEnd";
    public const string UpdateTowerReward = "UpdateTowerReward";
    public const string UpdateTowerRewardEnd = "UpdateTowerRewardEnd";
    public const string UpdateEndCopy = "UpdateEndCopy";
    public const string UpdateCopyClean = "UpdateCopyClean";
    public const string UpdateCopyCleanEnd = "UpdateCopyCleanEnd";
    public const string UpdateCopyCreate = "UpdateCopyCreate";
    #endregion

    #region NPC
    public const string PreloadNPC = "PreloadNPC";
    public const string CreateNPC = "CreateNPC";
    public const string ClickNPC = "ClickNPC";
    public const string InterruptInteraction = "InterruptInteraction";
    #endregion

    #region 复活系统
    public const string RefreshReviveData = "RefreshReviveData";
    public const string ReLife = "ReLife";
    public const string SelfDead = "SelfDead";
    #endregion

    #region 好友
    public const string SearchFriend = "SearchFriend";
    public const string AddFriend = "AddFriend";
    public const string AddBlack = "AddBlack";
    public const string AddRequest = "AddRequest";
    public const string DelFriend = "DelFriend";
    public const string AddRecommend = "AddRecommend";
    public const string AddRecommendEnd = "AddRecommendEnd";
    public const string DelRequestInfo = "DelRequestInfo";
    public const string DelBlackInfo = "DelBlackInfo";
    public const string UpdateFriendIsOnline = "UpdateFriendIsOnline";
    #endregion

    #region 任务
    public const string CleanAllMission = "CleanAllMission";
    public const string ReceiveMissionSuccess = "ReceiveMissionSuccess";
    public const string UpdateMissionEnd = "UpdateMissionEnd";
    public const string UpdateMission = "UpdateMission";
    public const string UpdateMissionTarget = "UpdateMissionTarget";
    public const string MissionCancel = "MissionCancel";
    public const string MissionFlowChartEnd = "MissionFlowChartEnd";
    public const string ExcuteMission = "ExcuteMission";
    public const string MssnEnd = "MssnEnd";
    public const string CompleteMission = "CompleteMission";
    public const string MissNavPathTrigger = "MissNavPathTrigger";
    #endregion

    #region Buff
    public const string DelBuff = "DelBuff";
    public const string AddBuff = "AddBuff";
    public const string BufValOnChange = "BufValOnChange";
    public const string BufValOnDel = "BufValOnDel";
    #endregion

    #region 组队
    public const string UpdateCopyTeam = "UpdateCopyTeam";
    public const string UpdateCopyTeamEnd = "UpdateCopyTeamEnd";
    public const string UpdateTeamInfoEnd = "UpdateTeamInfoEnd";
    public const string UpdateInviteTeam = "UpdateInviteTeam";
    public const string UpdateInviteReplyTeam = "UpdateInviteReplyTeam";
    public const string UpdateApplyReplyTeam = "UpdateApplyReplyTeam";
    public const string UpdateApplyTeam = "UpdateApplyTeam";
    public const string UpdateLeaveTeam = "UpdateLeaveTeam";
    public const string UpdateTeamInfo = "UpdateTeamInfo";
    public const string UpdateTeamRoleInfo = "UpdateTeamRoleInfo";
    public const string DelTeamRoleInfo = "DelTeamRoleInfo";
    public const string UpdateApplyTeamRoleInfo = "UpdateApplyTeamRoleInfo";
    public const string DelApplyTEamRoleInfo = "DelApplyTEamRoleInfo";
    public const string UpdateTeamCaptain = "UpdateTeamCaptain";
    public const string UpdateJoinCopyTeamReady = "UpdateJoinCopyTeamReady";
    #endregion

    #region 开启系统
    public const string OpenSystem = "OpenSystem";
    public const string OpenSystemEnd = "OpenSystemEnd";
    #endregion

    #region 动画
    public const string StartPlayAnim = "StartPlayAnim";
    public const string AllAnimFinish = "AllAnimFinish";
    #endregion

    #region 排行榜
    public const string UpdateRank = "UpdateRank";
    public const string UpdateRankParams = "UpdateRankParams";
    public const string UpdateRankEnd = "UpdateRankEnd";
    #endregion

    #region Boss
    public const string BossTie = "BossTie";
    public const string MonsterExtra = "MonsterExtra";
    public const string BossBelonger = "BossBelonger";
    public const string BossBlood = "BossBlood";
    #endregion
    #region 复活
    public const string FamilyRelife = "FamilyRelife";
    public const string UnitRevive = "UnitRevive";
    #endregion

    #region 1v1
    public const string RespSoloInfo = "RespSoloInfo";
    public const string RespSoloMatch = "RespSoloMatch";
    public const string RespSoloMSucc = "RespSoloMSucc";
    public const string RespSoloDlyRwd = "RespSoloDlyRwd";
    public const string RespSoloEntRwd = "RespSoloEntRwd";
    public const string RespSoloRank = "RespSoloRank";
    public const string RespSoloResult = "RespSoloResult";
    public const string RespSoloEntTime = "RespSoloEntTime";
    #endregion

    #region 离线竞技
    public const string ChallengeRole = "ChallengeRole";
    public const string AddOffLUnit = "AddOffLUnit";
    public const string ChangeOffLInfo = "ChangeOffLInfo";
    public const string EGToCSharp = "EGToCSharp";
    #endregion
    #region 离线时间改变
    public const string OfflFTimeChange = "OfflFTimeChange";
    #endregion
    #region 重连
    public const string DataClear = "DataClear";
    #endregion

    #region 帮派战
    public const string OccupPlayerEnter = "OccupPlayerEnter"; //角色进入占领点
    public const string OccupPlayerExit = "OccupPlayerExit"; //角色离开占领点
    #endregion

    #region 挂机
    /// <summary>
    /// 挂机点挂机
    /// </summary>
    public const string HgupPointHgup = "HgupPointHgup";
    #endregion

    #region 防沉迷
    /// <summary>
    /// 防沉迷
    /// </summary>
    public const string AntiIndulge = "AntiIndulge";
    #endregion
    #endregion
    #region 属性

    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法

    #endregion
}