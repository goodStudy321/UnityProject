--[[
 	authors 	:Liu
 	date    	:2018-7-26 10:00:00
 	descrition 	:开服活动管理
--]]

RankActivMgr = {Name = "RankActivMgr"}

local My = RankActivMgr

local Info = require("RankActiv/RankActivInfo")

function My:Init()
    Info:Init()
    self:SetLnsr(ProtoLsnr.Add)
    self.eActivInfo = Event()
    self.eGetAward = Event()
    self.eRankInfo = Event()
    self.eBuyItem = Event()
    self.eUpItemCount = Event()
end

--设置监听
function My:SetLnsr(func)
    func(20484,self.RespRankActivInfo, self)
    func(20486,self.RespRankAwardInfo, self)
    func(20488,self.RespBtnState, self)
    func(20490,self.RespRankInfo, self)
    func(20492,self.RespBuyItem, self)
end

--请求获取开服活动信息
function My:ReqRankActiv(id)
    local msg = ProtoPool.GetByID(20483)
    msg.id = id
	ProtoMgr.Send(msg)
end

--响应开服活动信息
function My:RespRankActivInfo(msg)
    -- iTrace.Error("msg = "..tostring(msg))
    local err = msg.err_code
    local index = msg.id
   -- print("                      index =                              "..index)
    local state = msg.status
    local rank = msg.my_rank
    local cond = msg.condition
    local rankState = msg.rank_reward_status
    Info:ClearStateDic()
    Info:ClearBuyList()

    for i,v in ipairs(msg.base_reward_list) do
        Info:SetAwardStateDic(v.id, v.val)
    end
    for i,v in ipairs(msg.buy_list) do
        Info:SetBuyList(v)
    end
    self.eActivInfo(index, state, rank, cond, rankState, err)
end

--请求获取开服活动奖励（1排行奖励 其他:基础奖励id+1）
function My:ReqRankAward(id, type)
    local msg = ProtoPool.GetByID(20485)
    msg.id = id
    msg.type = type
	ProtoMgr.Send(msg)
end

--响应开服活动奖励信息
function My:RespRankAwardInfo(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end

    local id = msg.id
    local type = msg.type
    local rankState = msg.rank_reward_status
    local stateList = msg.base_reward_list
    Info:ClearStateDic()

    for i,v in ipairs(msg.base_reward_list) do
        Info:SetAwardStateDic(v.id, v.val)
    end
    local isShow = self:IsGetAward(id, type, rankState, stateList)
    self:UpRedDot(isShow)
    self.eGetAward()
end

--响应按钮状态
function My:RespBtnState(msg)
    -- iTrace.Error("msg1 = "..tostring(msg))
    local isShow = false
    for i,v in ipairs(msg.status_list) do
        Info:SetActionDic(v.id, v.val)
        if v.val == true then
            isShow = true
        end
    end
    self:UpRedDot(isShow)
end

--更新红点
function My:UpRedDot(isShow)
    local actId = ActivityMgr.ZCGF
    if isShow == true then
		SystemMgr:ShowActivity(actId)
    else
		SystemMgr:HideActivity(actId)
    end
end

--判断是否能领取奖励
function My:IsGetAward(id, type, rankState, stateList)
    local isShow = false
    if type == 1 then
        isShow = (rankState == 2)
    else
        for i,v in ipairs(stateList) do
            if v.val == 2 then
                isShow = true
            end
        end
    end
    Info:SetActionDic(id, isShow)
    return isShow
end

--请求获取排行信息
function My:ReqRankInfo(id)
    local msg = ProtoPool.GetByID(20489)
    msg.id = id
	ProtoMgr.Send(msg)
end

--响应排行信息
function My:RespRankInfo(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    Info:ClearRankList()
    for i,v in ipairs(msg.ranks) do
        local rank = v.rank
        local roleId = v.role_id
        local roleName = v.role_name
        local val = v.rank_value
        Info:SetRankList(rank, roleId, roleName, val)
    end
    self.eRankInfo()
end

--请求购买道具
function My:ReqBuyItem(id, typeId)
    local msg = ProtoPool.GetByID(20491)
    msg.id = id
    msg.type_id = typeId
	ProtoMgr.Send(msg)
end

--响应购买道具
function My:RespBuyItem(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    local index = msg.id
    local item = msg.buy_info
    Info:SetBuyList(item)
    self.eBuyItem()
end

--获取坐骑信息
function My:GetMountsInfo(id)
	if id == 0 then return "功能未开启" end
	local cfg, index = BinTool.Find(MountStepCfg, id)
	if cfg == nil then return end
	return cfg.type.."阶"..cfg.st.."星"
end

--获取五行信息
function My :GetFiveInfo(id)
    if id == 0  then return "1层0关" end
         num1 = id%100   -- 几关
         num3  =math.floor( id/100  ) 
        
         num2 = num3%100 -- 几层
      return  num2.."层"..num1.."关"

end

--获取宠物信息
function My:GetPetInfo(id)
	if id == 0 then return "功能未开启" end
	local lv = math.floor((id-3030000) / 100)
	local cfg2, index2 = BinTool.Find(PetStepTemp, id)
	if cfg2 == nil then return end
	return lv.."阶"..cfg2.step.."星"
end

--清理缓存
function My:Clear()
    Info:Clear()
end

--释放资源
function My:Dispose()
    self:SetLnsr(ProtoLsnr.Remove)
	TableTool.ClearFieldsByName(self,"Event")
end

return My