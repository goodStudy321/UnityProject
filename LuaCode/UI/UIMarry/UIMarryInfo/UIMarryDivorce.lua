--[[
 	authors 	:Liu
 	date    	:2018-12-7 10:33:00
 	descrition 	:离婚面板
--]]

UIMarryDivorce = Super:New{Name = "UIMarryDivorce"}

local My = UIMarryDivorce

function My:Init(root)
    local des = self.Name
    local SetB = UITool.SetBtnClick

    self.go = root.gameObject
    SetB(root, "close", des, self.OnHide, self)
    SetB(root, "btn4", des, self.OnDivorce, self)
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	MarryMgr.ePopClick[func](MarryMgr.ePopClick, self.RespPopClick, self)
	MarryMgr.eDivorce[func](MarryMgr.eDivorce, self.RespDivorce, self)
end

--响应离婚
function My:RespDivorce()
	UIMarryInfo.pType:UpOtherInfo("请选择提亲对象", -1)
end

--响应弹窗点击
function My:RespPopClick(isAllShow)
    if not isAllShow and self.go.activeSelf then
		MarryMgr:ReqDivorce()
    end
end

--隐藏离婚界面
function My:OnHide()
    UIMarryInfo:SetMenuState(4)
end

--点击离婚
function My:OnDivorce()
    if MarryInfo:IsAppoint() then
        UITip.Log("您已预约了婚礼，当前不能离婚")
		return
    end
	local info = MarryInfo.data.coupleInfo
	if info then
		UIMgr.Open(UIMarryPop.Name, self.OpenPop, self)
	else
		UITip.Log("您未有仙侣")
	end
end

--打开弹窗
function My:OpenPop()
    local ui = UIMgr.Get(UIMarryPop.Name)
    if ui then
        ui:UpPanel("您确定要离婚吗？")
    end
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
end
    
return My