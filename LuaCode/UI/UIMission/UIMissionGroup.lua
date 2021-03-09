--region UIMission.lua
--Date
--此文件由[HS]创建生成

UIMissionGroup = Super:New{Name ="UIMissionGroup"}
local M = UIMissionGroup
local mMgr = MissionMgr
local OnKeyInfo = GlobalTemp["119"]

function M:Init(go, parent)
	self.Root = go
	self.Parent = parent
	local name = "UIMissionGroup"
	local trans = self.Root.transform
	local T = TransTool.FindChild
	local C = ComTool.Get

	self.ListView = ObjPool.Get(UIMissionGroupList)
	self.ListView:Init(go, self)

	self.Des = C(UILabel, trans, "Des", name, false)
	self.DesLab = C(UILabel, trans, "Des/Label", name, false)
	self.Target = C(UILabel, trans, "Target", name, false)
	self.Reward = T(trans, "Reward")
	self.RGrid = C(UIGrid, trans, "Reward/Grid", name, false)
	self.CBtn = T(trans, "Complete")
	self.Btn = T(trans, "Button")
	self.MenuTip = self.Btn:GetComponent("UIMenuTip")
	self.BtnLab = C(UILabel, trans, "Button/Label", name, false)
	self.LvLab = C(UILabel, trans, "Lv", name, false)
	self.CurLab = C(UILabel, trans, "Cur", name, false)
	self.Cells = {}
	--压入卡等级引导
	self.MenuTip:Clear()
	local items = self.MenuTip.items
	local list = MissGuideTemp
	for i=1,#list do
		local temp = list[i]
		if temp then 
			items:Add(temp.des)
		end
	end
	self.Succ = 0
	self.Ring = 0
	self.OnClickMenuTipAction = EventHandler(self.ClickMenuTip, self)
	EventMgr.Add("ClickMenuTipAction", self.OnClickMenuTipAction)
	UITool.SetLsnrSelf(self.CBtn, self.ClickCBtn, self)
	UITool.SetLsnrSelf(self.Btn, self.ClickBtn, self)
end

function M:UpdateDic(dic)
	local listview = self.ListView
	if listview then
		listview:UpdateDic(dic)
	end
end

function M:UpdateItems()
	local listview = self.ListView
	if listview then
		listview:UpdateItems()
	end
end

function M:UpdateItem(mission)
	if LuaTool.Length(mission) == 0 then return end
	local listview = self.ListView
	if listview then
		listview:UpdateItem(mission)
	end
end

function M:UpdateData(id)
	local mission = mMgr:GetMissionForID(id)
	if not mission then return end
	local temp = mission.Temp 
	if not temp then return end
	self.Succ = 0
	self.Ring = 0
	local des = self.Des
	local target = self.Target
	local desLab = self.DesLab
	if desLab then
		local lab = "章节描述"
		if temp.type ~= MissionType.Main then
			lab = "任务描述"
		end
		desLab.text = lab
	end
	if des then des.text = mission.Temp.cDes end
	if target then target.text = mission:GetTargetDes("42db70", false) end
	self:UpdateReward(mission)
	self:UpdateBtn(mission)
	self:UpdateMenuTip(mission)
end

function M:UpdateBtn(mission)
	local btnlab = self.BtnLab
	local lvlab = self.LvLab
	local show = false 
	local str = "前往执行"
	local temp = mission.Temp
	if temp then
		if temp.lv > User.MapData.Level then
			show = true
			str = "前往升级"
		end
		if mission.Status == MStatus.ALLOW_SUBMIT then
			if not temp.npcSubmit or temp.npcSubmit == 0 then
				str = "领取奖励"
			end
		end
	end
	if btnlab then
		btnlab.text = str
	end
	if lvlab then
		lvlab.gameObject:SetActive(show)
		lvlab.text = string.format("%s级开启", mission.Temp.lv)
	end
end

function M:UpdateReward(mission)
	self:CleanReward()
	if not mission then return end
	local temp = mission.Temp
	if not temp then return end
	if temp.type ~= MissionType.Escort then
		self:UpdateMissionReward(temp)
	else
		self:UpdateEscortReward()
	end
	self:UpdateCur(mission)
	self.RGrid:Reposition()
end

