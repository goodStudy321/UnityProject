--[[
 	authors 	:Liu
 	date    	:2018-12-20 09:35:00
 	descrition 	:结婚副本祝福购买项
--]]

UIMarryWishBuyIt = Super:New{Name = "UIMarryWishBuyIt"}

local My = UIMarryWishBuyIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf

    self.lab = CG(UILabel, root, "lab")
    self.tog = CGS(UIToggle, root, des)
    self.cfg = cfg

    self:InitLab()
end

--初始化文本
function My:InitLab()
    local cfg = self.cfg
    if cfg.type == 1 then
        self.lab.text = cfg.val.."元宝"
    else
        local key = tostring(cfg.val)
        local itemCfg = ItemData[key]
        if itemCfg then
            self.lab.text = itemCfg.name
        end
    end
end

--清理缓存
function My:Clear()
    self.cfg = nil
end
	
--释放资源
function My:Dispose()
	self:Clear()
end
	
return My