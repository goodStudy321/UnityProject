--// 道庭系统管理器 

FamilyMgr = Super:New{Name = "FamilyMgr"}

--// 创建道庭等级限制
CREATE_FAMILY_LV = 0;
--// 创建道庭元宝限制
CREATE_FAMILY_MON = 0;
--// 最大日志数量
MAX_LOG_NUM = 50;

local mgrPre = {};
local iLog = iTrace.eLog;
local iError = iTrace.Error;
local eError = iTrace.eError;
local ET = EventMgr.Trigger;

FamilyMgr.autoApplying = false;
FamilyMgr.autoApplyShowTip = false;

--// 大红点状态有变化才触发
FamilyMgr.eRed = Event();
FamilyMgr.eUpdateRedPack = Event();

--// 初始化
function FamilyMgr:Init()

	if mgrPre.init ~= nil and mgrPre.init == true then
 		return;
	end
	 
	--// 帮派等级配置
	mgrPre.lvCfg = FamilyLvCfg;

 	--print("LY : UIWingModule create !!! ");
 	iLog("LY", " FamilyMgr create !!! ");
 	mgrPre.init = false;

 	--// 是否拥有帮派
 	mgrPre.hasFamily = false;
 	--// 当前帮派数据结构（协议结构）
 	mgrPre.p_family = nil;
 	--// 当前帮派数据结构（使用结构）
	mgrPre.familyData = {};
	--// 道庭技能初始化信息
	mgrPre.skillInitInfos = nil;
	--// 道庭技能解锁Id列表
	mgrPre.familyData.ulSkillList = nil;
	--// 道庭技能当前信息
	mgrPre.familyData.skillCurInfos = nil;
 	--// 当前自我成员数据
 	mgrPre.familyMemberData = nil;
 	--// 道庭简介信息列表
	mgrPre.familyBriefs = nil;
	--// 道庭仓库宝箱数据列表
	mgrPre.boxDataList = nil;
	--// 道庭个人活跃度
	mgrPre.selfActivity = 0;
	--// 帮派个人贡献(捐献、兑换装备)
	mgrPre.selfIntegral = 0;
	--// 是否获取每日奖励
	mgrPre.familyData.getReward = false;
	--// 
	mgrPre.gGetReward = false;
	--// 
	mgrPre.sendBoxIndexMap = {};

	-- --// 兽粮
	-- mgrPre.familyData.grain = -1;
	-- --// Boss开启次数
	-- mgrPre.familyData.bossCount = -1;

 	--// 帮派列表范围最小值
 	mgrPre.briefMin = 0;
 	--// 帮派列表范围最大值
	mgrPre.briefMax = 0;
	--// 所有帮派数量
	mgrPre.briefNum = 0;

 	--// 点击请求更改帮派设置
	mgrPre.clickRepConfig = false;
	
	--// 技能初始化信息
	mgrPre.skillInitInfos = self:CalSkillInitInfo();

	--// 红包更新
	-- self.eUpdateRedPack = Event();
	self.lookAtRP = false;
	self.checkRP = false;
	
	self:AddLsnr();

	--// 期待打开道庭界面
	mgrPre.willOpenFamilyWnd = false;
 	mgrPre.init = true;
end

--// 添加监听
function FamilyMgr:AddLsnr()

	--// 创建帮派返回
	ProtoLsnr.AddByName("m_family_create_toc", self.RespCreateFamily, self);
	--// 邀请某人加入帮派返回
	ProtoLsnr.AddByName("m_family_invite_toc", self.RespFamilyInvite, self);
	--// 邀请者同意or拒绝返回
	ProtoLsnr.AddByName("m_family_invite_reply_toc", self.RespFamilyInviteReply, self);
	--// 申请加入某个道庭返回
	ProtoLsnr.AddByName("m_family_apply_toc", self.RespFamilyApply, self);
	--// 回应申请加入某个道庭返回
	ProtoLsnr.AddByName("m_family_apply_reply_toc", self.RespFamilyApplyReply, self);
	--// 调整职位返回
	ProtoLsnr.AddByName("m_family_admin_toc", self.RespFamilyAdmin, self);
	--// 开除成员返回
	ProtoLsnr.AddByName("m_family_kick_toc", self.RespFamilyKick, self);
	--// 离开帮派返回
	ProtoLsnr.AddByName("m_family_leave_toc", self.RespFamilyLeave, self);
	--// 修改帮派设置返回
	ProtoLsnr.AddByName("m_family_config_toc", self.RespFamilyConfig, self);
	--// 帮派信息，上线推送
	ProtoLsnr.AddByName("m_family_info_toc", self.RespFamilyInfo, self);
	--// 帮派信息更新推送
	ProtoLsnr.AddByName("m_family_info_update_toc", self.RespFamilyInfoUpdate, self);
	--// 帮派成员加入、更新、退出返回
	ProtoLsnr.AddByName("m_family_member_update_toc", self.RespFamilyMemberUpdate, self);
	--// 帮派申请新加、更新、删除返回
	ProtoLsnr.AddByName("m_family_apply_update_toc", self.RespFamilyApplyUpdate, self);
	--// 获取帮派信息返回
	ProtoLsnr.AddByName("m_family_brief_toc", self.RespFamilyBrief, self);
	--// 帮派仓库返回
	ProtoLsnr.AddByName("m_family_depot_update_toc", self.RespFamilyDepotUpdate, self);
	--// 捐献装备返回
	ProtoLsnr.AddByName("m_family_donate_toc", self.RespFamilyIntegral, self);
	--// 删除装备返回
	ProtoLsnr.AddByName("m_family_del_depot_toc", self.RespFamilyDelDepot, self);
	--// 兑换装备返回
	ProtoLsnr.AddByName("m_family_exchange_depot_toc", self.RespFamilyExcDonate, self);
	--// 新增日志返回
	ProtoLsnr.AddByName("m_family_depot_log_update_toc", self.RespFamilyDepotLog, self);
	--// 帮派技能信息返回
	ProtoLsnr.AddByName("m_family_skill_toc", self.RespFamilySkill, self);
	--// 道庭宝箱数据更新
	ProtoLsnr.AddByName("m_family_box_update_toc", self.RespFamilyBoxData, self);
	--// 道庭开箱子返回
	ProtoLsnr.AddByName("m_family_box_open_toc", self.RespFamilyBoxOpen, self);

	--// 每日奖励推送
	ProtoLsnr.AddByName("m_family_day_reward_info_toc", self.RespRewardInfo, self);
	--// 获取奖励返回
	ProtoLsnr.AddByName("m_family_day_reward_toc", self.RespGetReward, self);
	

	ProtoLsnr.AddByName("m_family_give_red_packet_toc", self.RespGiveRedPacket, self);
	ProtoLsnr.AddByName("m_family_get_red_packet_toc", self.RespGetRedPacket, self);
	ProtoLsnr.AddByName("m_family_see_red_packet_toc", self.RespSeeRedPacket, self);
	ProtoLsnr.AddByName("m_family_new_red_packet_toc", self.RespNewRedPacket, self);
	ProtoLsnr.AddByName("m_family_red_packet_overdue_toc", self.RespRedPacketOverdue, self);
	--// 个人发送红包
	ProtoLsnr.AddByName("m_family_red_packet_received_toc", self.RespNewGiveRedPacket, self);
	--// 领取列表刷新
	ProtoLsnr.AddByName("m_family_red_packet_content_toc", self.RespGetRedPList, self);

	--// 红包记录部分
	ProtoLsnr.AddByName("m_family_red_packet_log_toc", self.RespNewRedPRecord, self);
	ProtoLsnr.AddByName("m_family_red_packet_log_delete_toc", self.RespDelAllRPRecord, self);
	
	RoleAssets.eUpAsset:Add(self.FamilyComChg, self);
end

function FamilyMgr:Clear()

	mgrPre.init = false;
	
	mgrPre.hasFamily = false;
	mgrPre.p_family = nil;
	mgrPre.familyData = {};
	mgrPre.boxDataList = nil;
	--mgrPre.skillInitInfos = nil;
	mgrPre.familyMemberData = nil;
	mgrPre.familyBriefs = nil;
	mgrPre.selfActivity = 0;
	mgrPre.gGetReward = false;
	
	mgrPre.briefMin = 0;
	mgrPre.briefMax = 0;
	mgrPre.briefNum = 0;
	mgrPre.sendBoxIndexMap = {};
	
	mgrPre.clickRepConfig = false;
	
	mgrPre.init = false;
end

function FamilyMgr:Dispose()
	RoleAssets.eUpAsset:Remove(self.FamilyComChg, self);
	self:Clear();
end

---------------------------------- 向服务器请求 ----------------------------------

--// 请求创建帮派
function FamilyMgr:ReqCreateFamily(familyName)
	local msg = ProtoPool.Get("m_family_create_tos");

	msg.family_name = familyName;

    ProtoMgr.Send(msg);
	--NetworkMgr.ReqCreateFamily(familyName);
	mgrPre.willOpenFamilyWnd = true;
end

--// 邀请加入帮派
function FamilyMgr:ReqFamilyInvite(roleId)
	local msg = ProtoPool.Get("m_family_invite_tos");

	msg.role_id = roleId;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyInvite(roleId);
end

--// 回复被邀请事件
function FamilyMgr:ReqFamilyInviteReply(opType, roleId, familyId)
	local msg = ProtoPool.Get("m_family_invite_reply_tos");

	msg.op_type = opType;
	msg.role_id = roleId;
	msg.family_id = familyId;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyInviteReply(opType, roleId, familyId);
end

--// 请求加入帮派
function FamilyMgr:ReqFamilyApply(familyId)
	if FamilyMgr:JoinFamily() == true then
		UITip.Log("已经加入帮派 ！！！ ");
		return;
	end

	local msg = ProtoPool.Get("m_family_apply_tos");

	msg.family_id = familyId;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyApply(familyId);
	mgrPre.willOpenFamilyWnd = true;
end

--// 请求帮派列表信息
function FamilyMgr:ReqFamilyBrief(from, to)
	mgrPre.briefMin = from;
	mgrPre.briefMax = to;

	local msg = ProtoPool.Get("m_family_brief_tos");

	msg.from = from;
	msg.to = to;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyBrief(from, to);
end

--// 请求回应申请加入帮派(1同意加入 2为拒绝加入)
function FamilyMgr:ReqFamilyApplyReply(type, ids)
	local msg = ProtoPool.Get("m_family_apply_reply_tos");

	msg.op_type = type;
	for i = 1, #ids do
		msg.role_ids:append(ids[i]);
	end

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyApplyReply(type, ids);
end

