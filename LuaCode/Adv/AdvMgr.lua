--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-17 10:44:59
-- 通用养成管理器基类,可用于:神兵,法宝,翅膀
-- 必须设置:
--    基础配置:iCfg,等级配置:iLvCfg,皮肤配置:iSkinCfg,资质配置:iQualCfg,
--    升级消耗道具列表配置:itemIDs
-- 必须设置协议ID:
--    tcInfoID,tcSoulID,tcSkinID,tcUpgID,tcChgID,tsChgID
-- Simple:简短描述
--==============================================================================

local ADI = require("Adv/AdvInfo")
require("Flag/PropsFlag")

local GetErr = ErrorCodeMgr.GetError

AdvMgr = Super:New{Name = "AdvMgr"}

local My = AdvMgr

--系数
My.fact = 0.01

--获取模型界面
My.eGetCPM = Event()

My.eSkinActive = Event()

function My:Init()
  --最大等级
  self.maxLv = 0
  --升级外形配置
  --信息字典 k:id前5位 v:AdvInfo
  self.dic = {}

  --等级技能ID列表,e(number):
  self.skiIDs = {}

  --技能等级列表,k:id,v:等级
  self.skiDic = {}

  --法宝等级技能ID列表
  self.mwSkiIDs = {}

  --法宝技能等级列表,k:id,v:等级
  self.mwSkiDic = {}

  --器魂字典 k:道具ID,v:已使用数量
  self.soulDic = {}

  --升级属性名称列表
  self.lvPropNames = {}

  --皮肤属性名称列表
  self.skinPropNames = {}

  --升星/进阶
  self.eStep = Event()

  --响应升级事件
  self.eRespUpg = Event()

  --响应器魂事件
  self.eRespSoul = Event()

  --响应精炼事件
  self.eRespRefine = Event()

  --响应皮肤按钮红点状态
  self.eSkinRedS = Event()

  self.qualIDs = self:GetQualIds(self.iQualCfg)
  self.skltIDs = self:GetSkLtIds(self.iCfg)

  self.flag = PropsFlag:New()
  self.flag:Init(self.itemIDs,self.qualIDs,self.skltIDs,self.sysID)

  -- --是否操作法宝皮肤
  -- self.mwSkin = false

  --法宝等级配置
  self.mwLvSkinCfg = nil
  --法宝经验
  self.mwExp = 0

  --响应幻化事件
  self.eRespChange = Event()
  self.upgCfg = self.iCfg[1]
  local iLvCfg = self.iLvCfg
  self.maxLv = iLvCfg[#iLvCfg].lv
  self:Reset()
  self:AddLsnr()
  self:SetSkiIDs()
  PropMgr.eUpdate:Add(self.Updates, self)
  RebirthMsg.eRefresh:Add(self.Updates,self)
  PropTool.SetNames(iLvCfg[1], self.lvPropNames)
  if self.sysID == 2 then --法宝皮肤列表
    
  else
    PropTool.SetNames(self.iSkinCfg[2], self.skinPropNames)
  end
end

function My:Reset()
  --当前等级
  self.lv = 0
  --当前法宝等级
  self.mwlv = 0
  --升级经验
  self.lvExp = 0
  --幻化ID
  self.chgID = 0
  --当前等级配置
  self.lvCfg = nil
  --当前选择信息Adv
  self.info = nil
  --上一次经验
  self.lastLvExp = 0
  TableTool.ClearDicToPool(self.dic)
  self:SetDic()
  self:SetSoulKey()
  -- PropMgr.eUpdate:Remove(self.Updates, self)
  -- RebirthMsg.eRefresh:Remove(self.Updates,self)
end

function My:GetQualIds(iQualCfg)
  local qualTab = {}
  for k,v in ipairs(iQualCfg) do
		if qualTab[v.id] == nil then
			qualTab[v.id] = v
		end
	end
  return qualTab
end

function My:GetSkLtIds(iCfg)
  local skinTab = {}
  for k,v in pairs(iCfg) do
    local id = v.id * 100
    if skinTab[id] == nil then
      skinTab[id] = v
    end
  end
  return skinTab
end


function My:Updates()
  local isFullSkin = true
  local rebirthLv = User.MapData.ReliveLV
  local icfg = self.iCfg
  -- if self.flag.isFullSkin == true then
    for i,v in pairs(icfg) do
      local k = tostring(v.id)
      local bId = v.id
      local propId = bId * 100
      local propNum = PropMgr.TypeIdByNum(propId)
      if (self.dic[k].sCfg.st == nil or self.dic[k].sCfg.st < 5) and (self.dic[k].exp == nil or self.dic[k].exp >= 0) and propNum > 0 and rebirthLv  >= v.rLv then
        isFullSkin = false
        break
      end
    end
    -- end
  self.flag.isFullSkin = isFullSkin
  self.flag:Update()
  self:UpMwAction()
end

function My:UpdateReLv()
  self.rebirthLv = User.MapData.ReliveLV
end

--设置信息字典
function My:SetDic()
  local dic = self.dic
  local GetKey, GetBID = My.GetKey, My.GetBID
  local id, bid, k, info = nil, nil, nil, nil
  local BF, OG = BinTool.Find, ObjPool.Get
  local iCfg, iSkinCfg = self.iCfg, self.iSkinCfg
  for i, v in ipairs(iSkinCfg) do
    id = v.id
    if self.sysID == 2 then
      bid = math.floor(GetBID(id) * 0.1)
    else
      bid = GetBID(id)
    end
    k = tostring(bid)
    info = dic[k]
    if self.info == nil then
      self.info = info
    end
    if info == nil then
      info = OG(ADI)
      dic[k] = info
      info.sCfg = v
      info.skinCfg = iSkinCfg
      info.exp = 0
      -- info.bCfg = BF(iCfg, bid)
        for i,v in ipairs(iCfg) do
          if v.id == bid then
            info.bCfg = v
          end
        end
    end
  end
end

--设置等级技能列表和字典
function My:SetSkiIDs()
  local skiIDs = self.skiIDs
  local skiDic = self.skiDic
  for i, v in ipairs(self.iLvCfg) do
    local skiID = v.oSkiID
    if skiID then
      skiIDs[#skiIDs + 1] = skiID
      local k = tostring(skiID)
      skiDic[k] = v.lv
    end
  end
end

--判断等级技能是否解锁
function My:GetLvSkiLock(skiID)
  local k = tostring(skiID)
  local lv = self.skiDic[k]
  if not lv then return false end
  local lt = (lv > self.lv) and true or false
  return lt
end

--设置法宝皮肤等级技能
function My:SetMWSkiIDs(curId)
  local bId = My.GetBID(curId)
  local mwSkiIDs = {}
  local mwSkiDic = {}
  for i, v in ipairs(self.iSkinCfg) do
    local baId = My.GetBID(v.id)
    if v.type == 1 and bId == baId then
      local skiID = v.oSkiID
      if skiID then
        mwSkiIDs[#skiIDs + 1] = skiID
        local k = tostring(skiID)
        mwSkiDic[k] = v.lv
      end
    end
  end
  return mwSkiIDs,mwSkiDic
end

--判断法宝等级技能是否解锁
function My:GetMWSkiLock(skiID)
  -- local k = tostring(skiID)
  -- local lv = self.mwSkiDic[k]
  -- if not lv then return false end
  -- local lt = (lv > self.mwlv) and true or false
  -- return lt
end

--初始经验
function My:SetInfos(lst)
  if lst == nil then return end
  local id, k, info = nil, nil, nil
  local dic, iSkinCfg = self.dic, self.iSkinCfg
  local userRelv = User.MapData.ReliveLV
  local iCfg = self.iCfg
  local isFullSkin = true
  local lstTab = {}
  local skinIdTab = {}
  skinIdTab = lst
  for i, v in ipairs(lst) do
    id = v.id
    if self.sysID == 2 then
      local temp = {}
      temp.id = math.floor(id * 0.1)
      skinIdTab[i] = temp
      bId = math.floor(self.GetBID(id) * 0.1)
    else
      bId = self.GetBID(id)
    end
    local propId = 0
    if self.sysID == 2 then
      k = tostring(math.floor(self.GetKey(id) * 0.1))
      propId = bId * 1000
    else
      k = self.GetKey(id)
      propId = bId * 100
    end
    info = dic[k]
    if info == nil then
      iTrace.eError("Loong", self.Name, "无此,id:", id, ",k:", k)
    end
    info.exp = v.val
    info.lock = false
    info.sCfg = BinTool.Find(iSkinCfg, id)
    local maxStar = (info.sCfg.st==nil) and 0 or info.sCfg.st
    local value = v.val
    lstTab[propId] = maxStar
    if maxStar < 5 and id ~= iSkinCfg[1].id then
        isFullSkin = false
    elseif maxStar >= 5 and value > 0 then
      isFullSkin = false
    end
  end
  self.eSkinActive(skinIdTab)
  if isFullSkin == true then
    for i,v in pairs(iCfg) do
      local bId = v.id
      local propId = bId * 100
      local propNum = PropMgr.TypeIdByNum(propId)
      if lstTab[propId] == nil and propNum > 0 and userRelv >= v.rLv then
        isFullSkin = false
      end
    end
  end
  self.flag.isFullSkin = isFullSkin
end

--设置器魂字典的 K
function My:SetSoulKey()
  local dic = self.soulDic
  for i, v in ipairs(self.iQualCfg) do
    local k = tostring(v.id)
    dic[k] = 0
  end
end

--设置器魂字典的 V
function My:SetSoulVal(lst)
  if lst == nil then return end
  local dic, k = self.soulDic, nil
  for i, v in ipairs(lst) do
    k = tostring(v.id)
    dic[k] = v.val
  end
end

--丹药配置条目
--根据当前等级获取最大使用数量
function My:GetUseMax(qCfg)
  local maxs = qCfg.useMax
  local roleLv = UserMgr:GetRealLv()
  local lv, it = 0, nil
  for i = #maxs, 1, (-1) do
    it = maxs[i]
    lv = it.k
    if roleLv >= lv then
      return it.v
    end
  end
  do return 0 end
end

--添加监听
function My:AddLsnr()
  local Add = ProtoLsnr.Add
  Add(self.tcInfoID, self.RespInfo, self)
  Add(self.tcSoulID, self.RespSoul, self)
  Add(self.tcSkinID, self.RespSkin, self)
  Add(self.tcUpgID, self.RespUpg, self)
  Add(self.tcChgID, self.RespChange, self)
  Add(20260, self.RespSkinLv, self)
end

--请求法宝皮肤等级
function My:ReqSkinLv(id, num)
    local msg = ProtoPool.GetByID(20259)
    msg.id = id
    msg.num = num
    ProtoMgr.Send(msg)
end

--响应法宝皮肤等级
function My:RespSkinLv(msg)
    -- iTrace.Error("MSG = "..tostring(msg))
    if self.sysID ~= 2 then
      return
    end
    local err = msg.err_code
    if (err>0) then
          UITip.Error(ErrorCodeMgr.GetError(err))
      return
    end
    local skin = msg.skin
    local id = skin.id
    local exp = skin.val
    self.eRespRefine(id, unlock, exp)

    local k = tostring(math.floor(id * 0.001))
    local info = self.dic[k]
    info.exp = skin.val
    if info.id ~= id then
      info.id = id
      info.sCfg = BinTool.Find(self.iSkinCfg, id)
    --   iTrace.Error("idididiid = "..info.sCfg.id)
    end
    -- local unlock = false
    -- if info.lock then
    --   info.lock = false
    --   unlock = true
    -- end
    -- self.eRespRefine(id, unlock)
end

--设置等级和经验
--lv:等级
--exp:等级经验
function My:SetLv(lv, exp)
  self.lv = lv
  lv = (lv == 0) and 1 or lv
  self.lvCfg = BinTool.Find(self.iLvCfg, lv, "lv")
  self.lastLvExp = self.lvExp
  self.lvExp = exp
end

function My:IsMaxLv()
  if self.lv == self.maxLv then return true end
  return false
end

--获得皮肤完整的道具ID
function My.GetPIdByBId(BId)
  local v = BId * 100
  return v
end

--获得皮肤升级最大ID
function My.GetMaxIdByBId(BId)
  local v = BId * 100 + 5
  return v
end

--获取前5位字符
function My.GetKey(id)
  local v = My.GetBID(id)
  local k = tostring(v)
  return k
end

--获取基础ID
function My.GetBID(id)
  local v = id * My.fact
  v = math.floor(v)
  return v
end

--通过皮肤ID获取基础配置
function My:GetBCfg(id)
  local bid = My.GetBID(id)
  local cfg = BinTool.Find(self.iCfg, bid)
  return cfg
end

--响应升级
function My:RespUpg (msg)
  -- iTrace.Error("msg2 = "..tostring(msg))
  local err = msg.err_code
  local lvChg = false
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  else
    local lv = msg.new_level
    local exp = msg.new_exp
    if self.lv ~= lv then lvChg = true end
    self:SetLv(lv, exp)
    -- iTrace.eLog("Loong", self.Name, " 响应升级,升级前:", My.lv, ",升级后:", lv, ",经验:", exp)
  end
  self.eRespUpg(err, lvChg)
end

--登陆时获取信息
function My:RespInfo(msg)
  -- iTrace.Error("msg = "..tostring(msg))
  self:SetLv(msg.level, msg.exp)
  self.chgID = msg.cur_id
  self:SetInfos(msg.skin_list)
  self:SetSoulVal(msg.soul_list)

  local isFullStep = false
  local isFullQual = true
  local isFullQualTab = self.flag.isFullQualTab
  local qualTab = self.flag.getQualById

  for i, v in pairs(msg.soul_list) do
    local k = v.id
    if qualTab[k] then
      local usedNum = v.val
      local maxUseNum = self:GetUseMax(qualTab[k])
      if usedNum >= maxUseNum then
        isFullQualTab[k].isFull = true
      end
    end
  end
  -- if msg.soul_list == nil or #msg.soul_list == 0 then
  --   isFullQual = false
  -- end
  if self.lv >= self.maxLv then
      isFullStep = true
  end
  self.flag.isFullStep = isFullStep
  self.flag.isFullQual = isFullQual
  self.flag.isFullQualTab = isFullQualTab
  self.flag:Update()
  self:IsExistCurPet()
  self:UpMwAction()
end

--判断当前资源是否存在
function My:IsExistCurPet()
  if self.chgID == 0 or self.chgID == nil then
    return
  end
  if self.sysID == 2 then self.chgID = math.floor(self.chgID * 0.1) end
  local curCfg = self:GetBCfg(self.chgID)
  if curCfg == nil then
    return
  end
  local name = AssetTool.GetSexModName(curCfg)
  local scName = AssetTool.GetSexScModName(curCfg)
  local isExist = AssetTool.IsExistAss(name)
  local scIsExist = AssetTool.IsExistAss(scName)
	if isExist == true and scIsExist == true then
		return
  elseif isExist == false or scIsExist == false then
		self:ReqChange(self.iSkinCfg[1].id)
	end
end

--响应器魂
function My:RespSoul(msg)
  local soul = msg.soul
  local k = tostring(soul.id)
  local val = soul.val
  self.soulDic[k] = val

  local isFullQualTab = self.flag.isFullQualTab
  local qualTab = self.flag.getQualById
  local kid = soul.id
  if qualTab[kid] then
    local usedNum = val
    local maxUseNum = self:GetUseMax(qualTab[kid])
    if usedNum >= maxUseNum then
      isFullQualTab[kid].isFull = true
    end
  end
  self.flag.isFullQualTab = isFullQualTab
  self.flag:Update()
  self:UpMwAction()

  self.eRespSoul()
  --iTrace.eLog("Loong", self.Name, " 响应器魂,id:", id, "使用数量:", val)
end


--响应皮肤升级
function My:RespSkin(msg)
  -- iTrace.Error("msg1 = "..tostring(msg))
  local skin = msg.skin
  local id = skin.id
  local k = 0
  if self.sysID == 2 then
    k = tostring(math.floor(self.GetKey(id) * 0.1))
  else
    k = self.GetKey(id)
  end
  local info = self.dic[k]
  info.exp = skin.val
  if info.id ~= id then
    info.id = id
    info.sCfg = BinTool.Find(self.iSkinCfg, id)

    -- iTrace.Error("id = "..info.sCfg.id)
    self.eStep()
  end
  local unlock = false
  if info.lock then
    info.lock = false
    unlock = true
    local skId = id
    if self.sysID == 2 then
      skId = math.floor(skId * 0.1)
    end
    self.eSkinActive(skId)
  end
  self.eRespRefine(id, unlock)
  --iTrace.eLog("Loong", self.Name, " 响应皮肤升级,msg:", msg, " unlock:", unlock)
end

--请求幻化
--id(number):幻化ID
function My:ReqChange(id)
  local tsChgID = self.tsChgID
  local msg = ProtoPool.GetByID(tsChgID)
  if msg == nil then return end
  msg.cur_id = id
  ProtoMgr.Send(msg)
  --iTrace.eLog("Loong", self.Name, " 协议ID:", tsChgID, "请求幻化:", id)
end

--请求幻化法宝
function My:ReqMwChange(id)
  local msg = ProtoPool.GetByID(20253)
  msg.cur_id = id
  ProtoMgr.Send(msg)
  --iTrace.eLog("Loong", self.Name, " 协议ID:", tsChgID, "请求幻化:", id)
end

--响应幻化
function My:RespChange(msg)
  local err, id = msg.err_code, msg.cur_id
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  else
    self.chgID = id
  end
  self.eRespChange(err)
  --iTrace.eLog("Loong", self.Name, " 响应幻化:", id)
end

--打开对应系统界面
--通过系统ID切换并同时高亮选项按钮
--id:对应打开系统的ID
--secondID：对应打开二级界面的ID 0：不打开   1：打开  2:打开不显示红点
--propId：选中道具id
function My:OpenBySysID(id,secondID,propId)
  self.sysId = id
  self.secondID = secondID
  self.pId = propId
  local open=OpenMgr:IsOpen(tostring(id)) or false
	if open==false then 
		UITip.Log("系统未开启") 
		return
  end
  local active = UIMgr.GetActive(UIAdv.Name)
  -- iTrace.Error("GS","UIAdv active===",active)
  if active ~= -1 then
    return
  end
  UIMgr.Open(UIAdv.Name,My.AdvCb)
end

function My.AdvCb(name)
	local ui = UIMgr.Get(name)
  if ui then 
    if My.sysId then
      ui:SwtichBySysID(My.sysId,My.secondID,My.pId)
    end
	end
end

--坐骑跳转商城
function My:JumpMountStore()
  JumpMgr:InitJump(UIAdv.Name,1)
  self.propid = 30301
  self:OpenShop()
end

--仙峰论剑跳转
function My:JumpArena()
  local isOpen = ActivityMsg.ActIsOpen(10002)
  if isOpen then
    JumpMgr:InitJump(UIAdv.Name,2)
    UIArena.OpenArena(2)
  else
    UITip.Error("活动未开启")
    return
  end
end

--诛仙战场跳转
function My:JumpWar()
  local isOpen = ActivityMsg.ActIsOpen(10001)
  if isOpen then
      JumpMgr:InitJump(UIAdv.Name,2)
      UIArena.OpenArena(4)
  else
      UITip.Error("活动未开启")
      return
  end
end

--跳转宠物副本
function My:JumpPetCopy()
  local other,isOpen = CopyMgr:GetCurCopy("7")
  if isOpen then
      JumpMgr:InitJump(UIAdv.Name,3)
      -- UIMgr.Open(UICopy.Name, self.OpenPetCopy, self)
      UICopy:Show(CopyType.SingleTD)
  else
      UITip.Error("系统未开启")
  end
end

--宠物跳转商城
function My:JumpPetStore()
  JumpMgr:InitJump(UIAdv.Name,3)
  self.propid = 30361
  self:OpenShop()
end

--跳转逍遥神坛
function My:JumpTopFight()
  local isOpen = ActivityMsg.ActIsOpen(10008)
  if isOpen then
      JumpMgr:InitJump(UIAdv.Name,5)
      UIMgr.Open(UITopFightIt.Name)
  else
      UITip.Error("活动未开启")
  end
end

--打开坐骑商城界面
function My:OpenShop()
  local storeId = StoreMgr.GetStoreId(4,self.propid)
  StoreMgr.selectId = storeId
  StoreMgr.OpenStore(4)
end

--根据道具id打开对应提示框（暂时未用到）
function My:OpenPorpTip(tipId)
  if tipId then
    self.tipId = tipId
    UIMgr.Open("PropTip", self.ShowTip, self)
  end
end

--更新法宝红点
function My:UpMwAction()
  local isShow = false
  if self.db and self.db.sysID ~= 2 then
    return isShow
  end
  local dic = MWeaponMgr.dic
  for i,v in ipairs(MWeaponMgr.iCfg) do
    k = tostring(v.id)
    local info = dic[k]
    local cfg = info.sCfg
    local lock = info.lock
    local itemId = 0
    local nextCfg, lv,isFull = AdvInfo:GetMwNextCfg(cfg, MWSkinCfg)

    if lock == true then
      itemId = (cfg.type==1) and cfg.acPropId or cfg.stPropId
    else
      itemId = (cfg.type==1) and nextCfg.lvPropId or nextCfg.stPropId
    end
    if isFull == true then--满级
      isShow = false
    else
      local count = ItemTool.GetNum(itemId)
      local num = (lock==true) and cfg.stNum or nextCfg.stNum
      local curExp = (AdvMgr.mwExp==nil) and info.exp or AdvMgr.mwExp
      local curCount = math.floor(curExp/10)
      local maxCount = (cfg.type==1) and math.floor(cfg.lvExp/10) or 1
      local needCount = (lock==true) and 1 or maxCount-curCount
      local nextCount = (cfg.type==1) and needCount or num
      isShow = (count >= nextCount)
      if isShow == true then break end
    end
  end
  MWeaponMgr.flag.eChange(isShow, 3)
  return isShow
end

--判断某个法宝是否锁定
function My:IsLock(id)
  local dic = MWeaponMgr.dic
  for i,v in ipairs(MWeaponMgr.iCfg) do
    if v.id == id then
      k = tostring(v.id)
      return dic[k].lock
    end
  end
  return false
end

function My:ShowTip(name)
  local ui = UIMgr.Get(name)
  local id = self.tipId
  ui.root.transform.localPosition = Vector3.New(-445,-270,0)
  ui:UpData(id)
end

function My:Clear()
  self:Reset()
end

function My:Dispose()
  PropMgr.eUpdate:Remove(self.Updates, self)
  RebirthMsg.eRefresh:Remove(self.Updates,self)
end

return My
