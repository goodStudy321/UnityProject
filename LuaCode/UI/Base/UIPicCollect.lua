--region UIPicCollect.lua
--Date
--此文件由[HS]创建生成
require("UI/UIPicCollect/UIPicCollectPros")
require("UI/UIPicCollect/UIPicCollectStars")
require("UI/UIPicCollect/UIPicCollectItem")
require("UI/UIPicCollect/UIPicCollectGroup")
require("UI/UIPicCollect/UIPicCollectProView")
require("UI/UIPicCollect/UIPicCollectGroupPro")
require("UI/UIPicCollect/UIPicCollectStepGroup")
require("UI/UIPicCollect/UIPicCollectDevourView")
require("UI/UIPicCollect/UIPicCollectList")

UIPicCollect = UIBase:New{Name ="UIPicCollect"}
local M = UIPicCollect
local PCMgr = PicCollectMgr

M.DefaultOpen = 1 --1默认 2卡组 3.分解

M.DefaultType = 1
M.DefaultGroup = 1
M.DefaultPic = nil

function M:InitCustom()
	self.Persitent = true;
	local name = "图鉴"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Base = T(trans, "Base")

	self.Panel = C(UIPanel, trans, "Base/List",name, false)
	self.DefaultPos = self.Panel.transform.localPosition
	self.UISV = C(UIScrollView, trans, "Base/List",name, false)
	self.List = {}
	for i=1,3 do
		local data = ObjPool.Get(UIPicCollectList)
		data:Init(T(trans, "Base/List/Table/Quest"..i), self)
		table.insert(self.List, data)
	end

	self.Tog1 = T(trans, "Base/Tog1")
	self.Tog2 = T(trans, "Base/Tog2")
	self.Tog1Action = T(trans, "Base/Tog1/Action")
	self.Tog2Action = T(trans, "Base/Tog2/Action")

	self.PicGroup = ObjPool.Get(UIPicCollectGroup)
	self.PicGroup:Init(T(trans, "Base/Pics"), self)

	self.ProView = ObjPool.Get(UIPicCollectProView)
	self.ProView:Init(T(trans, "Base/Pros"), self)

	self.DevourView = UIPicCollectDevourView.New(T(trans, "Base/DevourView"))
	self.DevourView:Init()

	self.StepTitle = C(UILabel, trans, "Base/StepView/Step", name, false)
	self.StepAction = T(trans, "Base/StepView/Action")
	self.StepPros = ObjPool.Get(UIPicCollectPros)
	self.StepPros:Init(T(trans, "Base/StepView/Pros"))
	

	self.GroupView = ObjPool.Get(UIPicCollectStepGroup)
	self.GroupView:Init(T(trans, "Group"), self)
	
	local E = UITool.SetLsnrSelf
	self.StepView = T(trans, "Base/StepView")
	self.CloseBtn = T(trans, "Base/CloseBtn")
end

function M:AddEvent()
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
	
	local E = UITool.SetLsnrSelf
	E(self.StepView, self.ShowGroupView, self, nil, false)
	E(self.Tog1, self.OnClickTog1, self, "", false)
	E(self.Tog2, self.OnClickTog2, self, "", false)
	E(self.CloseBtn, self.Close, self)
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
end

function M:UpdateEvent(M)	
	--M("OnChangeLv", self.OnChangeLevel)
end

function M:SetEvent(fn)
	PCMgr.eUpdatePic[fn](PCMgr.eUpdatePic, self.UpdatePic, self)
	PCMgr.ePicEssence[fn](PCMgr.ePicEssence, self.UpdateEssence, self)
	PCMgr.eGroupActive[fn](PCMgr.eGroupActive, self.UpdateGroupActive, self)
	PCMgr.ePicRed[fn](PCMgr.ePicRed, self.UpdatePicRed, self)
	PCMgr.eResolveRed[fn](PCMgr.eResolveRed, self.UpdateResolveRed, self)
	PCMgr.eUpdateEssence[fn](PCMgr.eUpdateEssence, self.UpdateEssence, self)
	FightVal.eChgFv[fn](FightVal.eChgFv, self.UpdateFight, self)