function FamilyMgr:AgreeFamilyApply(roleId)
	local tIdTbl = {};
	tIdTbl[#tIdTbl + 1] = roleId;
	self:ReqFamilyApplyReply(1, tIdTbl);
end

function FamilyMgr:RefuseFamilyApply(roleId)
	local tIdTbl = {};
	tIdTbl[#tIdTbl + 1] = roleId;
	self:ReqFamilyApplyReply(2, tIdTbl);
end

function FamilyMgr:AgreeAllFamilyApply()
	local ids = self:GetAllApplyMemberIds();
	if ids == nil or #ids <= 0 then
		return;
	end

	self:ReqFamilyApplyReply(1, ids);
end

function FamilyMgr:RefuseAllFamilyApply()
	local ids = self:GetAllApplyMemberIds();
	if ids == nil or #ids <= 0 then
		return;
	end

	self:ReqFamilyApplyReply(2, ids);
end

--// 请求更改玩家职位
function FamilyMgr:ReqFamilyAdmin(roleId, titleType)
	if titleType < 1 or titleType > 5 then
		iError("LY", "Family title type error !!! "..titleType);
		return;
	end

	local msg = ProtoPool.Get("m_family_admin_tos");

	msg.role_id = roleId;
	msg.new_title = titleType;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyAdmin(roleId, titleType);
end

--// 请求踢人
function FamilyMgr:ReqFamilyKick(roleId)
	local msg = ProtoPool.Get("m_family_kick_tos");

	msg.role_id = roleId;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyKick(roleId);
end

--// 请求离开帮派
function FamilyMgr:ReqFamilyLeave()
	local msg = ProtoPool.Get("m_family_leave_tos");
	ProtoMgr.Send(msg);	
	--NetworkMgr.ReqFamilyLeave();
end

--// 请求配置变更
function FamilyMgr:ReqFamilyConfig(list1Null, list2Null, key1Tbl, val1Tbl, key2Tbl, val2Tbl)
	local msg = ProtoPool.Get("m_family_config_tos");

	--local kvList = {};
	if list1Null == false then
		--msg.kv_list:Clear();
		for i = 1, #key1Tbl do
			local tKv = msg.kv_list:add();
			tKv.id = key1Tbl[i];
			tKv.val = val1Tbl[i];
			--kvList[#kvList + 1] = tKv;
		end
	end

	--local ksList = {};
	if list2Null == false then
		--msg.ks_list:Clear(;
		for i = 1, #key2Tbl do
			local tKs = msg.ks_list:add();
			tKs.id = key2Tbl[i];
			tKs.str = val2Tbl[i];
			--ksList[#ksList + 1] = tKs;
		end
	end

	--msg.kv_list = kvList;
	--msg.ks_list.Add = ksList;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyConfig(list1Null, list2Null, key1Tbl, val1Tbl, key2Tbl, val2Tbl);
	mgrPre.clickRepConfig = true;
end

--// 道庭技能升级
function FamilyMgr:ReqFamilySkillUpgrade(skillId)
	local msg = ProtoPool.Get("m_family_skill_tos");

	msg.skill_id = skillId;

    ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilySkillUpgrade(skillId);
end

--// 申请道庭仓库开宝箱
function FamilyMgr:ReqFamilyBoxOpen(boxList)
	if boxList == nil or #boxList <= 0 then
		return;
	end

	local msg = ProtoPool.Get("m_family_box_open_tos");

	for i = 1, #boxList do
		local tBox = msg.box:add();
		tBox.id = boxList[i].itemId;
		tBox.end_time = boxList[i].endTime;
		tBox.type = boxList[i].fromType;
		tBox.param = boxList[i].param;

		if #boxList == 1 then
			mgrPre.sendBoxIndexMap[#mgrPre.sendBoxIndexMap + 1] = boxList[i].posIndex;
		end
	end

	ProtoMgr.Send(msg);
end

--// 申请打开所有仓库宝箱
function FamilyMgr:ReqFamilyAllBoxOpen()
	if mgrPre.boxDataList == nil then
		return;
	end

	local openList = {};
	for i = 1, #mgrPre.boxDataList do
		if mgrPre.boxDataList[i].goods == nil then
			openList[#openList + 1] = mgrPre.boxDataList[i];
		end
	end

	if #openList <= 0 then
		ET("OpenFamilyBox");
		return;
	end

	FamilyMgr:ReqFamilyBoxOpen(openList);
end

--// 领取每日奖励
function FamilyMgr:ReqReward()
	local msg = ProtoPool.Get("m_family_day_reward_tos");

    ProtoMgr.Send(msg);
end

---------// 红包部分 

--// 申请发道庭红包
function FamilyMgr:ReqGiveRedPacket(rpType, pAmount, pContent, pPiece)
	local msg = ProtoPool.Get("m_family_give_red_packet_tos");

	--// 系统红包 - 1 V6自我创建红包 - 0
	msg.type = rpType;
	msg.amount = pAmount;
	msg.content = pContent;
	msg.piece = pPiece;

    ProtoMgr.Send(msg);
end

--// 申请领取道庭红包
function FamilyMgr:ReqGetRedPacket(packetId)
	local msg = ProtoPool.Get("m_family_get_red_packet_tos");

	msg.packet_id = packetId;

	ProtoMgr.Send(msg);
end

--// 查看道庭红包领取情况
function FamilyMgr:ReqSeeRedPacket(packetId)
	local msg = ProtoPool.Get("m_family_see_red_packet_tos");
	msg.packet_id = packetId;

	ProtoMgr.Send(msg);
end

--// 根据索引申请加入帮派
function FamilyMgr:ReqFamilyApplyByIndex(fBIndex)
	if mgrPre.hasFamily == true or mgrPre.p_family ~= nil then
		return;
	end

	if mgrPre.familyBriefs == nil then
		return;
	end

	if fBIndex <= 0 or fBIndex > #mgrPre.familyBriefs then
		return;
	end

	self:ReqFamilyApply(mgrPre.familyBriefs[fBIndex].familyId);
end

--// 道庭捐献
function FamilyMgr:ReqFamilyDonate(itemUIdTbl)
	if itemUIdTbl == nil or #itemUIdTbl <= 0 then
		return;
	end

	local msg = ProtoPool.Get("m_family_donate_tos");

	for i = 1, #itemUIdTbl do
		--local tId = msg.goods_list:add();
		--tId = itemUIdTbl[i];
		msg.goods_list:append(itemUIdTbl[i]);
	end
	--msg.goods_list = itemUIdTbl;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyDonate(itemUIdTbl);
end

--// 捐献删除
function FamilyMgr:ReqFamilyDelDepot(uidList)
	if uidList == nil or #uidList <= 0 then
		return;
	end

	local msg = ProtoPool.Get("m_family_del_depot_tos");

	for i = 1, #uidList do
		msg.goods_list:append(uidList[i]);
	end
	--msg.goods_list = uidList;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyDelDepot(uidList);
end

--// 道庭兑换
function FamilyMgr:ReqFamilyExcDepot(itemUId, number)
	if itemUId == nil or itemUId <= 0 then
		return;
	end

	local msg = ProtoPool.Get("m_family_exchange_depot_tos");

	msg.goods_id = itemUId;
	msg.num = number;

	ProtoMgr.Send(msg);
	--NetworkMgr.ReqFamilyExcDepot(itemUId, number);
end

-------------------------------------------------------------------------------

---------------------------------- 服务器推送返回 ----------------------------------

--// 推送玩家帮派信息
function FamilyMgr:RespFamilyInfo(msg)
	if msg == nil then
		FamilyMgr.eRed(false, 1, 0);
		FamilyMgr.eRed(false, 1, 2);
		FamilyMgr.eRed(false, 1, 4);
		FamilyMgr.eRed(false, 2, 0);
		FamilyMgr.eRed(false, 3, 1);
		FamilyMgr.eRed(false, 3, 2);
		FamilyMgr.eRed(false, 3, 3);
		FamilyMgr.eRed(false, 3, 4);
		FamilyMgr.eRed(false, 3, 5);
		FamilyMgr.eRed(false, 3, 6);
		mgrPre.hasFamily = false;
		FamilyMgr:ClearFamilyData();
		--ET("NewFamilyMemberData");
		UIMgr.Close("UIFamilyMainWnd");
		ET("QuitFamily");
		return;
	end

	--// 玩家没有帮派
	if msg.family_info == nil or msg.family_info.family_id == 0 then
		FamilyMgr.eRed(false, 1, 0);
		FamilyMgr.eRed(false, 1, 2);
		FamilyMgr.eRed(false, 1, 4);
		FamilyMgr.eRed(false, 2, 0);
		FamilyMgr.eRed(false, 3, 1);
		FamilyMgr.eRed(false, 3, 2);
		FamilyMgr.eRed(false, 3, 3);
		FamilyMgr.eRed(false, 3, 4);
		FamilyMgr.eRed(false, 3, 5);
		FamilyMgr.eRed(false, 3, 6);
		mgrPre.hasFamily = false;
		FamilyMgr:ClearFamilyData();
		--ET("NewFamilyMemberData");
		UIMgr.Close("UIFamilyMainWnd");
		ET("QuitFamily");
		return;
	end

	--mgrPre.hasFamily = true;
	mgrPre.p_family = msg.family_info;
	mgrPre.familyData = FamilyMgr:SwitchFamilyData(msg.family_info);
	local goodList = mgrPre.familyData.goodsList
	--// 填充仓库宝箱数据
	mgrPre.boxDataList = FamilyMgr:SwitchFamilyBoxData(msg.box_list);
	FamilyMgr:SortBox(mgrPre.boxDataList);
	mgrPre.familyMemberData = FamilyMgr:GetPlayFamilyInfo();
	mgrPre.selfIntegral = msg.integral;
	mgrPre.hasFamily = true;

	FamilyMgr:SortFamilyMember();
	FamilyMgr:SortApplyMember();

	if msg.skill_list ~= nil then
		FamilyMgr:RespFamilySkillList(msg.skill_list);
	end

	if FamilyMgr:GetNewBoxNumber() > 0 then
		FamilyMgr.eRed(true, 1, 4);
		FamilyMgr.eRed(true, 3, 1);
	else
		FamilyMgr.eRed(false, 1, 4);
		FamilyMgr.eRed(false, 3, 1);
	end

	if FamilyMgr:IsAnySkillCanUpdate() == true then
		FamilyMgr.eRed(true, 3, 1);
	else
		FamilyMgr.eRed(false, 3, 1);
	end

	ET("NewFamilyMemberData");

	if mgrPre.willOpenFamilyWnd == true then
		UIMgr.Open(UIFamilyMainWnd.Name)
		mgrPre.willOpenFamilyWnd = false;
	end
	FamilyMgr:RedTempDrop( )
end

--// 推送帮派更新信息
function FamilyMgr:RespFamilyInfoUpdate(msg)
	if msg == nil then
		return;
	end

	if msg.kv_list == nil then
		return;
	end

	for i = 1, #msg.kv_list do
		if msg.kv_list[i].id == 1 then
			mgrPre.familyData.rank = msg.kv_list[i].val;
		elseif msg.kv_list[i].id == 2 then
			mgrPre.familyData.Lv = msg.kv_list[i].val;
		elseif msg.kv_list[i].id == 3 then
			mgrPre.familyData.money = msg.kv_list[i].val;
		end
	end

	EventMgr.Trigger("UpdateFamilyData");
end

--// 收到创建道庭返回
function FamilyMgr:RespCreateFamily(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if msg.family_info == nil then
		iError("LY", "FamilyMgr:RespCreateFamily family info is null !!! ");
		return;
	end

	--mgrPre.hasFamily = true;
	mgrPre.p_family = msg.family_info;
	mgrPre.familyData = FamilyMgr:SwitchFamilyData(msg.family_info);
	--// 填充仓库宝箱数据
	mgrPre.boxDataList = FamilyMgr:SwitchFamilyBoxData(msg.box_list);
	FamilyMgr:SortBox(mgrPre.boxDataList);
	mgrPre.familyMemberData = FamilyMgr:GetPlayFamilyInfo();
	mgrPre.selfIntegral = msg.integral;
	mgrPre.hasFamily = true;

	FamilyMgr:SortFamilyMember();
	FamilyMgr:SortApplyMember();

	if msg.skill_list ~= nil then
		FamilyMgr:RespFamilySkillList(msg.skill_list);
	end

	if FamilyMgr:GetNewBoxNumber() > 0 then
		FamilyMgr.eRed(true, 1, 4);
		-- FamilyMgr.eRed(true, 3, 1);
	else
		FamilyMgr.eRed(false, 1, 4);
		-- FamilyMgr.eRed(false, 3, 1);
	end

	ET("NewFamilyMemberData");

	-- if mgrPre.willOpenFamilyWnd == true then
	-- 	UIMgr.Open(UIFamilyMainWnd.Name)
	-- 	mgrPre.willOpenFamilyWnd = false;
	-- end
end

--// 邀请某人加入帮派返回
function FamilyMgr:RespFamilyInvite(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end
	local inviteUID = msg.invite_role_id
	local inviteName = msg.invite_role_name
	local familyId = msg.invite_family_id
	local familyName = msg.invite_family_name

	self.InviteUID = inviteUID
	self.FamilyId = familyId

	inviteUID = tostring(inviteUID)
	local userId = tostring(User.MapData.UID)
	if inviteUID == userId then
		UITip.Error("邀请发送成功")
	else
		local str = string.format("%s玩家邀请你加入%s道庭",inviteName,familyName)
		MsgBox.ShowYesNo(str,self.OKBtn,self,"确定", self.NoBtn ,self, "取消")
	end
end

-- opType, roleId, familyId
function FamilyMgr:OKBtn()
	local opType = 1
	local inviteUID = self.InviteUID
	local familyId = self.FamilyId
	self:ReqFamilyInviteReply(opType,inviteUID,familyId)
end

function FamilyMgr:NoBtn()
	local opType = 2
	local inviteUID = self.InviteUID
	local familyId = self.FamilyId
	self:ReqFamilyInviteReply(opType,inviteUID,familyId)
end

--// 推送玩家信息更新
function FamilyMgr:RespFamilyMemberUpdate(msg)
	if msg == nil then
		return;
	end

	local deleteId = FamilyMgr.ChangeInt64Num(msg.del_member_id);
	--// 清除此Id用户
	if deleteId > 0 then
		--// 删除自己
		if mgrPre.familyId == deleteId then
			FamilyMgr:ClearFamilyData();
			UIMgr.Close("UIFamilyMainWnd");
			ET("QuitFamily");
			return;
		--// 删除其他玩家
		else
			FamilyMgr:DeleteMemberData(deleteId);
		end
	--// 更新玩家数据
	else
		FamilyMgr:RenewMemberData(msg.member);
	end
	ET("NewFamilyMemberData");
end

--// 帮派申请新加、更新、删除
function FamilyMgr:RespFamilyApplyUpdate(msg)
	if msg == nil then
		return;
	end

	local newData = false;
	if msg.apply ~= nil then
		newData = true;
	end

	local delNull = true;
	if msg.del_apply_ids ~= nil and #msg.del_apply_ids > 0 then
		delNull = false;
	end

	if delNull == false then
		local newApplyList = {}
		for a = 1, #mgrPre.familyData.applyList do
			local inDel = false;
			for b = 1, #msg.del_apply_ids do
				local tDelId = FamilyMgr.ChangeInt64Num(msg.del_apply_ids[b]);
				if mgrPre.familyData.applyList[a].roleId == tDelId then
					inDel = true;
					break;
				end
			end

			if inDel == false then
				newApplyList[#newApplyList + 1] = mgrPre.familyData.applyList[a];
			end
		end

		mgrPre.familyData.applyList = newApplyList;
	else
		if newData == true then
			local newApplyData = FamilyMgr:SwitchFamilyApplyData(msg.apply);
			local isNew = true;
			for i = 1, #mgrPre.familyData.applyList do
				if mgrPre.familyData.applyList[i].roleId == newApplyData.roleId then
					isNew = false;
					break;
				end
			end
			if isNew == true then
				mgrPre.familyData.applyList[#mgrPre.familyData.applyList + 1] = newApplyData;
			end
		end
	end
	
	FamilyMgr:SortApplyMember();

	EventMgr.Trigger("FamilyApplyListUpdate");

	if FamilyMgr:CanDealWithMember() == true then
		if mgrPre.familyData.applyList == nil or #mgrPre.familyData.applyList <=0 then
			FamilyMgr.eRed(false, 2, 0);
		else
			FamilyMgr.eRed(true, 2, 0);
		end
	end
end

--// 推送帮派信息列表
function FamilyMgr:RespFamilyBrief(msg)
	if msg == nil then
		return;
	end

	local isNull = false;
	if msg.briefs == nil or #msg.briefs <= 0 then
		isNull = true;
	end

	--// 没有信息返回
	if isNull == true then
		mgrPre.familyBriefs = nil;
		mgrPre.briefNum = 0;
		ET("NewFamilyBrief", nil);
		return;
	end

	mgrPre.briefNum = msg.all_num;
	local newDataTbl = {}

	for i = 1, #msg.briefs do
		newDataTbl[#newDataTbl + 1] = FamilyMgr:SwitchFamilyBriefData(msg.briefs[i]);
	end

	table.sort(newDataTbl, function(a, b)
		return a.rank < b.rank;
	end);

	mgrPre.familyBriefs = newDataTbl;
	ET("NewFamilyBrief", mgrPre.familyBriefs, mgrPre.briefNum);
end

--// 收到帮派申请动作返回
function FamilyMgr:RespFamilyApply(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		
		if FamilyMgr.autoApplying == true and msg.err_code == 22714002 then
			return;
		end

		if msg.err_code == 22724004 or msg.err_code == 22714003 or msg.err_code == 22736002 or msg.err_code == 22734004 then
			if FamilyMgr.autoApplyShowTip == true then
				return;
			else
				FamilyMgr.autoApplyShowTip = true;
			end
		end

		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	--iLog("LY", "申请发送成功 ! ");
	MsgBox.ShowYes("申请发送成功！");
end

--// 收到邀请加入帮派请求回应
function FamilyMgr:RespFamilyInviteReply(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	local inviteUID = self.InviteUID
	local cRoleId = FamilyMgr.ChangeInt64Num(msg.reply_role_id);
	if inviteUID == cRoleId then
		if msg.op_type == 1 then
			MsgBox.ShowYes(msg.reply_role_name.."同意了你的请求！");
		elseif msg.op_type == 2 then
			MsgBox.ShowYes(msg.reply_role_name.."拒绝了你的请求！");
		end
	end
end

--// 收到申请加入帮派请求回应
function FamilyMgr:RespFamilyApplyReply(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	local cRoleId = FamilyMgr.ChangeInt64Num(msg.reply_role_id);
	if cRoleId == FamilyMgr:GetPlayerRoleId() then
		return;
	end

	if msg.op_type == 1 then
		MsgBox.ShowYes(msg.reply_role_name.."同意了你的请求！");
	elseif msg.op_type == 2 then
		MsgBox.ShowYes(msg.reply_role_name.."拒绝了你的请求！");
	end
end

--// 收到帮派成员职位变更信息
function FamilyMgr:RespFamilyAdmin(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if mgrPre.familyData == nil then
		iError("LY", "Family data is null !!! ");
		return;
	end

	if mgrPre.familyData.members == nil then
		iError("LY", "No member in family !!! ");
		return;
	end

	local newRoleId = FamilyMgr.ChangeInt64Num(msg.role_id);
	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].roleId == newRoleId then
			mgrPre.familyData.members[i].title = msg.new_title;
			break;
		end
	end

	FamilyMgr:SortFamilyMember();
	mgrPre.familyMemberData = FamilyMgr:GetPlayFamilyInfo();

	--// 新的帮派成员数据
	ET("NewFamilyMemberData");
end

--// 收到帮派踢人信息
function FamilyMgr:RespFamilyKick(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if mgrPre.familyData == nil then
		iError("LY", "Family data is null !!! ");
		return;
	end

	if mgrPre.familyData.members == nil then
		iError("LY", "No member in family !!! ");
		return;
	end

	local newRoleId = FamilyMgr.ChangeInt64Num(msg.role_id);
	local newMemberTbl = {};
	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].roleId ~= newRoleId then
			newMemberTbl[#newMemberTbl + 1] = mgrPre.familyData.members[i];
		end
	end
	mgrPre.familyData.members = newMemberTbl;

	--// 新的帮派成员数据
	ET("NewFamilyMemberData");
end

--// 收到某人离开帮派信息
function FamilyMgr:RespFamilyLeave(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if mgrPre.familyData == nil then
		--iError("LY", "Family data is null !!! ");
		return;
	end

	if mgrPre.familyData.members == nil then
		--iError("LY", "No member in family !!! ");
		return;
	end

	local newRoleId = FamilyMgr.ChangeInt64Num(msg.role_id);

	if newRoleId == FamilyMgr:GetPlayerRoleId() then
		FamilyMgr.eRed(false, 1, 0);
		FamilyMgr.eRed(false, 1, 2);
		FamilyMgr.eRed(false, 1, 4);
		FamilyMgr.eRed(false, 2, 0);
		FamilyMgr.eRed(false, 3, 1);
		FamilyMgr.eRed(false, 3, 2);
		FamilyMgr.eRed(false, 3, 3);
		FamilyMgr.eRed(false, 3, 4);
		FamilyMgr.eRed(false, 3, 5);
		FamilyMgr.eRed(false, 3, 6);

		FamilyMgr:ClearFamilyData();
		UIMgr.Close("UIFamilyMainWnd");
		--ET("NewFamilyMemberData");
		ET("QuitFamily");
		return;
	end

	local newMemberTbl = {};
	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].roleId ~= newRoleId then
			newMemberTbl[#newMemberTbl + 1] = mgrPre.familyData.members[i];
		end
	end
	mgrPre.familyData.members = newMemberTbl;

	--// 新的帮派成员数据
	ET("NewFamilyMemberData");
end

--// 收到帮派配置更改信息
function FamilyMgr:RespFamilyConfig(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if msg.kv_list ~= nil then
		for i = 1, #msg.kv_list do
			--// 是否可以直接加入帮派
			if msg.kv_list[i].id == 1 then
				if msg.kv_list[i].val == 0 then
					mgrPre.familyData.isDirectJoin = false;
				else
					mgrPre.familyData.isDirectJoin = true;
				end
			end
			--// 限制等级
			if msg.kv_list[i].id == 2 then
				mgrPre.familyData.limitLevel = msg.kv_list[i].val;
			end
			--// 限制战力
			if msg.kv_list[i].id == 3 then
				mgrPre.familyData.limitPower = msg.kv_list[i].val;
			end
		end

		ET("FamilyConfigChange");
	end

	if msg.ks_list ~= nil then
		for i = 1, #msg.ks_list do
			if msg.ks_list[i].id == 101 then
				mgrPre.familyData.notice = msg.ks_list[i].str;
				ET("FamilyNoticeChange");
			end
			if msg.ks_list[i].id == 102 then
				mgrPre.familyData.Name = msg.ks_list[i].str;
				ET("FamilyNameChange");
			end
		end
	end

	if mgrPre.clickRepConfig == true then
		MsgBox.ShowYes("道庭配置修改成功！");
		mgrPre.clickRepConfig = false;
	end
end

--// 道庭解锁技能更新
function FamilyMgr:RespFamilySkillList(skillList)
	mgrPre.familyData.ulSkillList = {};
	for i = 1, #skillList do
		mgrPre.familyData.ulSkillList[#mgrPre.familyData.ulSkillList + 1] = skillList[i];
	end

	local inits = mgrPre.skillInitInfos;
	if inits == nil then
		return;
	end

	mgrPre.familyData.skillCurInfos = {};
	for a = 1, #inits do
		local ulSkills = mgrPre.familyData.ulSkillList;
		local hit = false;
		for b = 1,#ulSkills do
			local tpId = math.floor(ulSkills[b] / 1000);
			if tpId == inits[a].preId then
				local newData = {};
				newData.baseInfo = inits[a];
				newData.cfgInfo = FamilySkill[tostring(ulSkills[b])];
				if mgrPre.familyData.Lv >= newData.baseInfo.ulLv then
					newData.unlock = true;
				else
					newData.unlock = false;
				end
				newData.lv = math.floor(ulSkills[b] % 1000);

				mgrPre.familyData.skillCurInfos[#mgrPre.familyData.skillCurInfos + 1] = newData;
				hit = true;
				break;
			end
		end

		if hit == false then
			local newData = {};
			newData.baseInfo = inits[a];
			newData.cfgInfo = FamilySkill[tostring(inits[a].id)];
			if mgrPre.familyData.Lv >= newData.baseInfo.ulLv then
				newData.unlock = true;
			else
				newData.unlock = false;
			end
			newData.lv = 0;

			mgrPre.familyData.skillCurInfos[#mgrPre.familyData.skillCurInfos + 1] = newData;
		end
	end

	ET("FamilySkillChange");

	if self:IsAnySkillCanUpdate() == true then
		FamilyMgr.eRed(true, 3, 1);
	else
		FamilyMgr.eRed(false, 3, 1);
	end

	FamilyBossMgr:UpAction()--更新道庭Boss红点
	FamilyMissionMgr:UpAction()--更新道庭任务红点
end

--// 道庭解锁技能更新
function FamilyMgr:RespFamilySkill(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));

		if self:IsAnySkillCanUpdate() == true then
			FamilyMgr.eRed(true, 3, 1);
		else
			FamilyMgr.eRed(false, 3, 1);
		end
		return;
	end

	self:RespFamilySkillList(msg.skill_list);
end

--// 收到道庭宝箱更新
function FamilyMgr:RespFamilyBoxData(msg)
	if msg == nil or msg.box_list == nil or #msg.box_list <= 0 then
		return;
	end

	FamilyMgr:ClearGetFamilyBox();

	if mgrPre.boxDataList == nil then
		mgrPre.boxDataList = FamilyMgr:SwitchFamilyBoxData(msg.box_list);
		return;
	end

	for a = 1, #msg.box_list do
		local sData = {};
		sData.itemId = msg.box_list[a].id;
		sData.endTime = msg.box_list[a].end_time;
		sData.fromType = msg.box_list[a].type;
		sData.param = msg.box_list[a].param;
		sData.goods = nil;
		sData.posIndex = 0;

		mgrPre.boxDataList[#mgrPre.boxDataList + 1] = sData;
	end

	FamilyMgr:SortBox(mgrPre.boxDataList);
	if FamilyMgr:GetNewBoxNumber() > 0 then
		FamilyMgr.eRed(true, 1, 4);
		-- FamilyMgr.eRed(true, 3, 1);
	else
		FamilyMgr.eRed(false, 1, 4);
		-- FamilyMgr.eRed(false, 3, 1);
	end
	ET("NewBoxData");
end

--// 收到道庭开箱子返回
function FamilyMgr:RespFamilyBoxOpen(msg)
	if msg == nil or mgrPre.boxDataList == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	--FamilyMgr:ClearGetFamilyBox();

	for a = 1, #msg.box do
		local oBox = msg.box[a];
		for b = 1, #mgrPre.boxDataList do
			local tBData = mgrPre.boxDataList[b];
			if tBData.goods == nil and oBox.id == tBData.itemId and oBox.end_time == tBData.endTime and oBox.type == tBData.fromType and oBox.param == tBData.param then
				if #msg.box > 1 then
					tBData.goods = FamilyMgr:SwitchGoodsToItemTbl(msg.goods[a]);
					break;
				else
					if tBData.posIndex == mgrPre.sendBoxIndexMap[1] then
						tBData.goods = FamilyMgr:SwitchGoodsToItemTbl(msg.goods[a]);
						table.remove(mgrPre.sendBoxIndexMap, 1);
						break;
					end
				end
			end
		end
	end

	if FamilyMgr:GetNewBoxNumber() > 0 then
		FamilyMgr.eRed(true, 1, 4);
		-- FamilyMgr.eRed(true, 3, 1);
	else
		FamilyMgr.eRed(false, 1, 4);
		-- FamilyMgr.eRed(false, 3, 1);
	end
	ET("OpenFamilyBox");
end

--// 每日奖励信息推送
function FamilyMgr:RespRewardInfo(msg)
	if msg == nil or msg.reward == nil then
		return;
	end

	mgrPre.familyData.getReward = msg.reward;
	mgrPre.gGetReward = msg.reward;
	FamilyMgr.eRed(mgrPre.familyData.getReward == false, 1, 0);
end

--// 领取每日奖励返回
function FamilyMgr:RespGetReward(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));

		mgrPre.familyData.getReward = true;
		mgrPre.gGetReward = true;
		FamilyMgr.eRed(mgrPre.familyData.getReward == false, 1, 0);
		return;
	end

	mgrPre.familyData.getReward = true;
	mgrPre.gGetReward = true;
	FamilyMgr.eRed(mgrPre.familyData.getReward == false, 1, 0);

	ET("RewardChange");
end


---------// 红包部分 

--// 申请发道庭红包返回
function FamilyMgr:RespGiveRedPacket(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if msg.type == 1 then
		local selfFData = FamilyMgr:GetPlayFamilyInfo();
		if selfFData ~= nil then
			local hasDel = false;
			local newRPTbl = {};
			for i = 1, #selfFData.redPacketTbl do
				if hasDel == false and selfFData.redPacketTbl[i].amount == msg.amount then
					hasDel = true;
				else
					newRPTbl[#newRPTbl + 1] = selfFData.redPacketTbl[i];
				end
			end

			selfFData.redPacketTbl = newRPTbl;
			if self.lookAtRP == false then
				self.checkRP = false;
			end
			FamilyMgr.eUpdateRedPack();
			EventMgr.Trigger("NewGetRedPacket");
		end
	end

	--// 触发发红包成功事件
	--ET("NewFTDInfo");
	UITip.Log("红包发送成功");
end

--// 申请收道庭红包返回
function FamilyMgr:RespGetRedPacket(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	--// 红包金额
	--msg.gold

	local getRedP = self:GetRedPacketById(msg.packet_id);
	if getRedP == nil then
		eError("LY", "Red packet miss !!! packet_id : "..msg.packet_id);
		return;
	end

	getRedP.sentNum = getRedP.sentNum + 1;
	self:ReqSeeRedPacket(msg.packet_id);

	if self.lookAtRP == false then
		self.checkRP = false;
	end
	FamilyMgr.eUpdateRedPack();
	EventMgr.Trigger("NewGetRedPacket");
end

--// 查看道庭红包返回
function FamilyMgr:RespSeeRedPacket(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if mgrPre == nil or mgrPre.familyData == nil or mgrPre.familyData.redPacketTbl then
		return;
	end

	--// 红包领取显示数据
	local tempShowRP = {};
	for i = 1, #msg.list do
		local tempData = self:SwitchRedPackerContentData(msg.list[i]);
		if tempData.roleId > 1 then
			tempShowRP[#tempShowRP + 1] = tempData;
		end
	end

	for i = 1, #mgrPre.familyData.redPacketTbl do
		if msg.id == mgrPre.familyData.redPacketTbl[i].id then
			mgrPre.familyData.redPacketTbl[i].contentTbl = tempShowRP;
			--mgrPre.familyData.redPacketTbl[i].sentNum = #tempShowRP;
			break;
		end
	end

	FamilyMgr.eUpdateRedPack();
	EventMgr.Trigger("NewRedPContList");
end

--// 领取道庭红包人员列表到达
function FamilyMgr:RespGetRedPList(msg)
	if msg == nil or msg.content == nil then
		return;
	end

	--// 红包领取显示数据
	local tempShowRP = {};
	for i = 1, #msg.content do
		local tempData = self:SwitchRedPackerContentData(msg.content[i]);
		if tempData.roleId > 1 then
			tempShowRP[#tempShowRP + 1] = tempData;
		end
	end

	for i = 1, #mgrPre.familyData.redPacketTbl do
		if msg.id == mgrPre.familyData.redPacketTbl[i].id then
			mgrPre.familyData.redPacketTbl[i].contentTbl = tempShowRP;
			mgrPre.familyData.redPacketTbl[i].sentNum = #tempShowRP;
			break;
		end
	end

	EventMgr.Trigger("NewRedPContList");
	--EventMgr.Trigger("NewGetRedPacket");
end

--// 道庭发新红包返回
function FamilyMgr:RespNewRedPacket(msg)
	if msg.red_packet == nil or mgrPre.familyData == nil then
		return;
	end

	local newRP = self:SwitchRedPackerData(msg.red_packet);
	if newRP == nil then
		return;
	end

	if mgrPre.familyData.redPacketTbl == nil then
		mgrPre.familyData.redPacketTbl = {};
	end

	for i = 1, #mgrPre.familyData.redPacketTbl do
		if mgrPre.familyData.redPacketTbl[i].id == newRP.id then
			iError("LY", "New red packet is exist !!! ");
			return;
		end
	end

	mgrPre.familyData.redPacketTbl[#mgrPre.familyData.redPacketTbl + 1] = newRP;

	self:DelSelfGiveRedPacket(newRP.id);

	--// 分发事件
	if self.lookAtRP == false then
		self.checkRP = false;
	end
	FamilyMgr.eUpdateRedPack();
	EventMgr.Trigger("NewGetRedPacket");
end

--// 道庭个人可发新红包
function FamilyMgr:RespNewGiveRedPacket(msg)
	if msg == nil or mgrPre.familyData == nil then
		return;
	end

	if FamilyMgr:JoinFamily() == false then
		return;
	end
	
	local selfFData = FamilyMgr:GetPlayFamilyInfo();
	if selfFData == nil then
		return;
	end

	selfFData.packetTimes = msg.times;
	if msg.amount == nil then
		return;
	end
	
	selfFData.redPacketTbl = {};
	for i = 1, #msg.amount do
		local newRP = FamilyMgr:MakeSelfRedPacket(msg.amount[i]);
		if newRP ~= nil then
			selfFData.redPacketTbl[#selfFData.redPacketTbl + 1] = newRP;
		end
	end

	--// 分发事件
	if self.lookAtRP == false then
		self.checkRP = false;
	end
	FamilyMgr.eUpdateRedPack();
	EventMgr.Trigger("NewGetRedPacket");
end

--// 道庭红包过期返回
--// 红包类型 1-道庭已发2-自我未发红包
function FamilyMgr:RespRedPacketOverdue(msg)
	--// 1-道庭已发
	if msg.type == 1 then

		local newRPTbl = {};

		for a = 1, #mgrPre.familyData.redPacketTbl do
			local isDel = false;
			for b = 1, #msg.packet_id do
				if mgrPre.familyData.redPacketTbl[a].id == msg.packet_id[b] then
					isDel = true;
					break;
				end
			end

			if isDel == false then
				newRPTbl[#newRPTbl + 1] = mgrPre.familyData.redPacketTbl[a];
			end
		end

		mgrPre.familyData.redPacketTbl = newRPTbl;

	--// 2-自我未发红包
	elseif msg.type == 2 then

		local newRPTbl = {};

		local selfMbData = FamilyMgr:GetPlayFamilyInfo();

		for a = 1, #selfMbData.redPacketTbl do
			local isDel = false;
			for b = 1, #msg.packet_id do
				if selfMbData.redPacketTbl[a].id == msg.packet_id[b] then
					isDel = true;
					break;
				end
			end

			if isDel == false then
				newRPTbl[#newRPTbl + 1] = selfMbData.redPacketTbl[a];
			end
		end

		selfMbData.redPacketTbl = newRPTbl;
	end

end

--// 收到更新红包记录
function FamilyMgr:RespNewRedPRecord(msg)
	if msg == nil or msg.log == nil then
		return;
	end

	--local rpLogTbl = mgrPre.familyData.redPacketLog;
	local rpLogTbl = {};
	for i = 1, #msg.log do
		rpLogTbl[#rpLogTbl + 1] = self:SwitchRedPacketLogData(msg.log[i]);
	end
	mgrPre.familyData.redPacketLog = rpLogTbl;

	--// 分发事件
	EventMgr.Trigger("NewRedPacketRecord");
end

--// 删除所以红包记录
function FamilyMgr:RespDelAllRPRecord()
	mgrPre.familyData.redPacketLog = {};

	--// 分发事件
	EventMgr.Trigger("NewRedPacketRecord");
end

--// 帮派仓库更新
function FamilyMgr:RespFamilyDepotUpdate(msg)
	if msg == nil then
		return;
	end

	--// 有删除列表
	if msg.del_goods ~= nil and #msg.del_goods > 0 then
		local newGoodsList = {};
		for a = 1, #mgrPre.familyData.goodsList do
			local goodData = mgrPre.familyData.goodsList[a];
			local isDel = false;
			for b = 1, #msg.del_goods do
				local delId = FamilyMgr.ChangeInt64Num(msg.del_goods[b]);
				if goodData.id == delId then
					isDel = true;
					break;
				end
			end
			if isDel == false then
				newGoodsList[#newGoodsList + 1] = goodData;
			end
		end
		mgrPre.familyData.goodsList = newGoodsList;
	end
	--// 有更新列表
	if msg.update_goods ~= nil and #msg.update_goods > 0 then
		for a = 1, #msg.update_goods do
			local newGoodData = msg.update_goods[a];
			local isNew = true;
			for b = 1, #mgrPre.familyData.goodsList do
				if mgrPre.familyData.goodsList[b].id == newGoodData.id then
					mgrPre.familyData.goodsList[b] = FamilyMgr:SwitchFamilyGoodsData(newGoodData);
					isNew = false;
					break;
				end
			end
			if isNew == true then
				mgrPre.familyData.goodsList[#mgrPre.familyData.goodsList + 1] = FamilyMgr:SwitchFamilyGoodsData(newGoodData);
			end
		end
	end

	ET("NewFamilyDepotData");
end

--// 道庭捐献贡献返回
function FamilyMgr:RespFamilyIntegral(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	mgrPre.selfIntegral = msg.integral;
	ET("NewIntegral");
end

--// 删除装备返回
function FamilyMgr:RespFamilyDelDepot(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	ET("RespFamilyDelDonate");
end

--// 道庭兑换返回
function FamilyMgr:RespFamilyExcDonate(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	mgrPre.selfIntegral = msg.integral;
	UITip.Log("兑换成功");
	ET("NewIntegral");
end

--// 道庭仓库日志更新
function FamilyMgr:RespFamilyDepotLog(msg)
	if msg == nil then
		return;
	end

	local logList = msg.depot_log;

	if logList == nil or #logList <= 0 then
		iError("LY", "logList is null !!! ");
		return;
	end

	if mgrPre.familyData == nil then
		iError("LY", "No family data !!! ");
		return;
	end

	local newDatas = {};
	for i = 1, #logList do
		local log = {};
		log.roleName = logList[i].role_name;
		log.type = logList[i].type;
		log.good = FamilyMgr:SwitchFamilyGoodsData(logList[i].goods);
		newDatas[#newDatas + 1] = log;
	end

	if mgrPre.familyData.depotLogs == nil then
		mgrPre.familyData.depotLogs = {};
	end

	local totalNum = #mgrPre.familyData.depotLogs + #newDatas;
	local dealTbl = mgrPre.familyData.depotLogs;
	if totalNum > MAX_LOG_NUM then
		local newTbl = {};
		for i = totalNum - MAX_LOG_NUM + 1, #dealTbl do
			newTbl[#newTbl + 1] = dealTbl[i];
		end
		dealTbl = newTbl;
	end

	-- for i = 1, #newDatas do
	-- 	dealTbl[#dealTbl + 1] = newDatas[i];
	-- end
	-- mgrPre.familyData.depotLogs = dealTbl;

	local newDealTbl = {};
	for i = 1, #newDatas do
		newDealTbl[#newDealTbl + 1] = newDatas[#newDatas - i + 1];
	end
	for i = 1, #dealTbl do
		newDealTbl[#newDealTbl + 1] = dealTbl[i];
	end

	mgrPre.familyData.depotLogs = newDealTbl;

	ET("NewDepotLog");
end

-------------------------------------------------------------------------------

---------------------------------- 监听函数部分 ----------------------------------



-------------------------------------------------------------------------------

---------------------------------- 处理数据部分 ----------------------------------

--// 清除帮派数据
function FamilyMgr:ClearFamilyData()
	mgrPre.hasFamily = false;
	mgrPre.p_family = nil;
	mgrPre.familyData = nil;
end

--// 转换帮派成员数据
function FamilyMgr:SwitchFamilyMemberData(oriData)
	local memberData = {};

	--// 角色Id
	memberData.roleId = FamilyMgr.ChangeInt64Num(oriData.role_id);
	--// 角色名称
	memberData.roleName = oriData.role_name;
	--// 角色等级
	memberData.roleLv = oriData.role_level;
	--// 角色职业
	memberData.category = oriData.category;
	--// 角色职位
	memberData.title = oriData.title;
	--// 角色性别
	memberData.sex = oriData.sex;
	--// 神殿俸禄是否领取
	memberData.salary = oriData.salary;
	--// 帮派永久活跃度(退出道庭清零)
	memberData.active = oriData.integral;

	--// 今日发送红包数量
	memberData.packetTimes = 0;
	--// 道庭红包，个人未发
	memberData.redPacketTbl = {};
	if mgrPre.hasFamily == true and self:GetPlayerRoleId() == memberData.roleId then
		local selfFData = FamilyMgr:GetPlayFamilyInfo();
		if selfFData ~= nil then
			memberData.packetTimes = selfFData.packetTimes;
			memberData.redPacketTbl = selfFData.redPacketTbl;
		end
	end
	-- for i = 1, #oriData.red_packet do
	-- 	memberData.redPacketTbl[#memberData.redPacketTbl + 1] = FamilyMgr:SwitchRedPackerData(oriData.red_packet[i]);
	-- end

	--// 帮派活跃度(用于技能升级)
	memberData.integral = oriData.integral;
	--// 角色战力
	memberData.power = oriData.power;

	--// 是否在线
	memberData.isOnline = oriData.is_online;
	if memberData.roleId == self:GetPlayerRoleId() then
		memberData.isOnline = true;
	end

	--// 上次下线时间 时间戳
	memberData.offTime = oriData.last_offline_time;

	return memberData;
end

--// 转换申请加入数据
function FamilyMgr:SwitchFamilyApplyData(oriData)
	local applyData = {};

	--// 角色Id
	applyData.roleId = FamilyMgr.ChangeInt64Num(oriData.role_id);
	--// 角色名称
	applyData.roleName = oriData.role_name;
	--// 角色等级
	applyData.roleLv = oriData.role_level;
	--// 角色职业
	applyData.category = oriData.category;
	--// 角色性别
	applyData.sex = oriData.sex;
	--// 角色战力
	applyData.power = oriData.power;

	return applyData;
end

--// 转换道庭数据
function FamilyMgr:SwitchFamilyData(oriData)
	local familyData ={};

	--// 道庭Id
	familyData.Id = FamilyMgr.ChangeInt64Num(oriData.family_id);
	--// 道庭名称
	familyData.Name = oriData.family_name;
	--// 道庭等级
	familyData.Lv = oriData.level;
	--// 道庭资金
	familyData.money = oriData.money;
	--// 是否可以直接加入
	familyData.isDirectJoin = oriData.is_direct_join;
	--// 限制申请的等级
	familyData.limitLevel = oriData.limit_level;
	--// 限制申请的战力
	familyData.limitPower = oriData.limit_power;
	--// 排名
	familyData.rank = oriData.rank;
	--// 可领连胜奖励  id连胜排名  val连胜次数
	familyData.cv_reward=oriData.cv_reward;
	--//最大连胜次数   id连胜排名 val连胜次数
	familyData.max_cv=oriData.max_cv;
	--// 本周终结连胜  id连胜排名-0时为没有终结 val连胜次数
	familyData.end_cv=oriData.end_cv;
	--// 公告
	familyData.notice = oriData.notice;

	--// 会员列表
	familyData.members = {};
	if oriData.members ~= nil then
		for i = 1, #oriData.members do
			familyData.members[#familyData.members + 1] = self:SwitchFamilyMemberData(oriData.members[i]);
		end
	end

	--// 道庭红包Id
	familyData.redPacketId = oriData.packet_id;
	--// 道庭红包列表（可以领取的）
	familyData.redPacketTbl = {};
	for i = 1, #oriData.red_packet do
		local checkRP = self:SwitchRedPackerData(oriData.red_packet[i]);
		if checkRP ~= nil then
			familyData.redPacketTbl[#familyData.redPacketTbl + 1] = checkRP;
		end
	end

	--// 红包信息记录
	familyData.redPacketLog = {};
	for i = 1, #oriData.red_packet_log do
		familyData.redPacketLog[#familyData.redPacketLog + 1] = self:SwitchRedPacketLogData(oriData.red_packet_log[i]);
	end

	-- --兽粮
	-- familyData.grain = oriData.boss_grain;

	-- --Boss开启次数
	-- familyData.bossCount = oriData.boss_times;

	familyData.applyList = {};
	if oriData.apply_list ~= nil then
		for i = 1, #oriData.apply_list do
			familyData.applyList[#familyData.applyList + 1] = self:SwitchFamilyApplyData(oriData.apply_list[i]);
		end
	end

	familyData.goodsList = {};
	if oriData.depot ~= nil then
		for i = 1, #oriData.depot do
			familyData.goodsList[#familyData.goodsList + 1] = self:SwitchFamilyGoodsData(oriData.depot[i]);
		end
	end

	--// 日志
	familyData.depotLogs = {};
	if oriData.depot_log ~= nil then
		for i = 1, #oriData.depot_log do
			local log = {};
			log.roleName = oriData.depot_log[i].role_name;
			log.type = oriData.depot_log[i].type;
			log.good = self:SwitchFamilyGoodsData(oriData.depot_log[i].goods);
			familyData.depotLogs[#familyData.depotLogs + 1] = log;
		end
	end

	return familyData;
end

--// 转换道庭仓库宝箱数据
function FamilyMgr:SwitchFamilyBoxData(oriDataList)
	if oriDataList == nil then
		return nil;
	end

	local retList = {}
	for a = 1, #oriDataList do
		local sData = {};
		sData.itemId = oriDataList[a].id;
		sData.endTime = oriDataList[a].end_time;
		sData.fromType = oriDataList[a].type;
		sData.param = oriDataList[a].param;
		sData.goods = nil;
		sData.posIndex = 0;

		retList[#retList + 1] = sData;
	end

	return retList;
end

--// 转换市场物品到背包物品格式
function FamilyMgr:SwitchGoodsToItemTbl(oriData)
	local goodData = {};

	goodData.id = oriData.id;
	--道具表id
	goodData.type_id = oriData.type_id;
	--是否绑定
	goodData.bind = false;
	--数量
	goodData.num = oriData.num;

	--卓越属性
	goodData.eDic = {};
	for i = 1, #oriData.excellent_list do
		goodData.eDic[oriData.excellent_list[i].id] = oriData.excellent_list[i].val;
	end

	--翅膀
	goodData.wing_id = nil;
	goodData.bList = {};
	goodData.lDic = {};
	
	--goodData.startTime = oriData.start_time; --开始生效的时间
	--goodData.endTime = oriData.end_time;  --now>endTime 过期

	return goodData;
end

--// 转换帮派简介数据
function FamilyMgr:SwitchFamilyBriefData(oriData)
	local briefData = {};

	briefData.familyId = FamilyMgr.ChangeInt64Num(oriData.family_id);
	briefData.familyName = oriData.family_name;
	briefData.familyLv = oriData.level;
	briefData.memberNum = oriData.num;
	briefData.ownerId = FamilyMgr.ChangeInt64Num(oriData.owner_id);
	briefData.ownerName = oriData.owner_name;
	briefData.power = oriData.power;
	briefData.rank = oriData.rank;

	return briefData;
end

--// 填充个人红包数据
function FamilyMgr:MakeSelfRedPacket(amount)
	local selfData = self:GetPlayFamilyInfo();
	if selfData == nil then
		iError("LY", "FamilyMgr:MakeSelfRedPacket no self member data !!! ");
		return nil;
	end

	local rpData = {};

	--// 红包ID
	rpData.id = 0;
	--// 发放玩家名
	rpData.senderName = selfData.roleName;
	--// 玩家头像（暂时用职业区分）
	rpData.icon = selfData.category;
	if rpData.icon < 1 then
		rpData.icon = 1;
	end
	if rpData.icon > 2 then
		rpData.icon = 2
	end
	--// 内容
	rpData.content = "";
	--// 发送时间 0-未发
	rpData.time = 0;
	--// 金额
	rpData.amount = amount;
	--// 份数
	rpData.piece = 0;
	--// 元宝种类  2 - 元宝 3-绑定元宝
	rpData.goldType = 3;
	--// 已经发出份数
	rpData.sentNum = 0;
	--// 领取红包人员列表
	rpData.contentTbl = {};

	return rpData;
end

--// 转换帮派红包数据
function FamilyMgr:SwitchRedPackerData(oriData)
	if oriData.role_list ~= nil and #oriData.role_list > 0 then
		local selfRP = false;
		local selfRoleId = FamilyMgr:GetPlayerRoleId();

		for i = 1, #oriData.role_list do
			local cId = FamilyMgr.ChangeInt64Num(oriData.role_list[i]);
			if cId == selfRoleId then
				selfRP = true;
				break;
			end
		end

		if selfRP == false then
			return nil;
		end
	end

	local rpData = {};

	--// 红包ID
	rpData.id = FamilyMgr.ChangeInt64Num(oriData.id);
	--// 发放玩家名
	rpData.senderName = oriData.sender_name;
	--// 玩家头像（暂时用职业区分）
	rpData.icon = oriData.icon;
	--// 内容
	rpData.content = oriData.content;
	--// 发送时间 0-未发
	rpData.time = oriData.time;
	--// 金额
	rpData.amount = oriData.amount;
	--// 份数
	rpData.piece = oriData.piece;
	--// 元宝种类  2 - 元宝 3-绑定元宝
	rpData.goldType = oriData.bind;
	--// 已经发出份数
	rpData.sentNum = oriData.sent_num;
	--// 领取红包人员列表
	rpData.contentTbl = {};

	for i = 1, #oriData.packet_list do
		local contData = FamilyMgr:SwitchRedPackerContentData(oriData.packet_list[i]);
		if contData.roleId > 1 then
			rpData.contentTbl[#rpData.contentTbl + 1] = contData;
		end
		--rpData.contentTbl[#rpData.contentTbl + 1] = contData;
	end

	return rpData;
end

--// 转换红包领取人员数据
function FamilyMgr:SwitchRedPackerContentData(oriData)
	local rpcData = {};

	--// id
	rpcData.id = oriData.id;
	--// 人员名字
	rpcData.name = oriData.name;
	--// RoleID  未领为-1
	rpcData.roleId = FamilyMgr.ChangeInt64Num(oriData.role_id);
	--// 金额
	rpcData.amount = oriData.amount;
	--// 头像信息（现在是职业Id）
	rpcData.icon = oriData.icon;

	return rpcData;
end

--// 转换红包日志数据
function FamilyMgr:SwitchRedPacketLogData(oriData)
	local recordData = {};

	--// 发送者名字
	recordData.senderName = oriData.sender_name;
	--// 来源
	recordData.from = oriData.from;
	--// 金额
	recordData.amount = oriData.amount;

	return recordData;
end

--// 检测玩家是否存在
function FamilyMgr:IsMemberExist(memberId)
	if mgrPre.familyData == nil then
		return false;
	end

	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].roleId == memberId then
			return true;
		end
	end

	return false;
end

--// 删除帮派成员数据
function FamilyMgr:DeleteMemberData(delId)
	if mgrPre.familyData == nil then
		iError("LY", "No family data !!! ");
		return;
	end

	if self:IsMemberExist(delId) == false then
		return;
	end

	local newDataTbl = {};
	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].roleId ~= delId then
			newDataTbl[#newDataTbl + 1] = mgrPre.familyData.members[i];
		end
	end

	mgrPre.familyData.members = newDataTbl;
end

--// 更新帮派成员数据
function FamilyMgr:RenewMemberData(memberData)
	if mgrPre.familyData == nil then
		iError("LY", "No family data !!! ");
		return;
	end

	if mgrPre.familyData.members == nil then
		mgrPre.familyData.members = {};
	end

	local newData = self:SwitchFamilyMemberData(memberData);
	local isNewData = true;

	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].roleId == newData.roleId then
			mgrPre.familyData.members[i] = newData;
			isNewData = false;
			break;
		end
	end

	if isNewData == true then
		mgrPre.familyData.members[#mgrPre.familyData.members + 1] = newData;
	end

	FamilyMgr:SortFamilyMember();
end

--// 帮派成员排序
function FamilyMgr:SortFamilyMember()
	if mgrPre.familyData == nil or mgrPre.familyData.members == nil or #mgrPre.familyData.members <= 0 then
		return;
	end

	table.sort(mgrPre.familyData.members, function(a, b)
		if a.isOnline == true and b.isOnline == false then
			return true;
		elseif a.isOnline == false and b.isOnline == true then
			return false;
		else
			if a.title == 5 then
				if b.title == 4 or b.title == 3 then
					return false;
				else
					return a.title > b.title; 
				end
			elseif b.title == 5 then
				if a.title == 4 or a.title == 3 then
					return true;
				else
					return a.title > b.title; 
				end
			else
				if a.title ~= b.title then
					return a.title > b.title;
				elseif a.power ~= b.power then
					return a.power > b.power;
				else
					return a.roleId < b.roleId;
				end
			end
		end
	end)
end

--// 帮派申请列表排序
function FamilyMgr:SortApplyMember()
	if mgrPre.familyData == nil or mgrPre.familyData.applyList == nil or #mgrPre.familyData.applyList <= 0 then
		return;
	end

	table.sort(mgrPre.familyData.applyList, function(a, b)
		if a.power ~= b.power then
			return a.power > b.power;
		else
			return a.roleId < b.roleId;
		end
	end)

end

--// 道庭个人可发新红包
function FamilyMgr:DelSelfGiveRedPacket(rpId)

	local selfFData = FamilyMgr:GetPlayFamilyInfo();
	local newGiveRPTbl = {};
	for i = 1, #selfFData.redPacketTbl do
		if rpId ~= selfFData.redPacketTbl[i].id then
			newGiveRPTbl[#newGiveRPTbl + 1] = selfFData.redPacketTbl[i];
		end
	end

	selfFData.redPacketTbl = newGiveRPTbl;
	
	--// 分发事件
	if self.lookAtRP == false then
		self.checkRP = false;
	end
	FamilyMgr.eUpdateRedPack();
	EventMgr.Trigger("NewGetRedPacket");
end

--// 使用道具发放道庭红包
function FamilyMgr:GiveRedPByItem(itemId)
	if mgrPre == nil or mgrPre.familyData == nil or mgrPre.hasFamily == false then
		UITip.Log("未创建或加入道庭！");
		return;
	end

	local tempData = {};
	tempData.itemId = itemId;
	tempData.goldType = 3;
	local tIData = ItemData[tostring(itemId)];
	if tIData == nil then
		iError("LY", "Item miss !!! ");
		return;
	end
	tempData.amount = tIData.uFxArg[1];
	tempData.minPiece = 10;
	if tIData.useCond ~= nil then
		tempData.minPiece = tIData.useCond[1];
	end
	
	UIMgr.Open(UIFamilyRedPWnd.Name, function()
		UIFamilyRedPWnd:OpenGivePedPPanel();
		UIFGiveRedPPanel:ShowData(tempData, 2);
	end)
end

--// 仓库宝箱排序
function FamilyMgr:SortBox(dataList)
	if dataList == nil or #dataList <= 0 then
		return;
	end

	table.sort(dataList, function(a, b)
		return a.endTime < b.endTime;
	end);

	for i = 1, #dataList do
		dataList[i].posIndex = i;
	end
end

--// 清理已经领取的道庭宝箱
function FamilyMgr:ClearGetFamilyBox()
	if FamilyMgr:JoinFamily() == false or mgrPre.boxDataList == nil then
		return;
	end

	local newBoxList = {};
	for i = 1, #mgrPre.boxDataList do
		if mgrPre.boxDataList[i].goods == nil then
			newBoxList[#newBoxList + 1] = mgrPre.boxDataList[i];
		end
	end

	mgrPre.boxDataList = newBoxList;
	FamilyMgr.SortBox(mgrPre.boxDataList);
end

--// 转换帮派装备数据
function FamilyMgr:SwitchFamilyGoodsData(oriData)
	local goodData = {};

	--唯一id
	goodData.id = oriData.id;
	--道具表id
	goodData.type_id = oriData.type_id;
	--是否绑定
	goodData.bind = oriData.bind;
	--数量
	goodData.num = oriData.num;

	--卓越属性
	goodData.eDic = {};
	for i = 1, #oriData.excellent_list do
		goodData.eDic[oriData.excellent_list[i].id] = oriData.excellent_list[i].val;
	end

	--翅膀
	goodData.wing_id = nil;
	goodData.bList = {};
	goodData.lDic = {};

	-- if oriData.wing ~= nil then
	-- 	local wing = oriData.wing;

	-- 	if(wing ~= nil)then
	-- 		--翅膀的id
	-- 		goodData.wing_id = wing.wing_id;

	-- 		--翅膀的基础属性
	-- 		local bProp = wing.base_props;
	-- 		for i = 0, bProp.Count - 1 do
	-- 			goodData.bList[#goodData.bList + 1] = bProp[i];
	-- 		end

	-- 		--翅膀的传奇属性
	-- 		local lProp = wing.legend_props;
	-- 		for i = 0, lProp.Count - 1 do
	-- 			goodData.lDic[tostring(lProp[i].id)] = lProp[i].val;
	-- 		end
	-- 	end
	-- end

	goodData.startTime = oriData.start_time; --开始生效的时间
	goodData.endTime = oriData.end_time;  --now>endTime 过期

	goodData.fightVal = nil;
	goodData.wearPart = nil;
	if EquipBaseTemp[tostring(goodData.type_id)] ~= nil then
	--if ItemData[tostring(goodData.type_id)] ~= nil then
		goodData.fightVal = PropTool.Fight(goodData.type_id);
		goodData.wearPart = PropTool.FindPart(tostring(goodData.type_id));
	end

	return goodData;

	-- local goodData = {};

	-- --// 背包数据
	-- goodData.id = oriData.id;
	-- --// 道具type_id
	-- goodData.type_id = oriData.type_id;
	-- --// 是否绑定
	-- goodData.bind = oriData.bind;
	-- --// 数量
	-- goodData.num = oriData.num;
	-- --// 装备卓越属性
	-- goodData.excellent_list = {};
	-- for i = 0, oriData.excellent_list.Count - 1 do
	-- 	goodData.excellent_list[oriData.excellent_list[i].id] = oriData.excellent_list[i].val;
	-- end

	-- return goodData;
end

-------------------------------------------------------------------------------

---------------------------------- 获取数据部分 ----------------------------------


function FamilyMgr:FamilyComChg(ty)
	if mgrPre == nil or mgrPre.hasFamily == nil or mgrPre.hasFamily == false or mgrPre.familyData == nil then
		return;
	end

	if ty == 99 then
		if self:IsAnySkillCanUpdate() == true then
			FamilyMgr.eRed(true, 3, 1);
		else
			FamilyMgr.eRed(false, 3, 1);
		end
	end
end

--// 转换64位整数
function FamilyMgr.ChangeInt64Num(number)
	return tonumber(tostring(number));
end

--// 根据等级获取相应的帮派等级数据
function FamilyMgr:GetLvCfgByLv(familyLv)
	if mgrPre.lvCfg == nil then
		iError("LY", "mgrPre.lvCfg is null !!! ");
		return nil;
	end

	return mgrPre.lvCfg[tostring(familyLv)];
end

--// 获取当前等级道庭最大人数
function FamilyMgr:GetLvCfgMaxPer(familyLv)
	local tCfg = FamilyMgr:GetLvCfgByLv(familyLv);
	if tCfg == nil then
		return 0;
	end

	if AgentMgr:GetAgentId() == 7 then
		return tCfg.maxPer7;
	end

	return tCfg.maxPer;
end

--// 是否加入帮派
function FamilyMgr:JoinFamily()
	if mgrPre.hasFamily == nil then
		return false;
	end
	return mgrPre.hasFamily;
end

--// 获取道庭数量
function FamilyMgr:GetFamilyNum()
	return mgrPre.briefNum;
end

--// 获取玩家工会Id（0为没有工会）
function FamilyMgr:GetPlayFamilyId()
	local retId = 0;

	if mgrPre.familyData ~= nil then
		retId = mgrPre.familyData.Id;
	end

	--iLog("LY", "Player family id : "..retId);
	return retId;
end

--// 获取帮派数据
function FamilyMgr:GetFamilyData()
	return mgrPre.familyData;
end

--// 获取道庭战力
function FamilyMgr:GetFamilyAbility()
	if mgrPre.familyData == nil or mgrPre.familyData.members == nil or #mgrPre.familyData.members <= 0 then
		return 0;
	end

	local retAbility = 0;
	for i = 1, #mgrPre.familyData.members do
		local tMember = mgrPre.familyData.members[i];
		if tMember ~= nil then
			retAbility = retAbility + tMember.power;
		end
	end

	return retAbility;
end

--// 获取角色Id
function FamilyMgr:GetPlayerRoleId()
	return FamilyMgr.ChangeInt64Num(User.instance.MapData.UID);
end

--// 根据道庭Id获取道庭简介
function FamilyMgr:GetFamilyBriefById(familyId)
	if mgrPre.familyBriefs == nil then
		return nil;
	end

	for i = 1, #mgrPre.familyBriefs do
		if mgrPre.familyBriefs[i].familyId == familyId then
			return mgrPre.familyBriefs[i];
		end
	end

	return nil;
end

--// 根据道庭Id获取道庭名字
function FamilyMgr:GetFamilyNameById(familyId)
	if mgrPre.familyBriefs == nil then
		return "";
	end

	for i = 1, #mgrPre.familyBriefs do
		if mgrPre.familyBriefs[i].familyId == familyId then
			return mgrPre.familyBriefs[i].familyName;
		end
	end

	return "";
end

--// 获取自身数据
function FamilyMgr:GetPlayFamilyInfo()
	if mgrPre.familyData == nil or mgrPre.familyData.members == nil or #mgrPre.familyData.members <= 0 then
		iLog("LY", "No family member data !!! ");
		return nil;
	end

	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].roleId == self:GetPlayerRoleId() then
			return mgrPre.familyData.members[i];
		end
	end

	return nil;
end

--// 获取玩家帮派成员数据
function FamilyMgr:GetCurMemberData()
	return mgrPre.familyMemberData;
end

--// 是否领取每日奖励
function FamilyMgr:IsGetReward()
	--return mgrPre.familyData.getReward;

	return mgrPre.gGetReward;
end

-- --设置帮派兽粮
-- function FamilyMgr:SetGrain(grain)
-- 	if mgrPre == nil or mgrPre.familyData == nil then
-- 		return
-- 	end
-- 	mgrPre.familyData.grain = grain
-- end

-- --获取帮派兽粮
-- function FamilyMgr:GetGrain()
-- 	if mgrPre == nil or mgrPre.familyData == nil then
-- 		return -1;
-- 	end

-- 	if not self:JoinFamily() then iTrace.Log("没有加入帮派，不能获取兽粮！") return -1 end
-- 	return mgrPre.familyData.grain
-- end

-- --设置帮派Boss开启次数
-- function FamilyMgr:SetBossCount(count)
-- 	if mgrPre == nil or mgrPre.familyData == nil then
-- 		return
-- 	end
-- 	mgrPre.familyData.bossCount = count
-- end

-- --获取帮派Boss开启次数
-- function FamilyMgr:GetBossCount()
-- 	if mgrPre == nil or mgrPre.familyData == nil then
-- 		return -1
-- 	end

-- 	if not self:JoinFamily() then iTrace.Log("没有加入帮派，不能获取Boss次数！") return -1 end
-- 	return mgrPre.familyData.bossCount
-- end

--// 获取庭主数据
function FamilyMgr:GetFamilyOwnerData()
	if mgrPre.familyData == nil or mgrPre.familyData.members == nil then
		return nil;
	end

	for i = 1, #mgrPre.familyData.members do
		if mgrPre.familyData.members[i].title == 4 then
			return mgrPre.familyData.members[i];
		end
	end

	return nil;
end

--// 获取帮派成员数量
function FamilyMgr:GetFamilyMemberNum()
	if mgrPre.familyData == nil or mgrPre.familyData.members == nil then
		return 0;
	end

	return #mgrPre.familyData.members;
end

--// 根据范围获取道庭成员列表信息
function FamilyMgr:GetFamilyMembersRange(bInd, eInd)
	local memberNum = self:GetFamilyMemberNum();
	if memberNum == 0 then
		return nil;
	end
	if bInd > memberNum or eInd < 1 then
		return nil;
	end

	local beginIndex = bInd;
	local endIndex = eInd;
	if beginIndex <= 0 then
		beginIndex = 1;
	end
	if endIndex > memberNum then
		endIndex = memberNum;
	end

	local retList = {}
	for i = beginIndex, endIndex do
		retList[#retList + 1] = mgrPre.familyData.members[i];
	end

	return retList;
end

--// 根据索引获取职位名称
function FamilyMgr:GetTitleByIndex(indexType)
	if indexType == 1 then
		return "成员";
	elseif indexType == 2 then
		return "长老";
	elseif indexType == 3 then
		return "副庭主";
	elseif indexType == 4 then
		return "庭主";
	elseif indexType == 5 then
		return "人气甜心";
	end
	return "未知";
end

--// 获取职业
function FamilyMgr:GetJobByIndex(sex, index)
	if sex == 1 then
		if index == 0 then
			return "沉鱼宫";
		elseif index == 1 then
			return "英招圣女";
		elseif index == 2 then
			return "天英神女";
		elseif index == 3 then
			return "飞云天仙";
		elseif index == 4 then
			return "天华真仙";
		elseif index == 5 then
			return "九天玄仙";
		elseif index == 6 then
			return "太皇天后";
		end
	else
		if index == 0 then
			return "圣道宗";
		elseif index == 1 then
			return "太一真人";
		elseif index == 2 then
			return "伏魔元帅";
		elseif index == 3 then
			return "蛮荒战神";
		elseif index == 4 then
			return "鸿蒙君主";
		elseif index == 5 then
			return "擎天大帝";
		elseif index == 6 then
			return "元始天尊";
		end
	end
end

--// 根据品质改变字体颜色
function FamilyMgr:ChangeTextColByQua(oriText, quaIndex)
	if oriText == nil or oriText == "" then
		return "";
	end

	local retText = oriText;

	--// 白
	if quaIndex == 1 then
		retText = StrTool.Concat("[FCF5F5FF]", oriText, "[-]");
	--// 蓝
	elseif quaIndex == 2 then
		retText = StrTool.Concat("[008FFCFF]", oriText, "[-]");
	--// 紫
	elseif quaIndex == 3 then
		retText = StrTool.Concat("[B03DF2FF]", oriText, "[-]");
	--// 橙
	elseif quaIndex == 4 then
		retText = StrTool.Concat("[F39800FF]", oriText, "[-]");
	--// 红
	elseif quaIndex == 5 then
		retText = StrTool.Concat("[F21929FF]", oriText, "[-]");
	--// 粉
	elseif quaIndex == 6 then
		retText = StrTool.Concat("[FF66FCFF]", oriText, "[-]");
	end

	return retText;
end

--// 获取自己的活跃度
function FamilyMgr:GetSelfActivity()
	return mgrPre.selfActivity;
end

--// 获取自身荣誉值
function FamilyMgr:GetFamilyCon()
	return RoleAssets.FamilyCon;
end

--// 获取所有申请者Id
function FamilyMgr:GetAllApplyMemberIds()
	if mgrPre.familyData == nil or mgrPre.familyData.applyList == nil then
		return nil;
	end

	local retIds = {};
	for i = 1, #mgrPre.familyData.applyList do
		retIds[#retIds + 1] = mgrPre.familyData.applyList[i].roleId;
	end

	return retIds;
end

--// 获取帮派申请列表数量
function FamilyMgr:GetFamilyApplyNum()
	if mgrPre.familyData == nil or mgrPre.familyData.applyList == nil then
		return 0;
	end

	return #mgrPre.familyData.applyList;
end

--// 根据索引获取帮派申请列表
function FamilyMgr:GetFamilyApplyData(bInd, eInd)
	local applyNum = self:GetFamilyApplyNum();
	if applyNum <= 0 then
		return nil;
	end
	if bInd > applyNum or eInd < 1 then
		return nil;
	end

	local beginIndex = bInd;
	local endIndex = eInd;
	if beginIndex <= 0 then
		beginIndex = 1;
	end
	if endIndex > applyNum then
		endIndex = applyNum;
	end

	local retList ={};

	for i = beginIndex, endIndex do
		retList[#retList + 1] = mgrPre.familyData.applyList[i];
	end

	return retList;
end

--// 根据职业挑选装备物品
function FamilyMgr:ChoseJobItems(jobId, dataList)
	--User.MapData.Category

	local retList = {}

	for i = 1, #dataList do
		local tData = dataList[i];
		if tData.type_id == 30360 then
			retList[#retList + 1] = tData;
		else
			local eData = EquipBaseTemp[tostring(tData.type_id)];
			if eData then
				if eData.wearJob == jobId then
					retList[#retList + 1] = tData;
				end
			end
			if not eData then
				retList[#retList + 1] = tData
			end
		end
	end

	return retList;
end

--// 获取未开启宝箱数量
function FamilyMgr:GetNewBoxNumber()
	if FamilyMgr:JoinFamily() == false or mgrPre.boxDataList == nil or #mgrPre.boxDataList <= 0 then
		return 0;
	end

	local tm = TimeTool.GetServerTimeNow() * 0.001;
	local retNum = 0;
	for i = 1, #mgrPre.boxDataList do
		local eT = mgrPre.boxDataList[i].endTime;
		if eT ~= nil and eT > tm then
			retNum = retNum + 1;
		end
	end

	return retNum;
end

--// 获取道庭仓库宝箱列表
function FamilyMgr:GetFamilyBoxDataList()
	-- mgrPre.boxDataList = {};
	-- for a = 1, 18 do
	-- 	local ttt = {}
	-- 	ttt.itemId = a;
	-- 	ttt.endTime = 1581041042;
	-- 	ttt.goods = nil;

	-- 	mgrPre.boxDataList[#mgrPre.boxDataList + 1] = ttt;
	-- end

	if FamilyMgr:JoinFamily() == false then
		return nil;
	end

	if mgrPre.boxDataList ~= nil then
		local newDataList = {};
		local tm = TimeTool.GetServerTimeNow() * 0.001;
		for i = 1, #mgrPre.boxDataList do
			if tm < mgrPre.boxDataList[i].endTime then
				newDataList[#newDataList + 1] = mgrPre.boxDataList[i];
			end
		end

		mgrPre.boxDataList = newDataList;
	end

	return mgrPre.boxDataList;
end


--// 是否有权限修改公告
function FamilyMgr:CanEditNotice()
	if mgrPre.familyMemberData == nil then
		return false;
	end

	if mgrPre.familyMemberData.title == 2
		or mgrPre.familyMemberData.title == 3
		or mgrPre.familyMemberData.title == 4
		or mgrPre.familyMemberData.title == 5 then
		return true;
	end

	return false;
end

--// 是否有权限处理成员事物
function FamilyMgr:CanDealWithMember()
	if mgrPre.familyMemberData == nil then
		return false;
	end

	if mgrPre.familyMemberData.title == 3
			or mgrPre.familyMemberData.title == 4 then
		return true
	end

	return false;
end

--// 是否有需要庭主或者副庭主处理的条目
function FamilyMgr:NeedDeal()
	if mgrPre.familyMemberData == nil then
		return false;
	end

	if mgrPre.familyMemberData.title == 3
		or mgrPre.familyMemberData.title == 4 then
		if mgrPre.familyMemberData.apply_list then
			return #mgrPre.familyMemberData.apply_list > 0;
		end
	end

	return false;
end

--// 计算技能初始信息
function FamilyMgr:CalSkillInitInfo()
	local retInfos = {};

	local tKV = {};
	for k, v in pairs(FamilySkill) do
		local tEId = math.floor(v.id % 1000);
		if tEId == 1 then
			local tPId = math.floor(v.id / 1000);
			if tKV[tPId] == nil then
				tKV[tPId] = 1;

				local newInfo = {};
				newInfo.id = v.id;
				newInfo.preId = tPId;
				newInfo.ulLv = v.unlockLv;
				newInfo.rankId = v.rankId;
				newInfo.showPct = v.showPct;

				retInfos[#retInfos + 1] = newInfo;
			end
		end
	end

	table.sort(retInfos, function(a, b)
		return a.rankId < b.rankId;
	end);

	return retInfos;
end

--// 获取技能初始信息
function FamilyMgr:GetSkillInitInfo()
	return mgrPre.skillInitInfos;
end

--// 获取当前技能信息列表
function FamilyMgr:GetSkillInfo()
	local retInfos = {};

	if (mgrPre.familyData == nil or mgrPre.familyData.Lv == nil 
	 or mgrPre.familyData.Lv <= 0 or mgrPre.familyData.skillCurInfos == nil) then
		local infos = mgrPre.skillInitInfos;
		if infos == nil then
			return nil;
		end

		for i = 1, #infos do
			local info = {};
			info.baseInfo = infos[i];
			info.cfgInfo = FamilySkill[tostring(infos[i].id)];
			info.unlock = false;

			if mgrPre.familyData.Lv >= info.baseInfo.ulLv then
				info.unlock = true;
			end
			info.lv = 0;

			retInfos[#retInfos + 1] = info;
		end

		return retInfos;
	end

	local curInfos = mgrPre.familyData.skillCurInfos;
	for i = 1, #curInfos do
		if mgrPre.familyData.Lv >= curInfos[i].baseInfo.ulLv then
			curInfos[i].unlock = true;
		end
	end

	return curInfos;
end

--// 根据技能Id获取技能信息
function FamilyMgr:GetSkillInfoById(skillId)
	for k, v in pairs(FamilySkill) do
		if v.id == skillId then
			return v;
		end
	end

	return nil;
end

--// 是否有道庭技能可以升级
function FamilyMgr:IsAnySkillCanUpdate()
	if mgrPre.familyData == nil or mgrPre.familyData.skillCurInfos == nil then
		return false;
	end

	local selfPot = FamilyMgr:GetFamilyCon();
	if selfPot ~= nil and selfPot < 15000 then
		return false;
	end

	for i = 1, #mgrPre.familyData.skillCurInfos do
		local curSkillInfo = mgrPre.familyData.skillCurInfos[i];
		if curSkillInfo ~= nil and curSkillInfo.unlock == true then
			if curSkillInfo.lv <= 0 then
				if selfPot >= curSkillInfo.cfgInfo.pay then
					return true;
				end
			else
				local tNextData = FamilyMgr:GetSkillInfoById(curSkillInfo.cfgInfo.id + 1);
				if tNextData == nil then
					return false;
				else
					if selfPot >= tNextData.pay then
						return true
					end
				end
			end
		end
	end

	return false;
end

--// 检查是否存在未处理的红包
function FamilyMgr:HasRedPacket()

	local actRptbl1, actRptbl2 = RedPacketActivMgr:GetAllRedState();
	if actRptbl2 ~=nil and #actRptbl2 > 0 then
		return true;
	end


	local ckTbl1, ckTbl2, ckTbl3, ckTbl4 = self:GetAllRedPacketData();
	if self:JoinFamily() == false or self.checkRP == true then
		return false;
	end
	if ckTbl1 ~= nil and #ckTbl1 > 0 then
		return true;
	end

	if ckTbl2 ~= nil and #ckTbl2 > 0 then
		return true;
	end

	-- if FamilyMgr:IsAnySkillCanUpdate() == true then
	-- 	return true;
	-- end

	return false;
end

--// 获取所有状态红包结构
--// 返回4个列表：1、未发送；2、未领取；3、已领取；4、已领完
function FamilyMgr:GetAllRedPacketData()
	local retTbl1 = {};
	local retTbl2 = {};
	local retTbl3 = {};
	local retTbl4 = {};

	--// 处理未发送红包
	local selfData = FamilyMgr:GetPlayFamilyInfo();
	if selfData ~= nil then
		if selfData.redPacketTbl ~= nil and #selfData.redPacketTbl > 0 then
			for i = 1, #selfData.redPacketTbl do
				retTbl1[#retTbl1 + 1] = selfData.redPacketTbl[i];
			end
		end
	end

	--// 处理未领取、已领取、已领完
	if mgrPre.familyData ~= nil and mgrPre.familyData.redPacketTbl ~= nil and #mgrPre.familyData.redPacketTbl > 0 then
		for i = 1, #mgrPre.familyData.redPacketTbl do
			local rpData = mgrPre.familyData.redPacketTbl[i];
			if rpData ~= nil then
				--// 已领完
				if rpData.piece == rpData.sentNum then
					retTbl4[#retTbl4 + 1] = rpData;
				elseif rpData.contentTbl ~= nil then
					local hasGet = false;
					for j = 1, #rpData.contentTbl do
						local getPData = rpData.contentTbl[j];
						if getPData.roleId == selfData.roleId then
							hasGet = true;
							break;
						end
					end

					--// 已领取
					if hasGet == true then
						retTbl3[#retTbl3 + 1] = rpData;
					--// 未领取
					else
						retTbl2[#retTbl2 + 1] = rpData;
					end
				end
			else
				iError("LY", "Red packet data error !!! ")
			end
		end
	end
	
	return retTbl1, retTbl2, retTbl3, retTbl4;
end

--// 检查自己是否获取此红包
function FamilyMgr:CheckSelfGetRedP(rpData)
	local selfData = FamilyMgr:GetPlayFamilyInfo();
	if selfData == nil then
		return false;
	end

	for i = 1, #rpData.contentTbl do
		local getPData = rpData.contentTbl[i];
		if getPData.roleId == selfData.roleId then
			return true;
		end
	end

	return false;
end

--// 根据Id获取红包数据
function FamilyMgr:GetRedPacketById(redPId)
	if mgrPre == nil or mgrPre.familyData == nil or mgrPre.familyData.redPacketTbl == nil then
		return nil;
	end

	for i = 1, #mgrPre.familyData.redPacketTbl do
		if mgrPre.familyData.redPacketTbl[i].id == redPId then
			return mgrPre.familyData.redPacketTbl[i];
		end
	end

	return nil;
end

--// 获得红包记录列表
function FamilyMgr:GetRedPacketRecord()
	if mgrPre.familyData == nil then
		return nil;
	end

	return mgrPre.familyData.redPacketLog;
end

-- 获取神殿相关信息
--写倒了is_salary =true时候为没有领取过了
function FamilyMgr:GetTempleInfo( )
	local tmpMsg = {}
	if mgrPre.familyMemberData==nil then
		tmpMsg.is_salary=true; --
		tmpMsg.canAllot=false;
	else
		tmpMsg.is_salary= mgrPre.familyMemberData.salary;
		tmpMsg.canAllot=mgrPre.familyMemberData.title==4 and true or false;
	end
	--nam查找id
	tmpMsg.memberName={}
	if mgrPre.familyData~=nil then
		local k = mgrPre.familyData.members
		if k~=nil then				
			for i=1,#k do
				tmpMsg.memberName[k[i].roleName]=k[i].roleId;
			end
		end
		tmpMsg.family_name=mgrPre.familyData.Name
		tmpMsg.cv_reward=mgrPre.familyData.cv_reward;
		tmpMsg.max_cv=mgrPre.familyData.max_cv;
		tmpMsg.end_cv=mgrPre.familyData.end_cv;
	end
	return tmpMsg
end
--设置神殿相关的信息
function FamilyMgr:SetTempleInfo(msg)
	mgrPre.familyData.cv_reward=msg.cv_reward
	mgrPre.familyData.max_cv=msg.max_cv
	mgrPre.familyData.end_cv=msg.end_cv
end
--神殿红点
function FamilyMgr:RedTempDrop( )
	local myself =FamilyMgr:GetPlayFamilyInfo()
	local redBool = false
	if myself~=nil then
		 redBool = FamilyMgr:RedTempDropCheck( )
	end
	FamilyMgr.eRed(redBool, 3, 4);
	TempleMgr.eRed(redBool)
end
function FamilyMgr:RedTempDropCheck( )
	local myself =FamilyMgr:GetPlayFamilyInfo()
	local is_salary = true
	if myself~=nil then
		 is_salary = FamilyMgr:GetTempleInfo().is_salary
	end
	local b = false
	if TempleMgr.canSend and (is_salary and TempleMgr.cansalara)  then
		b=true
	end
	return  b
end

FamilyMgr.openWndIndex = 0;
FamilyMgr.openWndCB = nil;
--// tagIndex：1、主页  2、成员  3、活动
function FamilyMgr:OpenFamilyWndTag(tagIndex, openCB)
	if mgrPre == nil or mgrPre.familyData == nil or FamilyMgr:JoinFamily() == false then
		return;
	end

	FamilyMgr.openWndIndex = tagIndex;
	FamilyMgr.openWndCB = openCB;
	UIMgr.Open(UIFamilyMainWnd.Name, self.OpenFamilyWndCB, self);
end

function FamilyMgr:OpenFamilyWndCB()
	UIFamilyMainWnd:ChangePanel(FamilyMgr.openWndIndex);
	FamilyMgr.openWndIndex = 0;
	if FamilyMgr.openWndCB ~= nil then
		FamilyMgr.openWndCB();
		FamilyMgr.openWndCB = nil;
	end
end

--// 获取化神等级显示
function FamilyMgr:GetLvShowText(oriLv)
	local retText = tostring(oriLv);
	-- if oriLv > 370 then
	if oriLv > 999 then
		--retText = StrTool.Concat("化神", tostring(oriLv - 370), "级");
		retText = tostring(oriLv - 370);
	end

	return retText;
end

function FamilyMgr:FamilyNeedShowRedP()
	if FamilyMgr:IsGetReward() == false then
		return true;
	end

	if FamilyMgr:HasRedPacket() == true then
		return true;
	end

	if FamilyMgr:IsAnySkillCanUpdate() == true then
		return true;
	end

	if FamilyBossMgr:IsShowAction() == true then
		return true;
	end

	if FamilyMissionMgr:IsShowAction() == true then
		return true;
	end

	if FamilyEscortMgr:IsOpen() == true then
		return true;
	end

	if FamilyActivityMgr.FmlDftState == true then
		return true;
	end

	if FamilyMgr:GetNewBoxNumber() > 0 then
		return true;
	end

	if FamilyMgr:NeedDeal() == true then
		return true;
	end
	return false
end

function FamilyMgr:FilterSpecChars(s)
    local ss = {};
    local k = 1;
    while true do
		if k > #s then
			break;
		end

        local c = string.byte(s, k);
		if not c then
			break;
		end

        if c < 192 then
            if (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then
                table.insert(ss, string.char(c));
            end
            k = k + 1;
        elseif c < 224 then
            k = k + 2;
        elseif c < 240 then
            if c >= 228 and c <= 233 then
                local c1 = string.byte(s, k+1);
                local c2 = string.byte(s, k+2);
                if c1 and c2 then
                    local a1, a2, a3, a4 = 128, 191, 128, 191;
					if c == 228 then
						a1 = 184;
					elseif c == 233 then
						a2, a4 = 190, c1 ~= 190 and 191 or 165;
                    end
                    if c1 >= a1 and c1 <= a2 and c2 >= a3 and c2 <= a4 then
                        table.insert(ss, string.char(c, c1, c2));
                    end
                end
            end
            k = k + 3;
        elseif c < 248 then
            k = k + 4;
        elseif c < 252 then
            k = k + 5;
        elseif c < 254 then
            k = k + 6;
        end
    end
    return table.concat(ss);
end

--// 获取自己的贡献值(捐献、兑换装备)
function FamilyMgr:GetSelfIntegral()
	return mgrPre.selfIntegral;
end

--// 获取仓库记录
function FamilyMgr:GetFamilyDepotLogs()
	if mgrPre.familyData == nil or mgrPre.familyData.depotLogs == nil then
		return nil;
	end

	return mgrPre.familyData.depotLogs;
end

--// 获取仓库物品
function FamilyMgr:GetFamilyDepotItems(forDel)
	if mgrPre.familyData == nil or mgrPre.familyData.goodsList == nil then
		return nil;
	end

	local gList = mgrPre.familyData.goodsList;

	local retDatas = {};
	--// 第一个为升级丹
	for i = 1, #gList do
		if gList[i].type_id == 700003 then
			if forDel == nil or forDel == false then
				local tData = gList[i];
				--// 调换为第一位
				if i ~= 1 then
					local temp = retDatas[1];
					retDatas[1] = tData;
					retDatas[#retDatas + 1] = temp;
				else
					retDatas[1] = tData;
				end
			end
		else
			retDatas[#retDatas + 1] = gList[i];
		end
	end

	return retDatas;
end

--// 根据品阶获取仓库物品
function FamilyMgr:GetDepotItemsByQuality(quality, dataList)
	local retList = {}

	for i = 1, #dataList do
		local tData = dataList[i];
		local eData = EquipBaseTemp[tostring(tData.type_id)];
		if eData ~= nil then
			if eData.wearRank == quality then
				retList[#retList + 1] = tData;
			end
		end
	end

	return retList;
end

--// 根据颜色获取仓库物品
function FamilyMgr:GetDepotItemsByColor(colorIndex, dataList)
	local retList = {}

	for i = 1, #dataList do
		local tData = dataList[i];
		--local eData = EquipBaseTemp[tostring(tData.type_id)];
		local eData = ItemData[tostring(tData.type_id)];
		if eData ~= nil then
			if eData.quality == colorIndex then
				retList[#retList + 1] = tData;
			end
		end
	end

	return retList;
end

--// 仓库物品排序
function FamilyMgr:SortDepotItems(dataList)
	local all = {}
	if dataList == nil or #dataList <= 0 then
		iLog("LY", "Sort data list is null !!! ");
		return all;
	end
	local equipDatas = {}
	local propDatas = {}
	for i = 1, #dataList do
		local temp = EquipBaseTemp[tostring(dataList[i].type_id)]
		if temp then
			table.insert(equipDatas, dataList[i])
		else
			table.insert(propDatas, dataList[i])
		end
	end
	--装备排序
	table.sort(equipDatas, function(a, b)
		local aeData = EquipBaseTemp[tostring(a.type_id)];
		local beData = EquipBaseTemp[tostring(b.type_id)];
		if aeData == nil then
			return true;
		elseif beData == nil then
			return false;
			--// 比较穿戴部位
		elseif aeData.wearParts ~= beData.wearParts then
			return aeData.wearParts < beData.wearParts;
		else
			--// 比较品阶
			if aeData.wearRank ~= beData.wearRank then
				return aeData.wearRank > beData.wearRank;
			else
				--// 比较品质
				if aeData.quality ~= beData.quality then
					return aeData.quality > beData.quality;
				else
					--// 比较星级
					if aeData.startLv ~= beData.startLv then
						return aeData.startLv > beData.startLv;
					else
						--// 按Id大小排序
						return a.id < b.id;
					end
				end
			end
			return false
		end
	end);

	--非装备道具排序
	table.sort(propDatas, function(a, b)
		local aData = ItemData[tostring(a.type_id)];
		local bData = ItemData[tostring(b.type_id)];
		if not aData or not bData then
			return false
		end
		-- 品质降序
		if aData.quality > bData.quality then
			return true
		elseif aData.quality == bData.quality then
			-- 品质相等，id升序
			if a.id < b.id then
				return true
			end
		end
		return false
	end)

	for i = 1, #equipDatas do
		table.insert(all, equipDatas[i])
	end
	for i = 1, #propDatas do
		table.insert(all, propDatas[i])
	end
	return all
end

--// 获取可捐献装备结构
function FamilyMgr:GetCanDepotEquipData()
	local retDataTbl = {};
	local tb = PropMgr.UseEffGet(1);
	if tb == nil then
		return retDataTbl;
	end

	local items = PropMgr.GetCanDonateItems()
	for i, v in pairs(items) do
		if v.bind == nil or v.bind == false then
			retDataTbl[#retDataTbl + 1] = v
		end
	end
	--for i,v in ipairs(tb) do
	--	--local equip = EquipBaseTemp[tostring(v)]
	--	local item = ItemData[tostring(v)];
	--	if item ~= nil and item.worth > 0 and item ~= nil and item.quality > 3 then
	--		local ttb = PropMgr.typeIdDic[tostring(v)]
	--		for i1,v1 in ipairs(ttb) do
	--			local tttb = PropMgr.tbDic[tostring(v1)]
	--			if tttb.bind == nil or tttb.bind == false then
	--				retDataTbl[#retDataTbl + 1] = tttb
	--			end
	--		end
	--	end
	--end
	-- for k,v in pairs(PropMgr.ATbDic) do
	-- 	for kc,vc in pairs(v) do
	-- 		local tData = ItemData[tostring(vc.type_id)];
	-- 		if tData ~= nil and tData.type == 1 then
	-- 			local tEData = EquipBaseTemp[tostring(vc.type_id)];
	-- 			if tEData ~= nil and tEData.worth > 0 then
	-- 				retDataTbl[#retDataTbl + 1] = vc;
	-- 			end
	-- 		end
	-- 	end
	-- end

	return retDataTbl;
end



-------------------------------------------------------------------------------

return FamilyMgr

