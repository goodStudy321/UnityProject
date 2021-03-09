SBCell = Cell:New{Name = "SBCell"}

local base = Cell

local M = SBCell

function M:Ctor()
    base.Ctor(self)
    self.showTip = true
    self.showBtn = false
    self.compare = false 
end

function M:SetTip(showTip, showBtn, compare)
    self.showTip = showTip
    self.showBtn = showBtn
    self.compare = compare
end


function M:UpdateData(data)
    self.data = data
    self:UpData(data.typeId)
    self:UpStar()
    self:UpdateArrow()
end

function M:UpdateArrow()
    local state = self.data.up
    if state == 1 then  --上升
        self:IconUp(true)
    elseif state == 2 then  --下降
        self:IconDown(true)
    else  --不变
        self:IconUp(false)
        self:IconDown(false)
    end
end

function M:UpStar()
	local star = self.data.star or 0
	for i,v in ipairs(self.starList) do
		local state=true
		if i>star then state=false end
		v:SetActive(state)
	end
end

function M:OnClick(go)
    if self.showTip then
        if self.data.type == 4 then
            UISBEquipTip:Show(self.data, self.showBtn, self.compare)
        else
            UIMgr.Open(PropTip.Name,self.OpenCb,self)
        end
    end
    self.eClickCell(self.data)
end

function M:OpenCb(name)
    local ui = UIMgr.Get(name)
    if(ui)then 
		ui:UpData(self.data.typeId)
	end
end

function M:UpRank()
    local lv = self.data.level
    if lv > 0 then 
        self.rank.text = string.format("+%d", lv)
    else
        self.rank.text = ""
    end
    self.rank.gameObject:SetActive(lv>0)
end

function M:DisposeCus()
    self.data = nil
    self.showTip = true
    self.showBtn = false
    self.compare = false 
end

return M