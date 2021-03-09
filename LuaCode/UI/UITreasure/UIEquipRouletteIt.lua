--[[
 	authors 	:Liu
 	date    	:2018-6-27 14:00:00
 	descrition 	:装备寻宝轮盘奖励项
--]]

UIEquipRouletteIt = Super:New{Name="UIEquipRouletteIt"}

local My = UIEquipRouletteIt

function My:Init(root, cfg)
    self.cfg = cfg
    self.root = root
    self.go = root.gameObject
    UITool.SetLsnrSelf(root, self.OnBoxClick, self)
end

--点击碰撞盒
function My:OnBoxClick()
	local key = tostring(self.cfg.iconId)
	local cfg = ItemData[key]
	if cfg == nil then return end
	if cfg.uFx == 1 then
		UIMgr.Open(EquipTip.Name,self.OpenCb,self)
	elseif cfg.uFx == 89 then
		UIMgr.Open(UIElixirTip.Name,self.OpenCb,self)
	else
		UIMgr.Open(PropTip.Name,self.OpenCb,self)
	end
end

--装备tip界面回调
function My:OpenCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
		local id = tostring(self.cfg.iconId);
		if ItemData[id].uFx == 89 then
			ui:UpData(id);
		else
			ui:UpData(self.cfg.iconId)
		end
	end
end

--清理缓存
function My:Clear()

end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My