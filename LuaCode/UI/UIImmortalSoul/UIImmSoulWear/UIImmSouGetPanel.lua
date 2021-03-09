--[[
 	authors 	:Liu
 	date    	:2018-11-1 16:10:00
 	descrition 	:仙魂获取途径界面
--]]

UIImmSouGetPanel = Super:New{Name = "UIImmSouGetPanel"}

local My = UIImmSouGetPanel

function My:Init(root)
	local des = self.Name
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	local SetS = UITool.SetLsnrSelf
	local routeTran = Find(root, "route1", des)

    self.go = root.gameObject

	SetB(root, "bg/box", des, self.OnBoxClick, self)
	SetS(routeTran, self.OnRouteClick, self, des, false)
end

--点击获取途径
function My:OnRouteClick(go)
	if go.name == "route1" then
		-- UIMgr.Open(UICopy.Name, self.OpenSoul, self)
		UICopy:Show(CopyType.XH)
	end
end

-- --仙魂副本界面回调
-- function My:OpenSoul(name)
-- 	local ui = UIMgr.Dic[name]
-- 	if(ui)then
-- 		ui:SetPage(15)
-- 	end
-- end

--点击碰撞器
function My:OnBoxClick()
    self:UpShow(false)
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