function M:UpdateMissionReward(temp)
	local exp = temp.exp
	local item = temp.item
	if exp and exp ~= 0 then
		if temp.expType == 0 then
			self:AddItemData(100, exp, false)
		else
			self:AddItemData(100, PropTool.GetExp(exp/10000), false)
		end
	end
	if item then
		local count = #item
		for i = 1, count do
			local data = item[i]
			if data and data.id ~= 0 then
				self:AddItemData(data.id, data.num, data.bind == 1)
			end
		end
	end
end

function M:UpdateEscortReward()
	local temp = EscortTemp[tostring(EscortMgr.FairyID)]
	if not temp then return end
	local isDouble = false
	local data = LivenessInfo:GetActInfoById(1012)
	if data then 
		isDouble = data.val == 1
	end
	local copper = temp.r_copper
	if isDouble == true then copper = copper * 2 end
	if copper and copper > 0 then
		self:AddItemData(1, copper, false)
	end
	local lv = User.MapData.Level
	local lvTemp = LvCfg[lv]
	if lvTemp then
		local exp = Mathf.Floor(lvTemp.exp * (temp.expRatio / 10000))
		if isDouble == true then exp = exp * 2 end
		if exp > 0 then
			self:AddItemData(100, exp, false)
		end
	end
	self.Grid:Reposition()
end


--add奖励
function M:AddItemData(id, value, bind)
	if value == 0 then return end
	local key = tostring(id)
	local dicKey = key..tostring(bind)
	if self.Cells[dicKey] then return end
	local item = ItemData[key]
	if not item then
		local create = ItemCreate[key]
		if create then
			local cate = User.MapData.Category
			if cate == 1 then
				item = ItemData[tostring(create.w1)]
			else
				item = ItemData[tostring(create.w2)]
			end
		end
		if not item then 
			iTrace.eLog("hs",string.format("任务奖励道具ID[%s]不存在",key))
			return 
		end
	end
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(self.RGrid.transform)
	cell.trans.name = tostring(id)
	cell:UpData(item, tonumber(value))
	cell:UpBind(bind)
	table.insert(self.Cells, cell)
end

function M:UpdateCur(mission)
	if not mission or not mission.Temp then return end
	local btn = self.CBtn
	if btn and btn.activeSelf == false then return end
	local t = mission.Temp.type
	local mType = MissionType
	if t == mType.Turn or t == mType.Family then
		local succ = mission.Succ % mission.Temp.ring
		local ring = mission.Temp.ring
		if succ == 0 then
			succ = mission.Temp.ring
		end
		local lab = self.CurLab
		if lab then
		lab.text = string.format("本轮任务(%s/%s)", succ, ring)
		self.Succ = succ
		self.Ring = ring
		end
	end
end

function M:ChangePos(value)
	local des = self.Des
	local target = self.Target
	local reward = self.Reward
	if des then des.gameObject:SetActive(not value) end
	if target then 
		local pos = Vector3.New(-93.4, 18.49 ,0)
		if value == true then
			pos = Vector3.New(-93.4, 146.8 ,0)
		end
		target.transform.localPosition = pos
	end
	if reward then
		local pos = Vector3.New(-53.6, -142 ,0)
		if value == true then
			pos = Vector3.New(-53.6, -18.1 ,0)
		end
		reward.transform.localPosition = pos
	end
end

function M:Reset(reset, resetGrid)
	self:CleanReward()
	local listview = self.ListView
	if listview then
		listview:Reset(reset, resetGrid)
	end
end

function M:ChangeLv()
	local listview = self.ListView
	if listview then
		listview:ChangeLv()
	end
end

function M:CleanMission(id)
	local listview = self.ListView
	if listview then
		listview:CleanMission(id)
	end
end

function M:UpdateMenuTip(mission)
	if not self.MenuTip then return end
	local miss = mission
	if not miss then return end
	local bool = miss.Temp and miss.Temp.type == MissionType.Main and miss:CheckLevel()
	local isCount = true
	if bool == true then
		local indexs = self.MenuTip.customIndex
		indexs:Clear()
		local list = MissGuideTemp
		for i=1,#list do
			local temp = list[i]
			if temp and User.MapData.Level >= temp.openlv then
				indexs:Add(i - 1) 
			end
		end
		isCount = indexs.Count > 0
	end
	self.MenuTip.IsEnabled = bool and isCount
end

function M:ClickMenuTip(name, tt, str, index)
	if not tt or tt ~= MenuType.MissionGroup then return end
	if self.MenuTip == nil then return end
	local menus = self.MenuTip.items
	if not menus then return end
	local index = menus:IndexOf(str)
	MissionMgr:ClickMenuTip(index)
