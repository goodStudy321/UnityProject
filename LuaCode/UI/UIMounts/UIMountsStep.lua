--[[
 	authors 	:Loong
 	date    	:2017-08-20 13:22:51
 	descrition 	:坐骑进阶
--]]

UIMountsStep = Super:New{Name = "UIMountsStep"}
local My = UIMountsStep
local Mm = MountsMgr
local pStorId = 50001 --坐骑进阶丹绑元商城id

function My:Init(root)
  --祝福值倒计时
  self.root = root
  self.gbj = root.gameObject
  local des, CG = self.Name, ComTool.Get
  local TF, TFC = TransTool.Find, TransTool.FindChild
  --进阶按钮
  self.advBtn = CG(UISprite, root, "advBtn", des)
  local advLab = CG(UILabel, root, "advBtn/lbl", des)
  advLab.text = "一键升级"
  --一键进阶标签
  self.aKeyLbl = CG(UILabel, root, "aKeyBtn/lbl", des)

  self.btnRed = TF(root,"advBtn/red",des)

  self.ItemTabGbj = {}
	self.ItemTabObj = {}

	self.icon1 = TFC(root, "propIcons/icon1",des)
	self.icon2 = TFC(root, "propIcons/icon2",des)
  self.ItemTabGbj = {self.icon1,self.icon2}

  self:SetAkeyActive(false)

  local USS, USC = UITool.SetLsnrSelf, UITool.SetLsnrClick
  USS(self.advBtn.gameObject, self.ReqStep, self, des)
  -- USS(self.advBtn.gameObject, self.AdvClick, self, des)
  -- UIEvent.Get(self.advBtn.gameObject).onPress= UIEventListener.BoolDelegate(self.OnPressCell, self)
  -- USC(root, "aKeyBtn", des, self.AKeyClick, self)

  for i = 1,#self.ItemTabGbj do
		local cell = self.ItemTabGbj[i]
		UIEvent.Get(cell.gameObject).onClick = function (gameObject) self:Switch(gameObject); end
	end

  --true 一键升阶中
  My.aKeying = false
  --一键进阶按钮计时器
  My.aKeyCnt = 0
  self.curCell = nil

  self.tog = CG(UIToggle, root,"coin/tog", des)
  self.costNumLab = CG(UILabel,root,"coin/const/num",des)
  self.togLab = CG(UILabel,root,"coin/tog/des",des)
  self.togLab.text = "不足时自动消耗绑元(绑元不足消耗元宝)"
  self.togLabSp = CG(UISprite, root,"coin/const/sp", des)
  self.togLabSp.spriteName = "money_03"
  self.isAutoCost = false
	self.costPNum = 0
  USS(self.tog.gameObject,self.AutoCost,self)
end

--是否勾选自动消耗
function My:AutoCost()
	local val = self.tog.value
	local index = 0
	if val == true then
        index = 1
    else
        index = 0
    end
	PlayerPrefs.SetInt("MountAutoCost", index)
	self.isAutoCost = val
	self:ShowCostNum()
end

function My:ShowAutoCost()
	local isVal = false
	if PlayerPrefs.HasKey("MountAutoCost") then
    local val = PlayerPrefs.GetInt("MountAutoCost")
    if val == 1 then
        isVal = true
    else
        isVal = false
		end
	end
	self.tog.value = isVal
	self.isAutoCost = isVal
	self:ShowCostNum()
end

