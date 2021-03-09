--region UISkyBookItem.lua
--排行榜基类
--此文件由[HS]创建生成
UISkyBookItem = Super:New{Name = "UISkyBookItem"}
local M = UISkyBookItem
local sbMgr = SkyBookMgr

function M:Init(go)
	self.GO = go
	local name = go.name
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Btn = C(UIButton, trans, "Button", name, false)
	self.BtnBG = C(UISprite, trans, "Button/Background", name, false)
	self.Menu = self.Btn.gameObject:GetComponent("UIMenuTip")
	self.BtnEffect = T(trans, "Button/Background/FX_UI_Button ")
	self.Label = C(UILabel, trans, "Button/Label", name, false)
	self.Des = C(UILabel, trans, "Target", name, false)
	self.Get = C(UILabel, trans, "Get", name, false)
	self.Icon = C(UITexture, trans, "Icon", name, false)
	self.Rate = C(UILabel, trans, "Rate", name, false)
	self.Grid = C(UIGrid, trans, "Grid", name, false)
	self.Prefab = T(trans, "Grid/ItemCell", name, false)
	self.BPrefab = T(trans, "Grid/BossCell", name, false)
	self.Action = T(trans, "Action")
	self.Tip = T(trans, "Tip")
	self.Items = {}
	self.BItems = {}
	self.Cur = 0
	self.Max = 1
	self.Status = false
	local SLS = UITool.SetLsnrSelf
	SLS(go, self.OnGetReward, self, nil, false)
	SLS(self.Btn, self.OnGetReward, self)
	SLS(self.Action, self.OnAction, self, nil, false)
end

function M:OnGetReward(go)
	local temp = self.Temp
	local t = temp.type
	local status = sbMgr:IsGetReward(temp.id)
	if status == false and self.Cur < self.Max then
		if t == 1 or t == 2 then
			return
		elseif t == 5 or t == 3 then
			sbMgr:GuideUI(temp.condition)
			return
		end
	end
	if not temp then
		iTrace.eLog("hs","没有数据，不能领取")
		return 
	end
	if status == true then
		iTrace.eLog("hs","已经领取")
		return
	end
	if self.Cur < self.Max then
		iTrace.eLog("hs","未满足领取条件")
		return
	end
	sbMgr:ReqGetReward(temp.id)
end

function M:OnAction(go)
	UIMgr.Close(UISkyBook.Name)
	UIMgr.Open(UIBoss.Name)
end

function M:UpdateData(data)
	local temp = data.Temp
	self.Temp = temp
	self:UpdateDes(temp.des)
	self:UpdateGet(temp.reward.v)
	self:UpdateIcon(temp.reward.k)
	self:UpdateTarget(temp.id, temp.condition, temp.param, temp.show, data.List)
end

function M:UpdateDes(value)
	if self.Des then
		self.Des.text = value
	end
end

function M:UpdateGet(value)
	if self.Get then
		self.Get.text = math.NumToStr(value)
	end
end

function M:UpdateIcon(value)
	local temp = ItemData[tostring(value)]
	if not temp then return end
	local path = temp.icon
	if self.Icon then
		local idx = path:match(".+()%.%w+$") --获取文件后缀
		local s = nil
		if idx then s = path:sub(1, idx - 1) end
		if StrTool.IsNullOrEmpty(s) == false then
			if self.Icon.mainTexture and self.Icon.mainTexture.name == s then return end
		end
		if StrTool.IsNullOrEmpty(path) then	
			self.Icon.mainTexture = nil
			self.Icon.gameObject:SetActive(false)
			self.Icon.gameObject:SetActive(true)
			return
		end
		self:UnloadIcon()
		self.IconName = path
		AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
	end
end

function M:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
	end
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

function M:UpdateStatus(cur, max, id)
	self.Cur = cur
	self.Max = max
	local t = self.Temp.type
	self.Status = sbMgr:IsGetReward(id)
	local sName = "领取"
	if self.Status == true then
		sName = "已领取"
		color = Color.green
	elseif cur < max then
		if self:GoPlayActive(t) then
			sName = "去完成"
		else
			sName = "未完成"
		end
	end
	if self.Menu then self.Menu.IsActive = cur < max and (t==1 or t==2) end
	if self.Label then
		self.Label.text = sName
	end
	local active = self:GetActive(t, cur, max)
	if self.BtnEffect then
		self.BtnEffect:SetActive(self.Status == false and cur >= max)
	end
	if self.Btn then
		if active == true then			
			self.BtnBG.spriteName = "btn_figure_non_avtivity" 
		else
			self.BtnBG.spriteName = "btn_figure_down_avtivity"
		end
		self.Btn.isEnabled = active
	end
end

function M:GetActive(t, cur, max)
	if self:GoPlayActive(t) then
		return self.Status == false
	else
		return self.Status == false and cur >= max
	end
	return false
end

