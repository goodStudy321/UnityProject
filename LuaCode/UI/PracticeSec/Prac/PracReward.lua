require("UI/PracticeSec/Prac/PracRewIt")
require("UI/PracticeSec/Prac/PracRewShow")
PracReward = Super:New{Name = "PracReward"}
local My = PracReward

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local TF = TransTool.Find
	local US = UITool.SetLsnrSelf
	local TFC = TransTool.FindChild

	self.go = root.gameObject
	self.comTex = CG(UITexture,root,"sp/bg1/tex",des)
    self.spcTex = CG(UITexture,root,"sp/bg2/tex",des)
	self.btn = TFC(root,"btn",des)
	self.flag = TFC(root,"flag",des)
	self.panel = CG(UIPanel,root,"ScrollView",des)
	self.grid = CG(UIGrid,root,"ScrollView/Grid",des)
	self.prefab = TFC(root,"ScrollView/Grid/rewItem",des)
	self.prefab:SetActive(false)
	self.itemTab = {}

	local isCharge = PracSecMgr:IsRecharge()
	if isCharge == false then
		self.rewardP = ObjPool.Get(PracRewShow)
		self.rewardP:Init(TF(root,"rewardP",des))
	end

	self:SetLnsr("Add")
	US(self.btn,self.OpenRewP,self,des,false)
	self:LoadComTex()
    self:LoadSpcTex()
	self:RefreshData()
	self:RefresDifShow()
end

function My:SetLnsr(func)
    PracSecMgr.ePracCharge[func](PracSecMgr.ePracCharge, self.RefresDifShow, self)
    PracSecMgr.ePracCharge[func](PracSecMgr.ePracCharge, self.RefreshData, self)
    PracSecMgr.ePracInfoGotRew[func](PracSecMgr.ePracInfoGotRew, self.RefreshData, self)
    PracSecMgr.ePracInfo[func](PracSecMgr.ePracInfo, self.RefreshData, self)
    PracSecMgr.ePracMisGotRew[func](PracSecMgr.ePracMisGotRew, self.RefreshData, self)
    PracSecMgr.ePracBackExp[func](PracSecMgr.ePracBackExp, self.RefreshData, self)
end

function My:LoadComTex()
	local path = "icon_fanpin.png"
	AssetMgr:Load(path, ObjHandler(self.SetComIcon, self))
end

function My:LoadSpcTex()
	local path = "icon_xianpin.png"
	AssetMgr:Load(path, ObjHandler(self.SetSpcIcon, self))
end

--设置图标
function My:SetComIcon(tex)
	if self.texComName == nil then
		self.comTex.mainTexture = tex
		self.texComName = tex.name
	end
end

--设置图标
function My:SetSpcIcon(tex)
	if self.texSpcName == nil then
		self.spcTex.mainTexture = tex
		self.texSpcName = tex.name
	end
end

--清理texture
function My:ClearComIcon()
	if self.texComName then
	  AssetMgr:Unload(self.texComName,".png",false)
	  self.texComName = nil
	end
end

--清理texture
function My:ClearSpcIcon()
	if self.texSpcName then
	  AssetMgr:Unload(self.texSpcName,".png",false)
	  self.texSpcName = nil
	end
end

--打开奖励预览面板
function My:OpenRewP()
	self.rewardP:SetActive(true)
end

--是否已充值
function My:RefresDifShow()
	local info = PracSecMgr.pracInfoTab
	local isCharge = PracSecMgr:IsRecharge()
	self.btn:SetActive(not isCharge)
	self.flag:SetActive(isCharge)
end

--更新显示
function My:UpShow(state)
	if state == true then
		self:SetCurCenter()
	end
	self.go:SetActive(state)
 end

 function My:RefreshData()
	local data = PracSecMgr:GetRew()
	local redIndex = 0
    local len = #data
    local itemTab = self.itemTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpdateData(data[i])
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(PracRewIt)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(self.itemTab,item)
		end
		if redIndex == 0 and data[i] then
			local lv = data[i].lv
			local index1 = PracSecMgr:IsCanRew(1,lv) --index == 1
			local index2 = PracSecMgr:IsCanRew(2,lv) --index == 3
			if index1 == 1 or index2 == 3 then
				redIndex = i
			end
		end
	end
	self.redIndex = redIndex
    self.grid:Reposition()
end

function My:SetCurCenter()
    local index = self.redIndex
    local rewTab = PracSecMgr:GetRew()
	local len = #rewTab
	local finIndex = len - 4
    if index <= 4 then
		return
	elseif index >= (len-4) then
		local tPos = len * 162
		local nPos = 4 * 162
		local pos = tPos - nPos - 50
		self.panel.clipOffset = Vector2.New(pos,0)
		self.panel.transform.localPosition = Vector3.New(-pos,0,0)
		return
	end
    local item = self.itemTab[index]
    if item == nil then
        return
    end
    local pos = item.Gbj.transform.localPosition
    local x = pos.x
	local centerX = x - 200
    self.panel.clipOffset = Vector2.New(centerX,0)
    -- centerX = math.abs(centerX)
    self.panel.transform.localPosition = Vector3.New(-centerX,0,0)
end

function My:Dispose()
	self:SetLnsr("Remove")
	if self.rewardP then
		ObjPool.Add(self.rewardP)
		self.rewardP = nil
	end
	 --清理texture
	 self:ClearComIcon()
	 self:ClearSpcIcon()
	TableTool.ClearListToPool(self.itemTab)
end

return My
