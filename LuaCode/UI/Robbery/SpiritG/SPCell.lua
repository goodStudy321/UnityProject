SPCell = Cell:New{Name = "SPCell"}

local base = Cell

local My = SPCell

function My:Ctor()
    base.Ctor(self)
    self.showTip = true
    self.showBtn = false
    self.compare = false 
end

function My:SetTip(showTip, showBtn, compare)
    self.showTip = showTip
    self.showBtn = showBtn
    self.compare = compare
end

function My:BossSpData(prpId)
   local data = SpiritGMgr:CreateDate(prpId)
   self.data = data
   self:SetActive(true)
   self:UpData(data.typeId)
   self:UpStar()
end

function My:UpdateData(data,index)
    self.data = data
    self.index = index
    self:UpData(data.typeId)
    self:UpStar()
    self:UpdateArrow()
end

function My:UpdateArrow()
    local state = self.data.up
    local quality = self.data.quality
    local star = self.data.star
    local numSpId = SpiritGMgr:GetCurSPId()
    local spId = SpiritGMgr:GetCurSPId()
    spId = tostring(spId)
    local spCfg = SpiriteCfg[spId]
    local qLimit=quality
    local qStar = star
    local spInfo = RobberyMgr.SpiriteInfoTab.spiriteTab
    if spCfg~=nil then
        if spInfo ~= nil and spInfo[numSpId] ~= nil then
            local spLv = spInfo[numSpId].lv
            qLimit,qStar = SpiritGMgr:GetQuility(spLv,spCfg)
        end
    end
    local isShow = (quality <= qLimit) and (star <= qStar)
    if state == 1 and isShow == true then  --上升
        self:IconUp(true)
    elseif state == 2 and isShow == true then  --下降
        self:IconDown(true)
    elseif state == 0 or isShow == false then--不变
        self:IconUp(false)
        self:IconDown(false)
    end
end

function My:UpStar()
	local star = self.data.star or 0
	for i,v in ipairs(self.starList) do
		local state=true
		if i>star then state=false end
		v:SetActive(state)
	end
end

function My:OnClick(go)
    if self.showTip then
        if self.data.type == 5 then
            UISpiritEquipTip:Show(self.data, self.showBtn, self.compare)
        else
            UIMgr.Open(PropTip.Name,self.OpenCb,self)
        end
    end
    self.eClickCell(self.data)
end

function My:OpenCb(name)
    local ui = UIMgr.Get(name)
    if(ui)then 
		ui:UpData(self.data.typeId)
	end
end

function My:UpRank()
    local index = self.index
    local maxStep = self.data.maxStep
    local step = self.data.step
    if index then
        if index == 1 then
            step = self.data.step
        elseif index == 2 then
            step = self.data.step + 1
        end
    end
    self.rank.gameObject:SetActive(step>0)
    if step > 0 then 
        if step >= maxStep then
            step = "满"
        end
        self.rank.text = string.format("%s阶", step)
    else
        self.rank.text = ""
    end
end

function My:UpdateLab(state)
    local str = ""
    if state then
        str = "满"
    end
    self.Lab.text = str
end

function My:DisposeCus()
    self.index = nil
    self.data = nil
    self.showTip = true
    self.showBtn = false
    self.compare = false 
end

return My