--显示消耗元宝数量
function My:ShowCostNum()
	local isAuto = self.isAutoCost
	local total, ids = 0, self.db:GetConID()
  local GetNum = ItemTool.GetNum
  local propExp = 0
  for i, v in ipairs(ids) do
    local num = GetNum(v)
		total = total + num
		local cfg = ItemData[tostring(v)]
		local getExp = cfg.uFxArg[1]
		propExp = (num * getExp) + propExp
	end
	-- if total > 0 then
	-- 	isAuto = false
	-- end
	local num = 0
	local needProp = 0
	if isAuto == true then
		local cfg = ItemData["30301"]
    local getExp = cfg.uFxArg[1]
    local curExp = MountsMgr.exp
    if curExp == nil then
      curExp = 0
    end
		local limit = MountsMgr.curCfg.con
    local needExp = limit - (curExp + propExp)
    if needExp > 0 then
      needProp = math.ceil(needExp/getExp)
      local needCost = StoreData[tostring(pStorId)].curPrice --坐骑进阶丹价格
      num = needCost * needProp
    else
      num = 0
    end
	else
		num = 0
	end
	self.costPNum = needProp
	self.costNumLab.text = num
end

function My:OnPressCell(go, isPress)
	if not go then
		return
	end
	if isPress== true then
		self.IsAutoClick = Time.realtimeSinceStartup
	else
		self.IsAutoClick = nil
	end
end

--更新
function My:Update()
  -- if self.aKeying then
  --   self.aKeyCnt = self.aKeyCnt + Time.unscaledDeltaTime
  --   if self.aKeyCnt > 0.5 then
  --     self:AKeyTimeCb()
  --   end
  -- end


  -- local num = ItemTool.GetNum(self.db.curSelectId)
	-- if num <= 0 then
	-- 	return
	-- end

  -- if self.IsAutoClick then
	-- 	if Time.realtimeSinceStartup - self.IsAutoClick > 0.05 then
	-- 		self.IsAutoClick = Time.realtimeSinceStartup
	-- 		self:ReqStep()
	-- 	end
	-- end
end

--设置属性
function My:SetProp()
  self:SetConsume()
  self:SetStar(true)
  self:SetPro()
end

--设置星级
function My:SetStar(reset)
  -- self.rCntr.Step:SetStar(MountsMgr.curCfg.st, reset)
  self.rCntr.Step:SetNewStart(MountsMgr.curCfg.st, reset)
end

--设置消耗
function My:SetConsume()
  -- local id = self.db:GetConID()
  local ids = {}
  local items, it = self.ItemTabObj, nil
  ids = self.db:GetConID()
  local GetNum = ItemTool.GetNum
  if #self.ItemTabObj <= 0 then
    for i = 1,#self.ItemTabGbj do
      local cellGbj = self.ItemTabGbj[i]
			local it = ObjPool.Get(UIItem)
			local id = ids[i]
			it:Init(cellGbj.transform)
			it.root.name = id
			it:RefreshByID(id)
			self.ItemTabObj[id] = it
    end
  else
    for i = 1,#ids do
			local id = ids[i]
			it = items[i]
			it:RefreshByID(id)
		end
  end

  local firstId = ids[1]
  local secondId = ids[2]
  local firstNum = GetNum(firstId)
  local secondNum = GetNum(secondId)

  local totalExp = 0
	local isCanLv = false
	local needExp = 0
	local curExp = MountsMgr.exp
	for i,v in pairs(ids) do
		local num1 = GetNum(v)
		num1 = num1 or 0
		if num1 > 0 then
		  local cfg = ItemData[tostring(v)]
		  local exp = cfg.uFxArg[1] * num1
		  totalExp = totalExp + exp
		end
	end

  local id = MountsMgr.id
	if not id then return end
	local temp =  MountsMgr.GetCfg(id)
	local costExp = temp.con
	needExp = costExp - curExp

	if needExp and totalExp >= needExp then
		isCanLv = true
	end
  self.isCanLv = isCanLv
  if (firstNum > 0 or secondNum > 0) and MountsMgr.flag.isFullStep == false and isCanLv == true then
		self:SetBtnFlag(true,1)
  end
  
	for i = 1,#ids do
		local id = ids[i]
    num = GetNum(id)
    if self.db.curSelectId == secondId and secondNum > 0 then
      cell = self.ItemTabObj[secondId]
			self:Switch(cell.root)
      self.db.curSelectId = secondId
      return
    elseif --[[self.curCell == nil and --]]num > 0 then
			cell = self.ItemTabObj[id]
			self:Switch(cell.root)
      self.db.curSelectId = id
      return
		elseif self.curCell == nil then
			cell = self.ItemTabObj[firstId]
			self:Switch(cell.root)
      self.db.curSelectId = firstId
    elseif secondNum == 0 then
      self.ItemTabObj[secondId]:SetSelect(false)
    end
  end
