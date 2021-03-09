--[[
 	authors 	:Liu
 	date    	:2019-4-9 20:00:00
 	descrition 	:化神投资项
--]]

UILvInvestIt = Super:New{Name = "UILvInvestIt"}

local My = UILvInvestIt

function My:Init(go, cfg)
	local trans = go.transform
    local G = ComTool.Get
	local FC = TransTool.FindChild
	
	self.cfg = cfg
	self.cellList = {}
	self.isShowTip = false

	self.go = go

    self.labDes = G(UILabel, trans, "Des")
    self.labCount = G(UILabel, trans, "Count")
    self.labNextCount = G(UILabel, trans, "nextCount")

    self.btnGet = FC(trans, "BtnGet")
	self.labBtnName = G(UILabel, self.btnGet.transform, "Label")
	self.btnSpr = G(UISprite, trans, "BtnGet", des)
    
    self.tips = G(UILabel, trans, "Tips")
	self.hadGet = FC(trans, "HadGet")
	
	self.grid = G(UIGrid, trans, "Grid")

    UITool.SetLsnrSelf(self.btnGet, self.OnGet, self)
end

--更新数据
function My:UpData(type)
	self:UpCell(type)
	self:UpLab(type)
end

--更新金币文本
function My:UpLab(type1)
	local num = 0
	local cfg = self.cfg
	local list = cfg["type"..type1]
	for i,v in ipairs(list) do
		if v.id == 3 then
			num = v.num
		end
	end
	local mgr = LvInvestMgr
	local gold = mgr.investGold
	local type2 = mgr:GetType(gold) or 3
	local temp1 = (type2>type1) and type1 or type2
	local count = mgr:GetTotalCount(cfg.id, temp1)

	local val = mgr.investDic[tostring(cfg.id)]
	if val and type1 == type2 then
		if val ~= mgr.investGold then
			count = mgr:GetCount(cfg.id, temp1)
		end
	end

	local total = mgr:GetTotalCount(cfg.id, type1)
	self.labCount.text = count
	self.labNextCount.text = total
	self.labNextCount.gameObject:SetActive(type1>type2)

	local lv = LvInvestCfg[1].id
	if cfg.id == lv then
		des = "存入当天立返100%绑元"
		mgr.maxGold = total
	else
		local str1 = UIMisc.GetLv(cfg.id)
		local str2 = math.floor(total/mgr.maxGold*100)
		des = string.format("达到%s级可领取%d%%绑元", str1, str2)
	end

	self:SetBtnState()
	if type2 ~= type1 then
		self:UpName(1000)
		self:NoGetState()
		self:UpBtnState(true)
	end

	self.labDes.text = des
	self.tips.gameObject:SetActive(self.isShowTip)
	self.tips.text = "附赠炫酷装饰"
end

--设置按钮状态
function My:SetBtnState()
	local cfg = self.cfg
	local mgr = LvInvestMgr
	local cond1 = mgr.investGold == 0
	local cond2 = User.MapData.Level < cfg.id
	local cond3 = mgr.investDic[tostring(cfg.id)]
	self:UpBtnState(true)
	if cond1 or cond2 then--未领取
		self:UpName(5000)
		self:NoGetState()
	elseif cond3 then--已领取
		if cond3 == mgr.investGold then
			self:UpName(8000)
			self:NoGetState()
			self:UpBtnState(false)
			local list = GlobalTemp["116"].Value2
			if list[3] == mgr.investGold then
				self.isShowTip = false
			end
		else
			self:UpName(1000)
			self:GetState()
		end
	else--可领取
		self:UpName(1000)
		self:GetState()
	end
end

--领取状态
function My:GetState()
	CustomInfo:SetEnabled(self.btnGet, true)
	self.btnSpr.spriteName = "btn_figure_non_avtivity"
	self.labBtnName.text = "[772a2a]领取[-]"
end

--不能领取状态
function My:NoGetState()
	CustomInfo:SetEnabled(self.btnGet, false)
	self.btnSpr.spriteName = "btn_figure_down_avtivity"
	self.labBtnName.text = "[5d5451]领取[-]"
end

--更新按钮状态
function My:UpBtnState(state)
	self.btnGet:SetActive(state)
	self.hadGet:SetActive(not state)
end

--更新道具
function My:UpCell(type)
	local cellList = self.cellList
	local cfg = self.cfg
	local list = {}
	local goldCount = 0
	local temp1 = cfg.type1
	local temp2 = cfg.type2
	local temp3 = cfg.type3
	if type == 1 then
		list = temp1
	elseif  type == 2 then
		list = self:GetNewCfg(temp1, temp2)
	elseif type == 3 then
		local tempList = self:GetNewCfg(temp1, temp2)
		list = self:GetNewCfg(tempList, temp3)
	end

	if #cellList > #list then
		TableTool.ClearListToPool(self.cellList)
		self:SetCell(list)
	elseif #cellList == #list then
		for i,v in ipairs(list) do
			cellList[i]:UpData(v.id)
		end
	else
		TableTool.ClearListToPool(self.cellList)
		self:SetCell(list)
	end
	self.grid:Reposition()
end

--设置道具
function My:SetCell(list)
	for i,v in ipairs(list) do
		local cell = ObjPool.Get(UIItemCell)
		cell:InitLoadPool(self.grid.transform, 0.8)
		local num = (v.id==3) and 1 or v.num
		cell:UpData(v.id, num)
		table.insert(self.cellList, cell)
		self.isShowTip = (i==2)
	end
end

--获取新的配置
function My:GetNewCfg(list1, list2)
	local id = 3
	local list = {}
	local tempList = {}
	for i,v in ipairs(list1) do
		table.insert(tempList, v)
	end
	for i,v in ipairs(list2) do
		table.insert(tempList, v)
	end
	for i,v in ipairs(tempList) do
		if id ~= v.id then
			table.insert(list, v)
		end
	end
	for i,v in ipairs(list2) do
		if v.id == id then
			table.insert(list, v)
			return list
		end
	end
	return list
end

--更新名字
function My:UpName(num)
	self.go.name = self.cfg.id + num
end

--点击领取
function My:OnGet()
	LvInvestMgr:ReqInvestAward(self.cfg.id)
end

--清理缓存
function My:Clear()
	self.isShowTip = false
end

--释放资源
function My:Dispose()
	self:Clear()
	TableTool.ClearListToPool(self.cellList)
end

return My