--[[
 	authors 	:Liu
 	date    	:2019-4-30 10:00:00
 	descrition 	:累充轮盘项
--]]

UIActComViewHYIt = Super:New{Name = "UIActComViewHYIt"}

local My = UIActComViewHYIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg
    self.go = root.gameObject
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.btn = FindC(root, "btn", des)
    self.yes = FindC(root, "yes", des)
    self.no = FindC(root, "no", des)
    self.spr = FindC(root, "goldSpr", des)
    self.spr:SetActive(false)

    SetB(root, "btn", des, self.OnGet, self)

    self:InitLab()
    self:ChangeName()
end

--初始化数据
function My:InitLab()
    local list = StrTool.Split(self.cfg.des, ",")
    self.lab1.text = list[1] or ""
    self.lab2.text = "[EE9A9EFF]"..list[2] or ""
end

--点击领取
function My:OnGet()
    local mgr = FestivalActMgr
    mgr:ReqBgActReward(self.cfg.type, self.cfg.id)
end

--更新按钮状态
function My:UpBtnState(state)
    if state == 2 then
        self:UpShowBtn(true, false, false)
    elseif state == 3 then
        self:UpShowBtn(false, true, false)
    else
        self:UpShowBtn(false, false, true)
    end
    self:ChangeName()
end

--更新显示按钮
function My:UpShowBtn(state1, state2, state3)
    self.btn:SetActive(state1)
    self.yes:SetActive(state2)
    self.no:SetActive(state3)
end

--改变名字
function My:ChangeName()
    local num = 0
    local cfg = self.cfg
    if cfg.state == 2 then
        num = cfg.id + 1000
    elseif cfg.state == 3 then
        num = cfg.id + 8000
    else
        num = cfg.id + 5000
    end
    self.go.name = num
end

--清理缓存
function My:Clear()

end

-- 释放资源
function My:Dispose()
    self:Clear()
end

return My