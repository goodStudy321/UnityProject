--[[
 	authors 	:Liu
 	date    	:2018-12-20 14:35:00
 	descrition 	:结婚副本祝福日志项
--]]

UIMarryWishLogIt = Super:New{Name = "UIMarryWishLogIt"}

local My = UIMarryWishLogIt

function My:Init(root, cfg, index)
	local des = self.Name
	local CGS = ComTool.GetSelf

	self.lab = CGS(UILabel, root, des)
	self.go = root.gameObject
	self.index = index
	self.cfg = cfg
end

--初始化文本
function My:UpLab(cfg)
	local info = MarryInfo
	local hour = info:GetDate(cfg.time, "HH")
	local minute = info:GetDate(cfg.time, "mm")
	local itName = self:GetItemName(cfg.index)
	local str = string.format("[FFE9BDFF]%s:%s[88F8FFFF]%s[-]对[88F8FFFF]%s[-]送上真诚的祝福，献上[FF66FCFF]%s", hour, minute, cfg.name, cfg.toName, itName)
	self.lab.text = str
end

--获取道具名字
function My:GetItemName(index)
	local str = "???"
	local cfg = MarryWishCfg[index]
	if cfg then
		if cfg.type == 1 then
			str = cfg.val.."元宝"
		else
			local key = tostring(cfg.val)
			local itemCfg = ItemData[key]
			if itemCfg then
				str = itemCfg.name
			end
		end
	end
	return str
end

--更新显示
function My:UpShow(state)
	self.go:SetActive(state)
end

--清理缓存
function My:Clear()

end
	
--释放资源
function My:Dispose()
    self:Clear()
end
	
return My