end

function My:Switch(it)
	local id = tonumber(it.name)
  self.db.curSelectId = id
  local cellSelf = self.ItemTabObj[id]
  if self.curCell == cellSelf then
    PropTip.pos = self.curCell.root.transform.position
		PropTip.width = self.curCell.qtSp.width
    UIMgr.Open("PropTip", self.ShowTip, self)
		return
	end
	if self.curCell then
		self.curCell:SetSelect(false)
	end
	cellSelf:SetSelect(true)
  self.curCell = cellSelf
end

function My:ShowTip(name)
	local ui = UIMgr.Get(name)
	local id = self.curCell.cfg.id
	ui:UpData(id)
end

function My:SetItemNum()
  local id = self.db.curSelectId--self.db.GetConID()
  self.ItemTabObj[id]:Refresh()
end

--检查进阶条件
--show(显示提示)
function My:CheckAdv(show)
  local itID = self.db.curSelectId--self.db.GetConID()
  local res = ItemTool.NumCond(itID, 1, show)
  return res
end

--点击进阶事件
function My:AdvClick(go)
  if self.aKeying then return end
  self:ReqStep()
end

--点击一键进阶事件
function My:AKeyClick(go)
  if self.aKeying then
    self:AkeyStop()
  else
    if not self:ReqStep() then return end
    self.aKeying = true
    self.aKeyCnt = 0
    self:SetAkeyActive(true)
  end
end

--设置一键升阶时相关按钮状态
--at(boolean):true,激活状态
function My:SetAkeyActive(at)
  local color = Color.var
  color.g = 1
  color.b = 1
  color.a = 1
  if at == true then
    color.r = 0
    self.aKeyLbl.text = "停止进阶"
    self.advBtn.color = color
  else
    color.r = 1
    self.aKeyLbl.text = "一键进阶"
    self.advBtn.color = color
  end
end

--请求进阶
function My:ReqStep(show)
  local total, ids = 0, self.db:GetConID()
	local GetNum = ItemTool.GetNum
  	for i, v in ipairs(ids) do
    	total = total + GetNum(v)
	end

  local id = 30301
  local isAutoC = self.isAutoCost
	local pNum = self.costPNum
  -- local num = ItemTool.GetNum(self.db.curSelectId)
  if self.db.flag.isFullStep == true then
    MsgBox.ShowYes("不能再继续升级")
    return
  end

  if total < 1 or self.isCanLv == false then
    if isAutoC == false then
      if total >= 1 then
				for i, v in ipairs(ids) do
					local num = GetNum(v)
					if num > 0 then
						PropMgr.ReqUse(v, num, 1)
					end
				end
				return
			end
      -- local itID = id
      local itID = self.db.curSelectId
			local isSkin = false
			local sysId = 1
			GetWayFunc.AdvGetWay(UIAdv.Name,sysId,itID,isSkin)
	  	-- UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
      return 
    elseif isAutoC == true then
			local isEnough=StoreMgr.QuickBuy(pStorId,pNum,false)
      if isEnough then
        for i, v in ipairs(ids) do
          local num = GetNum(v)
          if v == id then
            num = num + pNum
          end
          if num > 0 then
            PropMgr.ReqUse(v, num, 1)
          end
        end
				-- PropMgr.ReqUse(id, pNum,1)
			end
			return
    end
  end
  
  for i, v in ipairs(ids) do
		local num = GetNum(v)
		if num > 0 then
			PropMgr.ReqUse(v, num, 1)
		end
  end
  -- self.db.ReqStep()
  return true
end

function My:OpenShop()
  local storeId = StoreMgr.GetStoreId(4,My.db.curSelectId)
	StoreMgr.selectId = storeId
	StoreMgr.OpenStore(4)
