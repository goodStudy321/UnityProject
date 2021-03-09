PracLv = Super:New{Name = "PracLv"}
require("UI/PracticeSec/Prac/PracExpIt")
require("UI/PracticeSec/Prac/PracBackShow")
local My = PracLv

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local TF = TransTool.Find
	local US = UITool.SetLsnrSelf
	local TFC = TransTool.FindChild

	self.go = root.gameObject
	self.go:SetActive(true)
	self.iconTex = CG(UITexture,root,"tex",des)
	self.tipBtn = TFC(root,"tipBtn",des)
	self.backBtn = TFC(root,"backBtn",des)
	self.timerLab = CG(UILabel, root, "timeLab", des)
	self.lvLab = CG(UILabel, root, "lv", des)
	self.grid = CG(UIGrid,root,"Grid2",des)
	self.prefab = TFC(root,"Grid2/line2",des)
	self.prefab:SetActive(false)

	self.backShowP = ObjPool.Get(PracBackShow)
	self.backShowP:Init(TF(root,"backP",des))

	self:SetLnsr("Add")
	US(self.tipBtn,self.ClickTipBtn,self,des,false)
	US(self.backBtn,self.OpenBackShow,self,des,false)
	self.expItTab = {}
	self:InitProp()
	self:Countdown()
end

function My:SetLnsr(func)
    PracSecMgr.ePracInfo[func](PracSecMgr.ePracInfo, self.RefreshExp, self)
    PracSecMgr.ePracMisGotRew[func](PracSecMgr.ePracMisGotRew, self.RefreshExp, self)
    PracSecMgr.ePracBackExp[func](PracSecMgr.ePracBackExp, self.RefreshExp, self)
end

function My:OpenBackShow()
	self.backShowP:SetActive(true)
end

function My:ClickTipBtn()
	local desInfo = InvestDesCfg["2021"]
    local str = desInfo.des
	UIComTips:Show(str, Vector3(-223,208,0),nil,nil,nil,700,UIWidget.Pivot.TopLeft)
end

function My:InitProp()
	self:LoadTex()
	self:InitExp()
	self:RefreshExp()
end

function My:LoadTex()
	local cfg = ItemData["27"]
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
end

--设置图标
function My:SetIcon(tex)
	self.iconTex.mainTexture = tex
	self.texName = tex.name
end

--清理texture
function My:ClearIcon()
	if self.texName then
	  AssetMgr:Unload(self.texName,".png",false)
	  self.texName = nil
	end
end

function My:InitExp()
	for i = 1,10 do
		local go = Instantiate(self.prefab)
		go:SetActive(true)
		TransTool.AddChild(self.grid.transform,go.transform)
		local item = ObjPool.Get(PracExpIt)
		item:Init(go)
		table.insert(self.expItTab,item)
	end
	self.grid:Reposition()
end

function My:RefreshExp()
	local data = PracSecMgr.pracInfoTab
	local curLv = data.pracLv
	local curExp = data.pracExp
	local len = curExp
	local itTab = self.expItTab
	local count = #itTab
	for i = 1,count do
		local it = itTab[i]
		if i <= len then
			it:SetActive(true)
		elseif i > len then
			it:SetActive(false)
		end
	end
	self.lvLab.text = curLv
end

function My:Countdown()
    local info = NewActivMgr:GetActivInfo(2010)
    if not info then return end
    local startTime = 0
    local endTime = 0
    local severTime = 0
    local seconds = 0
    startTime = info.startTime
    endTime = info.endTime
    severTime = TimeTool.GetServerTimeNow()*0.001
    seconds = info.endTime - severTime
    local isOpen = PracSecMgr:IsOpen()
    if isOpen and seconds > 0 then
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.fmtOp = 0
            self.timer.apdOp = 0
            self.timer.invlCb:Add(self.InvCountDown, self)
            self.timer.complete:Add(self.EndCountDown, self)
        end
        self.timer.seconds = seconds
        self.timer:Stop()
        self.timer:Start()
        self:InvCountDown()
    end
end

function My:InvCountDown()
	local time = self.timer:GetRestTime()
	time = DateTool.FmtSec(time,0,4,false)
    self.timerLab.text = time
end

function My:EndCountDown()
    self.timerLab.text = ""
    if self.timer then
        self.timer:Stop()
	end
	local active = UIMgr.GetActive(UIPracticeSec.Name)
	local ui = UIMgr.Get(UIPracticeSec.Name)
	if ui and active ~= -1 then ui:Close() end
end

function My:ClearTab()
	for k,v in pairs(self.expItTab) do
		v:Dispose()
		self.expItTab[k] = nil
	end
end

function My:Dispose()
	self:SetLnsr("Remove")
	if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
	end
	if self.backShowP then
		ObjPool.Add(self.backShowP)
		self.backShowP = nil
	end
	self:ClearIcon()
	self:ClearTab()
end

return My