end


--更新分类数据
function M:UpdateList()
	if not self.List then return end
	local len = #self.List 
	for i=1,len do
		self.List[i]:UpdateData(i, PCMgr.TypeDic[i])
		if i == self.DefaultType then
			self.List[i]:OpenDefault()
		end
	end
end

--选中图组
function M:SelectPicGroup(go)
	self:Reposition()
	local name = go.name
	if StrTool.IsNullOrEmpty(name) == true then return end
	local keys = string.split(name, "_")
	local tkey = tonumber(keys[1])
	local gkey = tonumber(keys[2])
	local list = self.List
	if self.SelectType ~= nil and self.SelectType ~= tkey then
		if list and #list >= self.SelectType then
			list[self.SelectType]:ShowSelect(nil)
		end
	end
	self.SelectType = tkey
	self.SelectGroup = gkey
	if list and #list >= tkey then
		list[tkey]:ShowSelect(name)
	end

	local groupV = self.PicGroup
	if groupV then
		groupV:ShowGroup(tkey, gkey)
		groupV:OpenDefault()
	end
	self:UpdateStepGroup(tkey, gkey)
end

--选中图片
function M:SelectPic(go)
	self:Reposition()
	local key = go.name
	if StrTool.IsNullOrEmpty(key) == true then return end
	self.SelectID = tonumber(key)
	local pic = PCMgr:GetPic(self.SelectType, self.SelectGroup, self.SelectID)
	if not pic then return end
	local proV = self.ProView
	if proV then
		proV:ShowData(pic)
	end
end

function M:UpdateStepGroup(tkey, gkey)
	self:UpdateStepGroupRed()
	local temp, num = PCMgr:GetStepGroup(tkey, gkey)
	if temp then
		if self.StepTitle then
			self.StepTitle.text = string.format("目标属性：%s （激活卡片星级数量：%s/%s）", temp.title, num, temp.stars)
		end
		if self.StepPros then
			self.StepPros:UpdateProTemp(temp)
		end
	else
		temp, num = PCMgr:GetStepGroup(tkey, gkey, true)
		if self.StepTitle then
			self.StepTitle.text = "所有等阶属性已经全部激活"
		end
		if self.StepPros then
			self.StepPros:Clear()
		end
	end
	self.ProTemp = temp
end

function M:UpdatePic(data)
	if not data then return end
	local key = tostring(data.Temp.id)
	local temp = PicCollectTemp[key]
	if not temp then return end
	local tkey = temp.type
	local gkey = temp.group
	if self.SelectType == tkey and self.SelectGroup == gkey then
		if self.PicGroup then
			self.PicGroup:UpdatePic(temp, data)
		end
		self:UpdateStepGroup(tkey, gkey)
		if self.SelectID == data.Temp.picId then
			local proV = self.ProView
			if proV then
				proV:ShowData(data)
			end
		end
	end
end

function M:UpdateEssence()
	local pView = self.ProView
	if pView then
		pView:UpdateEssence()
	end
end

function M:UpdateFight()
	local pView = self.ProView
	if pView then
		pView:UpdateAllFight()
	end
end

function M:UpdateGroupActive(id)
	if self.SelectType and self.SelectGroup then
		self:UpdateStepGroup(self.SelectType, self.SelectGroup)
	end
	local view = self.GroupView 
	if view then
		view:UpdateGroupActive(id)
	end
end

function M:UpdateRed()
	local action1 = self.Tog1Action 
	if action1 then
		action1:SetActive(SystemMgr:GetActivityPage(ActivityMgr.TJ, 1))
	end
	local action2 = self.Tog2Action 
	if action2 then
		action2:SetActive(SystemMgr:GetActivityPage(ActivityMgr.TJ, 2))
	end
