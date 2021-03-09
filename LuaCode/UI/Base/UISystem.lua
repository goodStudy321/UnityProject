--region UISystem.lua
--Date
--此文件由[HS]创建生成


UISystem = UIBase:New{Name = "UISystem"}
local M = UISystem

M.anchors1 = {Vector3.New(-257.5,435.25,0),Vector3.New(296.21,-366.3,0)}

M.anchors2 = {Vector3.New(-421,314,0),Vector3.New(468.9,-173.5,0)}

M.targetPos = {Vector3.New(-433,211,0),Vector3.New(-449.7385,104.0144,0),Vector3.New(-468.4429,5.942193,0),Vector3.New(-448.5552,-95.05804,0),Vector3.New(-428.8814,-195.1262,0)
,Vector3.New(433,211,0),Vector3.New(454,105,0),Vector3.New(473,6,0),Vector3.New(453,-96,0),Vector3.New(433,-197,0)}
M.time = 0.3

--注册的事件回调函数

function M:InitCustom()
	local T = TransTool.FindChild
	self.CloseBtn = T(self.root, "Close")
	self.Items = {}
	for i=1,16 do
		local btnInfo = self:AddBtn(i)
		table.insert(self.Items, btnInfo)
	end
	self:AddEvent()
end

function M:AddBtn(index)
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	local name = "UI主界面系统按钮窗口"
	local info = {}
	local path = string.format( "Btn%s",index)
	info.Root = T(trans, path)
	if index <= 10 then
		local flyScale = ComTool.Add(info.Root, UIFlyScale)
		if flyScale then
			local i = math.ceil(index / 5)
			flyScale.anchors1 = self.anchors1[i]
			flyScale.anchors2 = self.anchors2[i]
			flyScale.targetPos = self.targetPos[index]
			flyScale.time = self.time
			flyScale.isDestroy = false
		end
	end
	info.Btn = C(UIButton, trans, path, name, false)
	info.Label = T(trans, string.format( "%s/%s", path, "Label"))
	info.Lock = T(trans, string.format( "%s/%s", path, "Lock"))
	info.Icon = C(UISprite, trans, string.format("%s/%s", path, "Icon"), name, false)
	info.Action = T(trans, string.format("%s/%s", path, "Action"))
	UITool.SetLsnrSelf(info.Root, self.OnClickBtn, self)
	return info
end

function M:UpdateLock()
	if self.Items then
		local oMgr = OpenMgr
		for i=1,#self.Items do
			local v = self.Items[i]
			local name = v.Root.name
			local str = string.gsub(name, "Btn", "")
			local index = tonumber(str)
			local isLock = true
			if index == 1 then
				isLock = false
			elseif index == 2 then
				isLock = oMgr:IsOpen(oMgr.ZBQH) == false
			elseif index == 3 then
				isLock = oMgr:IsOpen(oMgr.XM) == false
			elseif index == 4 then
				--isLock = not SoulBearstMgr:IsOpen()
				isLock = not PicCollectMgr:IsOpen()
			elseif index == 5 then
				isLock = false
			elseif index == 6 then
				for i=1,5 do
					local k = tostring(i)
					if oMgr:IsOpen(k) == true then
						isLock = false
						break
					end
				end
			elseif index == 7 then
				isLock = oMgr:IsOpen(oMgr.FWXB) == false
			elseif index == 8 then
				isLock = ImmortalSoulInfo:IsOpen() == false
			elseif index == 9 then
				isLock = MarryInfo:IsOpen() == false
			elseif index == 10 then
				isLock = false
			elseif index == 11 then
			elseif index == 12 then
			elseif index == 13 then
			elseif index == 14 then
			elseif index == 15 then
			elseif index == 16 then
			end
			if v.Lock then
				v.Lock:SetActive(isLock)
			end
			if v.Btn then
				v.Btn.Enabled = not isLock
			end
			if v.Icon then
				local c = Color.New(1,1,1,1)
				if isLock == true then c = Color:New(0,1,1,1) end 
				v.Icon.color = c
			end
			if v.Label then 
				v.Label.gameObject:SetActive(not isLock)
			end
		end
	end
end

function M:UpdateAction()
	if self.Items then
		for i=1,#self.Items do
			local v = self.Items[i]
			local name = v.Root.name
			local str = string.gsub(name, "Btn", "")
			local index = tonumber(str)
			if v.Action then
				local status = SystemMgr:GetSystem(index)
				v.Action:SetActive(status)
			end
		end
	end
end

function M:AddEvent()
	if self.CloseBtn then
		UITool.SetLsnrSelf(self.CloseBtn, self.OnClickClose, self)
	end
end

function M:RemoveEvent()
	-- body
end

function M:OnClickClose(go)
	self:Close()
end

function M:OnClickBtn(go)
	local len = string.len("Item")
	local key = tonumber(string.sub(go.name,len))
	local O = UIMgr.Open
	self:Close()
	if key == 1 then
		M.OpenRoleUI(1);
	elseif key == 2 then
		if User.instance.MapData.Level<20 then --装备强化所需等级
			UITip.Log("系统暂未开启")
		else
			EquipMgr.OpenEquip(1)--装备
		end
	elseif key == 3 then --道庭
		if FamilyMgr:JoinFamily() == true then
			O(UIFamilyMainWnd.Name);
		else
			O(UIFamilyListWnd.Name);
		end
	elseif key == 4 then
		--O(UISoulBearst.Name)
		O(UIPicCollect.Name)
	elseif key == 5 then
		M.OpenRoleUI(2);
	elseif key == 6 then
		local open = OpenMgr:IsOpen("3") or false
		if open == true then
			AdvMgr:OpenBySysID(3)
		else
			AdvMgr:OpenBySysID(1)  -- id:养成系统系统id: 1--->坐骑  2--->法宝  3--->宠物  4--->神兵  5--->翅膀
		end
	elseif key == 7 then
		O(UIRune.Name);--？？
	elseif key == 8 then
		O(UIImmortalSoul.Name)--仙魂
	elseif key == 9 then
		UIMarry:OpenTab(1)--仙侣
	elseif key == 10 then
		O("UISetting")--设置
	end
end

function M.OpenRoleUI(index)
	local O = UIMgr.Open;
	UIRole.OpenIndex = index;
	O(UIRole.Name);
end

--打开符文界面
function M:OpenRuneUI(go)
	local ui = UIMgr.Dic[UIRole.Name]
	if ui then
		ui.RuneBtnTog:Set(false,false);
		ui:SBActive(3);
	end
end



function M:OpenCustom()
	self:UpdateLock()
	self:UpdateAction()
	self.Timer = Time.realtimeSinceStartup
	self.Index = 5
	self.IsEffect = true

end

function M:CloseCustom()
	self.IsEffect = nil
	self.Index = nil
	self.Timer = nil
end

function M:Update()
	if not self.IsEffect then return end
	if not self.Timer then return end
	if Time.realtimeSinceStartup - self.Timer > 0.05 then
		local index = self.Index
		local index1 = 11 - index
		local v = self.Items[index]
		if v then
			v.Btn.gameObject:SetActive(true)
		end
		local v1 = self.Items[index1]
		if v1 then
			v1.Btn.gameObject:SetActive(true)
		end
		self.Index = index - 1
		if index <= 0 then
			self.IsEffect = false 
			return 
		end
		self.Timer = Time.realtimeSinceStartup
	end
	
end

return UISystem
	--endregion
