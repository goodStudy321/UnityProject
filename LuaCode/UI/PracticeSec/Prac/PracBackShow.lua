PracBackShow = Super:New{Name = "PracBackShow"}
local My = PracBackShow

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local TF = TransTool.Find
	local US = UITool.SetLsnrSelf
	local TFC = TransTool.FindChild

	self.go = root.gameObject
	self.closeBtn = TFC(root,"CloseBtn",des)
	self.buyBtn = TFC(root,"yesBtn",des)

	self.backLab = CG(UILabel,root,"num1",des)
	self.expLab = CG(UILabel,root,"num2",des)
	self.goldLab = CG(UILabel,root,"num3",des)
	self.expTex = CG(UITexture,root,"tex1",des)
	self.goldTex = CG(UITexture,root,"tex2",des)
	self.addBtn = TFC(root,"btnAdd",des)
	self.reduceBtn = TFC(root,"btnReduce",des)
	self.countLab = CG(UILabel,root,"Count",des)
	self.countBtn = TFC(root,"Count",des)
	self.mNunStr = "0"
	self:SetLnsr("Add")
	US(self.buyBtn,self.ClickBuy,self,des,false)
	US(self.closeBtn,self.ClickClose,self,des,false)
	US(self.addBtn,self.OnAdd,self,des,false)
	US(self.reduceBtn,self.OnReduce,self,des,false)
	US(self.countBtn,self.OnInput,self,des,false)
	self:LoadExpTex()
	self:LoadGoldTex()
end

function My:SetLnsr(func)
	PricePanel.eConfirm[func](PricePanel.eConfirm, self.OnConfirm, self)
	PricePanel.eNum[func](PricePanel.eNum, self.OnNum, self)
    PricePanel.eClear[func](PricePanel.eClear, self.OnClear, self)
	PracSecMgr.ePracBackExp[func](PracSecMgr.ePracBackExp, self.UpData, self)
end

function My:LoadExpTex()
	local cfg = ItemData["27"]
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetExpIcon, self))
end

function My:LoadGoldTex()
	local id = GlobalTemp["195"].Value2[1]
	id = tostring(id)
	local cfg = ItemData[id]
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetGoldIcon, self))
end

--设置图标
function My:SetExpIcon(tex)
	if self.texExpName == nil then
		self.expTex.mainTexture = tex
		self.texExpName = tex.name
	end
end

--设置图标
function My:SetGoldIcon(tex)
	if self.texGoldName == nil then
		self.goldTex.mainTexture = tex
		self.texGoldName = tex.name
	end
end

--清理texture
function My:ClearExpIcon()
	if self.texExpName then
	  AssetMgr:Unload(self.texExpName,".png",false)
	  self.texExpName = nil
	end
end

--清理texture
function My:ClearGoldIcon()
	if self.texGoldName then
	  AssetMgr:Unload(self.texGoldName,".png",false)
	  self.texGoldName = nil
	end
end

function My:OnNum(num)
	local max = PracSecMgr.pracInfoTab.praceBackExp
	-- local max = 100
	self.mNunStr = self.mNunStr .. num
    local num = tonumber(self.mNunStr)
    if num > max then
        self.curCount = max
    elseif num > 0 then
        self.curCount = num
    else
        self.curCount = 0
    end
    self:UpdatePrice(self.curCount)
end

function My:OnClear()
	self.curCount = 0
	self.mNunStr = "0"
    self:UpdatePrice(self.curCount)
end

function My:OnConfirm(num)
	local max = PracSecMgr.pracInfoTab.praceBackExp
	-- local max = 100
    num = num > 0 and num or 0
    self.curCount = num > max and max or num
    self:UpdatePrice(self.curCount)
end

function My:OnInput()
	self.mNunStr = "0"
    UIMgr.Open(PricePanel.Name,self.OpenCb,self)
end

function My:OpenCb(name)
	local ui = UIMgr.Dic[name]
	if ui then
		ui:SetPos(Vector3.New(64.6,-197.7,0))
	end
end

function My:OnAdd()
	local max = PracSecMgr.pracInfoTab.praceBackExp
	-- local max = 100
    self.curCount = self.curCount + 1
    if self.curCount > max then
        self.curCount = max
    end
    self:UpdatePrice(self.curCount)
end

function My:OnReduce()
    self.curCount = self.curCount - 1
    if self.curCount < 0 then
        self.curCount = 0
    end
    self:UpdatePrice(self.curCount)
end

function My:UpdatePrice(num)
	local sinPirce = GlobalTemp["195"].Value2[2]
    self.expLab.text = num
    self.goldLab.text = num * sinPirce
    self.countLab.text = num
end

function My:UpData()
    local num = PracSecMgr.pracInfoTab.praceBackExp
    -- local num = 100
    self.curCount = num
	self:UpdatePrice(num)
    self.backLab.text = num
end

function My:ClickClose()
	self:SetActive(false)
end

--点击追回
function My:ClickBuy()
	local str = "是否确认追回未完成的修炼任务奖励？"
	MsgBox.ShowYesNo(str,self.YesCb, self)
end

function My:YesCb()
	local num = self.curCount
	if num == 0 then
		UITip.Error("不可找回")
		return
	end
	PracSecMgr:ReqPracExpBack(num)
end

function My:SetActive(ac)
	if ac == true then
		self:UpData()
	end
	self.go:SetActive(ac)
end

function My:Dispose()
	self.mNunStr = "0"
	self.curCount = 0
	self:SetLnsr("Remove")
	self:ClearExpIcon()
	self:ClearGoldIcon()
	TableTool.ClearUserData(self)
end

return My