end

function M:UpdatePicRed()
	local action1 = self.Tog1Action 
	if action1 then
		action1:SetActive(SystemMgr:GetActivityPage(ActivityMgr.TJ, 1))
	end
	local list = self.List
	for i,v in ipairs(list) do
		v:UpdateAction()
	end
	local pGroup = self.PicGroup
	if pGroup then
		pGroup:UpdateAction()
	end
	local proView = self.ProView
	if proView then
		proView:UpdateUAction()
	end
	local groupView = self.GroupView
	if groupView then
		groupView:UpdateAction()
	end
	self:UpdateStepGroupRed()
end

function M:UpdateStepGroupRed()
	local value = self.SelectGroup
	local action = self.StepAction
	if action then
		action:SetActive(PCMgr:GetGroupProViewToRed(value))
	end
end

function M:UpdateResolveRed()
	local proView = self.ProView
	if proView then
		proView:UpdateRAction()
	end
end

function M:ShowBaseView()
	self:SetView(true)
end

function M:ShowGroupView()
	if not self.ProTemp then return end
	self:SetView(false)
	if self.GroupView then
		self.GroupView:UpdateData(self.SelectType, self.ProTemp)
	end
end

function M:ShowDevourView()
	if self.DevourView then
		self.DevourView:SetActive(true)
	end
end

function M:SetView(value)
	if self.Base then
		self.Base:SetActive(value)
	end
	if self.GroupView then
		self.GroupView:SetActive(not value)
	end
end

function M:OnClickTog1()
	-- body
end

function M:OnClickTog2()
	local temp = SystemOpenTemp["56"]
	if not temp then 
		iTrace.eError("hs","系统开放表没有[56]神兽配置")
		return 
	end
	local lv = temp.trigParam
	if User.MapData.Level >= lv and SoulBearstMgr:IsOpen() == true then
		UIMgr.Open(UISoulBearst.Name)
	else 
		UITip.Error(string.format("兽魂将于%s级开启",lv))
	end
end

function M:Reposition()
	local panel = self.Panel
	if panel then
		panel:Refresh()
	end
	local uisv = self.UISV
	if uisv then
		uisv:DisableSpring()
	end
	if self.Panel then
		self.Panel.transform.localPosition = self.DefaultPos
		if self.Panel then
			self.Panel.clipOffset = Vector2.zero
		end
	end
end

--通过索引打开分页
--t1(number)1级分页索引:0:代表无分页
--t2(number)2级分页索引
--t3(number)3级分页索引
--t4(number)4级分页索引
function M:OpenTabByIdx(t1, t2, t3, t4)
	-- body
end

function M:OpenCustom()
	self:UpdateList()
	self:ShowBaseView()
	self:UpdateRed()
	self:AddEvent()
	local defaultOpen = self.DefaultOpen
	if defaultOpen == 2 then
		self:ShowGroupView()
	elseif defaultOpen == 3 then
		self:ShowDevourView()
	end
end

function M:CloseCustom()
	self:RemoveEvent()
	self.DefaultOpen = 1 --1默认 2卡组 3.分解
	self.DefaultType = 1
	self.DefaultGroup = 1
	self.DefaultPic = nil
end

function M:DisposeCustom()

	self.StepTitle = nil

	if self.List then
		local len = #self.List
		while len > 0 do
			local data = self.List[len]
			if data then
				data:Dispose()
				ObjPool.Add(self.List[len])
			end
			table.remove(self.List, len)
			len = #self.List
		end
	end

	if self.StepPros then
		self.StepPros:Dispose()
		ObjPool.Add(self.StepPros)
	end

	if self.ProView then
		self.ProView:Dispose()
		ObjPool.Add(self.ProView)
	end

	if self.PicGroup then
		self.PicGroup:Dispose()
		ObjPool.Add(self.PicGroup)
	end
end

return M

--endregion
