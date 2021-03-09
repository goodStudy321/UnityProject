--[[
 	authors 	:Liu
 	date    	:2018-5-28 14:32:00
 	descrition 	:激活码界面
--]]

UIActiveCode = Super:New{Name = "UIActiveCode"}

local My = UIActiveCode

function My:Init(root)
    self.go = root.gameObject
    local des = self.Name
    self.userInput = ComTool.Get(UIInput, root, "inputBar", des, false)
    UITool.SetBtnClick(root, "getBtn", des, self.OnBtnClick, self)
    self:AddLsnr()
end

--添加监听
function My:AddLsnr()
    ActiveCodeMgr.eActCode:Add(self.RespActCodet, self)
    UILvAward.eSwitch:Add(self.RespSwitchTog, self)
end

--移除监听
function My:RemoveLsnr()
    ActiveCodeMgr.eActCode:Remove(self.RespActCodet, self)
    UILvAward.eSwitch:Remove(self.RespSwitchTog, self)
end

--响应切换Tog
function My:RespSwitchTog()
    self:Clear()
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
  end

--响应激活码
function My:RespActCodet(err)
    UITip.Log("礼包领取成功")
end

--点击领取礼包按钮
function My:OnBtnClick()
    local str = self.userInput.value
    if StrTool.IsNullOrEmpty(str) then
        --UITip.Error("激活码不能为空")
        MsgBox.ShowYes("激活码不能为空")
        return
    elseif string.len(str) < 5 then
        --UITip.Error("激活码错误，请核对后重试")
        MsgBox.ShowYes("激活码错误，请核对后重试")
        return
    end
    ActiveCodeMgr:ReqActCode(str)
end

--清理缓存
function My:Clear()
    self.userInput.value = nil
end

--释放资源
function My:Dispose()
    self.userInput.value = nil
    self:RemoveLsnr()
end

return My