end

--获取途径界面回调
function My:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
  ui:SetPos(Vector3(85,-110,0))
	local petGetWay = AdvGetWayCfg[1].wayDic
	local len = #petGetWay
	for i = 1,len do
		local wayName = petGetWay[i].v
		ui:CreateCell(wayName, self.OnClickGetWayItem, self)
	end
end

function My:OnClickGetWayItem(name)
	if name == "商城" then
		AdvMgr:JumpMountStore()
	end
end

--一键升级终止
function My:AkeyStop()
  self.aKeying = false
  self:SetAkeyActive(false)
end

function My:AKeyTimeCb()
  if self:ReqStep(false) then
    self.aKeyCnt = 0
  else
    self:AkeyStop()
  end
end

--响应进阶
--upstep:等阶提升
function My:RespStep()
  self:SetConsume()
  local rCntr = self.rCntr
  ParticleUtil.Play(rCntr.fxStepSucGo)
  self.rCntr.Step.proSpFx1:SetActive(true)
  -- rCntr:PlayLvFx(pos)
  self:SetPro()
end

function My:SetPro()
  local tExp = MountsMgr.curCfg.con * 1.0
  self.rCntr.Step:SetSlider(MountsMgr.exp, tExp)
  -- self:ShowCostNum()
end

function My:UpStep()
  self:AkeyStop()
  self:SetConsume()
  self:SetStar(true)
  local bid = MountsMgr.bid
  local cfg = BinTool.Find(MountCfg, bid)
  if cfg == nil then
    iTrace.Error("Loong", "无ID为:", bid, "坐骑基础配置")
  else
    UIShowGetCPM.OpenCPM(cfg.uMod)
  end
end

function My:Refresh()
  self:SetProp()
end

--设置激活状态
function My:SetActive(at)
  at = at or false
  if at == self.active then return end
  if at then
    self:Open()
  else
    self:Close()
  end
end

--清除坐骑升级消耗texture
function My:ClearIcon()
	if self.ItemTabObj then
	  for k,v in pairs(self.ItemTabObj) do
		  v:ClearIcon()
	  end
	end
end

function My:ItemToPool()
	local len = #self.ItemTabObj
	while len > 0 do
	  local item = self.ItemTabObj[len]
	  if item then
      table.remove(self.ItemTabObj, len)
      ObjPool.Add(item)
	  end
	  len = #self.ItemTabObj
	end
end

function My:ItemGbjD()
	local len = #self.ItemTabGbj
	while len > 0 do
	  local item = self.ItemTabGbj[len]
	  if item then
		table.remove(self.ItemTabGbj, len)
	  end
	  len = #self.ItemTabGbj
	end
end

function My:SetBtnFlag(red,index)
  if index == 1 then
    if not LuaTool.IsNull(self.btnRed) then
      self.btnRed.gameObject:SetActive(red)
    end
	end
end

function My:Open()
  self.gbj:SetActive(true)
  self.rCntr.Step:Open()
  self.active = true
  self:SetProp()
  self:ShowAutoCost()
  PropMgr.eUpdate:Add(self.SetConsume, self)
  MountsMgr.flag.eChange:Add(self.SetBtnFlag, self)
end

function My:Close()
  self.curCell = nil
  self.IsAutoClick = nil
  self.gbj:SetActive(false)
  self.rCntr.Step:Close()
  --self:ClearIcon()
  self.active = false
  self:AkeyStop()
  PropMgr.eUpdate:Remove(self.SetConsume, self)
  MountsMgr.flag.eChange:Remove(self.SetBtnFlag, self)
end

function My:Dispose()
  -- TableTool.ClearListToPool(self.ItemTabObj)
  self:ClearIcon()
  self:ItemToPool()
  self:ItemGbjD()

  self.curCell = nil
  self:AkeyStop()
  PropMgr.eUpdate:Remove(self.SetConsume, self)  --SetItemNum
end

return My