function M:UpdateRate(v1, v2)
	v1 = math.NumToStr(v1)
	v2 = math.NumToStr(v2)
	if self.Rate then
		if not v1 and not v2 then self.Rate.text = "" end
		if not self.Status then
			self.Rate.text = string.format( "(%s/%s)",v1,v2)
		else
			self.Rate.text = string.format( "(%s/%s)",v2,v2)
		end
	end
end

function M:UpdateTarget(id, t, params, icons, list)
	if list then len = #list end
	local cur,max,ti,satisfy = sbMgr:IsStatus(t, params, list)
	self:UpdateStatus(cur, max, id)
	self:UpdateRate(cur, max)
	self:UpdateCells(ti, icons, satisfy)
	self:UpdateAction(t, ti, icons)
end

function M:UpdateAction(t, ti, list)
	local pos = self.Grid.transform.localPosition
	pos.x = pos.x + (#list) * self.Grid.cellWidth *  0.8
	if self.Action then
		self.Action.transform.localPosition = pos
		self.Action:SetActive(ti == 2)
	end
	if self.Tip then
		self.Tip.transform.localPosition = pos
		self.Tip:SetActive( ti == 1 )
	end
end

function M:UpdateCells(t, list, satisfy)
	self:CleanItems()
	if not list then return end
	local len = #list
	for i=1,len do
		self:AddItem(t, i)
		self:UpdateItemData(t, i, list[i], satisfy)
	end
	self.Grid:Reposition()
end

function M:UpdateItemData(t, index, id, UpdateItemData)
	if not id then return end
	if self:IsItemCell(t) == true  then
		local cell = self.Items[index]
		if cell then 
			local create = ItemCreate[tostring(id)]
			local key = nil
			if create then
				local cate = User.MapData.Category
				if cate == 1 then
					key = create.w1
				else
					key = create.w2
				end
			end
			if not create then key = tostring(id) end
			if StrTool.IsNullOrEmpty(key) then return end
			local item = ItemData[key]
			if item then
				 if self.Temp.type ~= 4 then
					cell:UpData(item)
				else
					cell:TipSuit(id, 1)
				end
			end
		end
	else
		local cell = self.BItems[index]
 		if cell then
			local most =  MonsterTemp[tostring(id)]
			if most then
				cell:UpdateData(most, UpdateItemData)
			end
		end
	end
end

function M:AddItem(t, index)
	local go = nil
	if self:IsItemCell(t) == true then
		go = GameObject.Instantiate(self.Prefab)
	else
		go = GameObject.Instantiate(self.BPrefab)
	end
	if not go then return end
	go:SetActive(true)
	local trans = go.transform
	trans.parent = self.Grid.transform
	trans.localScale = Vector3.one
	trans.localPosition = Vector3.zero
	local cell = nil
	if self:IsItemCell(t) == true then
		cell = ObjPool.Get(UIItemCell)
		table.insert(self.Items, cell)
	else
		cell = ObjPool.Get(UISkyBookBossCell)
		table.insert(self.BItems, cell)
	end
	if cell then
		cell:Init(go)
	end
end


function M:GetPosX(w, ui, reset, offset)
	offset = offset or 1
	local trans = ui.transform
	if reset == true then
		local pos = trans.localPosition
		pos.x = w
		trans.localPosition = pos
	else
		local pos = trans.localPosition
		w = pos.x
	end
	w = w + ui.width * offset + 5
	return w
end

function M:IsReach()
	return self.Cur >= self.Max and self.Status == true
end

function M:State()
	if self.Status == true then 
		return 0
	elseif self.Cur >= self.Max then
		return 2
	end 
	return 1
end

function M:GoPlayActive(t)
	if t == 1 or t == 2 or t == 5 or t == 3 then
		return true
	end
	return false
end

function M:IsItemCell(t)
	if t == 1 or t == 3 or t == 4  then
		return true
	end
	return false
end

function M:SetActive(value)
	if not value then self:Clear() end
	if self.GO then
		self.GO:SetActive(value)
	end
end

function M:CleanItems()
	if self.Items then
		while #self.Items>0 do
			local item = self.Items[#self.Items]
			item.trans.parent = nil
			GameObject.Destroy(item.trans.gameObject)
			--item:DestroyGo()
			ObjPool.Add(item)
			self.Items[#self.Items] = nil
		end
	end
	if self.BItems then
		while #self.BItems>0 do
			local item = self.BItems[#self.BItems]
			item:Dispose()
			self.BItems[#self.BItems] = nil
		end
	end
end

function M:Clear()
	self:UnloadIcon()
	self.Cur = 0
	self.Max = 1
	self.Status = false
	self:UpdateDes("")
	self:UpdateGet(0)
	self:SetIcon(nil)
end

--销毁释放
function M:Dispose()
	self:CleanItems()
	self.Temp = nil
	self.Des = nil
	self.Get = nil
	self.Icon = nil
	self.Rate = nil
	if self.GO then
		self.GO.transform.parent = nil
	end
	GameObject.Destroy(self.GO)
	self.GO = nil
end
--endregion
