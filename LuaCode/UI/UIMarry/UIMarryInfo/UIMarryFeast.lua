--[[
 	authors 	:Liu
 	date    	:2018-12-13 10:00:00
 	descrition 	:预约婚宴界面
--]]

UIMarryFeast = Super:New{Name = "UIMarryFeast"}

local My = UIMarryFeast

require("UI/UIMarry/UIMarryInfo/UIMarryFeastIt")

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local SetB = UITool.SetBtnClick
	local Find = TransTool.Find
	local FindC = TransTool.FindChild

	local item = FindC(root, "feastTimeBg/Scroll View/Grid/item", des)

	self.grid = Find(root, "awardSpr/Grid", des)
	self.countLab = CG(UILabel, root, "countLab")
	self.panel = CG(UIPanel, root, "feastTimeBg/Scroll View")

	self.str = ""
	self.index = 0
	self.itList = {}
	self.cellList = {}
	self.go = root.gameObject

	SetB(root, "btn", des, self.OnSure, self)
	SetB(root, "close", des, self.OnClose, self)

	self:InitItems(item)
	self:UpCountLab()
	self:SetLnsr("Add")
	self:InitAppointList()
	self:InitCell()
end

--设置监听
function My:SetLnsr(func)
	MarryMgr.eAppointInfo[func](MarryMgr.eAppointInfo, self.RespAppointInfo, self)
	MarryMgr.eAppoint[func](MarryMgr.eAppoint, self.RespAppoint, self)
	MarryMgr.ePopClick[func](MarryMgr.ePopClick, self.RespPopClick, self)
end

--响应弹窗点击
function My:RespPopClick(isAllShow)
	if isAllShow and self.go.activeSelf then
		local select = self:GetSelect()
		MarryMgr:ReqAppoint(select)
    end
end

--响应预约
function My:RespAppoint()
	self:UpAppointList()
	self:UpCountLab()
	UIMarryInfo:Close()
	UIProposePop:OpenTab(3)
end

--响应预约列表
function My:RespAppointInfo()
	self:UpAppointList()
	self:GetIndex()
	self:SetSView()
end

--获取当前能预约的项
function My:GetIndex()
	for i,v in ipairs(self.itList) do
		if v.isCanAppoint then
			self.index = v.index
			return
		end
	end
end

--设置Scroll View
function My:SetSView()
	local index = self.index
	local v3 = Vector3.zero
	local v2 = Vector2.zero
	if index == 0 or index >= 19 then
		v3 = Vector3.New(-2811, 0, 0)
		v2 = Vector2.New(2811, 0)
	elseif index == 1 then
		v3 = Vector3.New(-1, 0, 0)
		v2 = Vector2.New(1, 0)
	else
		v3 = Vector3.New( -(((index-1) * 155) + 1), 0, 0)
		v2 = Vector2.New( ((index-1) * 155) + 1, 0)
	end
	self.panel.transform.localPosition = v3
	self.panel.clipOffset = v2
end

--初始化道具
function My:InitCell()
	local cfg = GlobalTemp["77"]
	if cfg then
		for i,v in ipairs(cfg.Value2) do
			local it = ObjPool.Get(UIItemCell)
			it:InitLoadPool(self.grid, 0.8)
			it:UpData(v, 1)
			table.insert(self.cellList, it)
		end
	end
end

--更新预约列表
function My:UpAppointList()
	local dic = MarryInfo.feastData.hourDic
	for i,v in ipairs(self.itList) do
		local key = tostring(v.index)
		if dic[key] then
			v:UpState(false)
			v.select:SetActive(false)
		end
	end
end

--初始化预约列表
function My:InitAppointList()
	local data = MarryInfo.data.coupleInfo
	if data then
		MarryMgr:ReqAppointInfo()
	end
end

--更新婚宴次数文本
function My:UpCountLab()
	local info = MarryInfo.data
	if info.coupleInfo then
		local str = string.format("[FFE400FF]剩余预约次数：[-]%s次", info.count)
		self.countLab.text = str
	end
end

--初始化结婚时间项
function My:InitItems(item)
	local Add = TransTool.AddChild
	local parent = item.transform.parent
    for i=1, 24 do
		local go = Instantiate(item)
		local tran = go.transform
		Add(parent, tran)
		local it = ObjPool.Get(UIMarryFeastIt)
		table.insert(self.itList, it)
		it:Init(tran, i, self.itList)
    end
    item:SetActive(false)
end

--点击马上预约按钮
function My:OnSure()
	local select = self:GetSelect()
	if select == nil then
		UITip.Log("请先预约")
		return
	end
	if MarryInfo.data.count < 1 then
		UITip.Log("次数不足")
		return
	end
	local it = self.itList[select]
	if it then
		if it:IsOverdue() then
			it.select:SetActive(false)
			it:SetState(false, false, true)
			UITip.Log("时间已过，不能预约")
			return
		end
	end
	if MarryInfo:IsAppoint() then
		UITip.Log("同时只能预约一场婚宴")
		return
	end
	if select == 24 then
		self.str = string.format("[FFE9BDFF]您将预约今天[88F8FFFF]00:00-00:15[-]的豪华婚宴")
	else
		self.str = string.format("[FFE9BDFF]您将预约今天[88F8FFFF]%s:00-%s:15[-]的豪华婚宴", select, select)
	end
	UIMgr.Open(UIMarryPop.Name, self.OpenPop, self)
end

--打开弹窗
function My:OpenPop()
    local ui = UIMgr.Get(UIMarryPop.Name)
    if ui then
        ui:UpPanel(self.str, true)
    end
end

--获取当前选择的场次
function My:GetSelect()
	for i,v in ipairs(self.itList) do
		if v.select.activeSelf then
			return i
		end
	end
	return nil
end

--点击关闭
function My:OnClose()
	UIMarryInfo:SetMenuState(1)
end

--清理缓存
function My:Clear()
    self.str = ""
end
    
--释放资源
function My:Dispose()
	self:Clear()
	self:SetLnsr("Remove")
	TableTool.ClearListToPool(self.cellList)
end
    
return My