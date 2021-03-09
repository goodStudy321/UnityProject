--[[
 	authors 	:Liu
 	date    	:2018-12-10 16:00:00
 	descrition 	:结婚信息界面
--]]

UIMarryInfoMenu = Super:New{Name = "UIMarryInfoMenu"}

local My = UIMarryInfoMenu

function My:Init(root)
	local des = self.Name
	local SetB = UITool.SetBtnClick

	self.go = root.gameObject

	SetB(root, "btn1", des, self.OnBtn1, self)
	SetB(root, "btn2", des, self.OnBtn2, self)
	SetB(root, "btn3", des, self.OnBtn3, self)
	SetB(root, "close", des, self.OnClose, self)
end

--点击喜结良缘
function My:OnBtn1()
	UIMarryInfo:SetMenuState(1)
end

--点击结婚商城
function My:OnBtn2()
	UIMarryInfo:SetMenuState(5)
end

--点击解除关系
function My:OnBtn3()
	UIMarryInfo:SetMenuState(6)
end

--点击关闭
function My:OnClose()
	UIMarryInfo:Close()
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
	self:Clear()
end

return My