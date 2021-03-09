--[[
 	authors 	:Liu
 	date    	:2018-12-18 11:50:00
 	descrition 	:宾客邀请项
--]]

UIInviteGuestIt = Super:New{Name = "UIInviteGuestIt"}

local My = UIInviteGuestIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick

    local nameLab = CG(UILabel, root, "lab")
    self.cfg = cfg
    self.go = root.gameObject
    SetB(root, "yes", des, self.OnYes, self)
    SetB(root, "no", des, self.OnNo, self)
    self:InitLab(cfg, nameLab)
end

--初始化文本
function My:InitLab(cfg, nameLab)
    nameLab.text = cfg.name
end

--点击同意
function My:OnYes()
    UIProposePop.modList[5]:IsMax()
    self:ReplyGuest(1)
end

--点击拒绝
function My:OnNo()
    UIProposePop.modList[5]:IsMax()
    self:ReplyGuest(0)
end

--回复宾客请求
function My:ReplyGuest(type)
    local list = {}
    table.insert(list, self.cfg.id)
    MarryMgr:ReqReplyGuest(type, list)
end

--清理缓存
function My:Clear()

end
	
--释放资源
function My:Dispose()
	self:Clear()
end
	
return My