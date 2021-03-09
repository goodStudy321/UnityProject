UIElvesBtn = Super:New{Name = "UIElvesBtn"}

local My = UIElvesBtn

function My:Init(root)
    local transRoot = root.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
    local S = UITool.SetLsnrSelf
	self.elvesTimeLab = C(UILabel, root, "Root/ActTimerLab")
    self.elvesTimeLab.gameObject:SetActive(true)

    self:SetLnsr("Add")
    -- self:UpElvesNewState()
end

--设置监听
function My:SetLnsr(func)
    --绝版守护按钮状态显示
	-- ElvesNewMgr.eUpState[func](ElvesNewMgr.eUpState,self.UpElvesNewState,self)
    ElvesNewMgr.eUpTimer[func](ElvesNewMgr.eUpTimer, self.RespUpTimer, self)
	ElvesNewMgr.eEndTimer[func](ElvesNewMgr.eEndTimer, self.RespEndTimer, self)
end

function My:OpenElvesUI()
    -- local payState = ElvesNewMgr.PayState
    -- if payState == 1 then
    --     self:ElvesAction(true)
    -- else
    --     self:ElvesAction(false)
    -- end
    -- UIMgr.Open(UIElvesNew.Name)
end

--更新永久绝版守护
function My:UpElvesNewState()
    local state = ElvesNewMgr.State
	self.elvesGbj:SetActive(state)
	if state == false then
		return
	end
    self:SetElvesInfo()
end

--设置绝版守护显示信息
function My:SetElvesInfo()
    local name = "永久绝版守护"
    local iconPath = "icon_fl"
	self.elvesNameLab.text = name
	self.elvesIcon.spriteName = iconPath
end

function My:RespUpTimer(time)
    local payS = ElvesNewMgr.PayState
    if payS == 1 then
        self:ElvesAction(true)
    end
    local time = tonumber(time)
    self.elvesTimeLab.text = DateTool.FmtSec(time, 3, 2,true)
end

function My:RespEndTimer()
    -- self.elvesGbj:SetActive(false)
    local mgr = ActivityMgr
	local k,v = mgr:Find(mgr.YJJBSH)
	mgr:Remove(v)
    self:SetLnsr("Remove")
end

function My:ElvesAction(ac)
    local actId = ActivityMgr.YJJBSH
    if ac == true then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
    -- self.elvesAction:SetActive(ac)
end

function My:Dispose()
    if not LuaTool.IsNull(self.elvesTimeLab) then
        self.elvesTimeLab.gameObject:SetActive(false)
        self.elvesTimeLab = nil
    end
    self:SetLnsr("Remove")
end

return My
