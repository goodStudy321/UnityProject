--[[
 	authors 	:Liu
 	date    	:2018-12-15 14:05:00
 	descrition 	:宾客项
--]]

UIInviteIt = Super:New{Name = "UIInviteIt"}

local My = UIInviteIt

function My:Init(root, cfg, index)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick

    local lab = CG(UILabel, root, "lab")
    self.cfg = cfg
    self.index = index
    self.go = root.gameObject
    if index ~= 3 then
        SetB(root, "btn", des, self.OnClick, self)
    end
    self:InitLab(lab)
end

--初始化文本
function My:InitLab(lab)
    local str = ""
    local cfg = self.cfg
    local index = self.index
    if index == 1 then
        local color = (cfg.Online) and "[FFE9BDFF]" or "[B2B2B2FF]"
        str = string.format("%s%s", color, cfg.Name)
    elseif index == 2 then
        local color = (cfg.isOnline) and "[FFE9BDFF]" or "[B2B2B2FF]"
        str = string.format("%s%s", color, cfg.roleName)
    elseif index == 3 then
        str = self.cfg.name
    end
    lab.text = str
end

--点击邀请
function My:OnClick()
    local index = self.index
    local mgr = MarryMgr
    if index == 1 then
        mgr:ReqInviteGuest(self.cfg.ID)
    else
        mgr:ReqInviteGuest(self.cfg.roleId)
    end
    UITip.Log("邀请成功")
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
end
    
return My