end

function M:IsOpenCBtn()
	local vip = VIPMgr.GetVIPLv() >= OnKeyInfo.Value2[2]
	local lv = User.MapData.Level >= OnKeyInfo.Value2[1]
	if vip == true or lv == true then return true end
	return false
end

function M:ClickCBtn(go)
	local vip = VIPMgr.GetVIPLv() >= OnKeyInfo.Value2[2]
	local lv = User.MapData.Level >= OnKeyInfo.Value2[1]
	if vip == false then
		if lv == true then		
			local cost = (self.Ring - self.Succ) * OnKeyInfo.Value3
			
			local msg = string.format("本轮道庭任务进度：[00FF00](%s/%s)[-]\n 是否消耗[00ff00]%s[-]元宝，完成一轮任务\n（优先消耗绑元）", self.Succ, self.Ring, cost)
			MsgBox.ShowYes(msg,self.OnKeyComplete, self, "确定")
			return
		end
		MsgBox.ShowYes("一键完成功能 VIP4 可用\n是否立即前往",self.OpenVip, self, "立即前往")
	else
		MissionNetwork:ReqMissionOnKey(MissionType.Family)
	end
	
end

function M:OpenVip()
	VIPMgr.OpenVIP()
end

function M:OnKeyComplete(check)
	if check == nil then check = true end
	if check == true then
		if RoleAssets.IsEnoughAsset(3, OnKeyInfo.Value3) == false then			
			MsgBox.ShowYesNo("元宝不足，是否充值？",M.InvestMoney)
			return
		end
	end
	MissionNetwork:ReqMissionOnKey(MissionType.Family)
end

function M:InvestMoney()
	VIPMgr.OpenVIP(1)
end

function M:ClickBtn(go)
	local listview = self.ListView
	if not listview then return end
	local miss = listview:GetMission() 
	if not miss then return end
	if miss:NotAllowExecute(false) == true then
		return
	end
	local temp = miss.Temp
	if miss:CheckLevel() == true then return end
	if miss.Status == MStatus.COMPLETE then return end
	Hangup:ClearAutoInfo()
	User:ResetMisTarID()
	mMgr:Execute(false)
	if miss.Temp and miss.Temp.type == MissionType.Feeder and not miss.Temp.childType then
		Hangup:SetAutoHangup(false);
	else
		Hangup:SetAutoHangup(true);
	end
	mMgr.CurExecuteType = miss.Temp.type
	mMgr.CurExecuteChildType = miss.childType
	if temp.type ~= MissionType.Feeder or miss.Status ~= MStatus.ALLOW_SUBMIT then
		  MissionMgr:UpdateCurMission(miss)
	end
	miss:AutoExecuteAction(MExecute.ClickItem, false) 
	if miss.Status == MStatus.ALLOW_SUBMIT then return end
	if self.Parent then self.Parent:Close() end
end

function M:CleanReward()
	local list = self.Cells
	if list then
		local l = #list
		while l > 0 do
			local cell = list[l]
			if cell then
				table.remove(list, l)
				cell:Destroy()
				ObjPool.Add(cell)
				cell = nil
			end
			l = #list
		end
		self.Cells = {}
	end
	if self.RGrid then
		local childs = self.RGrid:GetChildList()
		local count = childs.Count
		for i=0,count - 1 do
			local trans = childs[i]
			if not LuaTool.IsNull(trans) then
				trans.parent = nil
				Destroy(trans.gameObject)
			end
		end
		childs:Clear()
	end
end

function M:ShowCBtn(value)
	local btn = self.CBtn
	local lab = self.CurLab
	if btn then btn:SetActive(value) end
	if lab then lab.gameObject:SetActive(value) end
end

function M:SetActive(value)
	local root = self.Root
	if root then root:SetActive(value) end
	if value == false then self:CleanItems() end
end

function M:RestActiveNum()
	local listview = self.ListView
	if listview then
		listview:RestActiveNum()
	end
end

function M:CleanItems()
	local listview = self.ListView
	if listview then
		listview:CleanItems()
	end
end

function M:Dispose()
	if self.ListView then
		self.ListView:Dispose()
		ObjPool.Add(self.ListView)
	end
	self.Items = nil
	self.SV = nil
	self.Panel = nil
	self.Grid = nil
	self.Prefab = nil
	self.Succ = nil
	self.Ring = nil
	TableTool.ClearDic(self)
end

return M

--endregion
