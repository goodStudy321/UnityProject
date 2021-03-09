--[[
 	authors 	:Liu
 	date    	:2018-7-25 09:45:00
 	descrition 	:退出前的提示界面
--]]

UIFamAnswerExitTip = Super:New{Name = "UIFamAnswerExitTip"}

local My = UIFamAnswerExitTip

function My:Init(root)
    local des, CG = self.Name ,ComTool.Get
    self.go = root.gameObject
    self.timeLab = CG(UILabel, root, "timeCount")
end

--更新倒计时文本
function My:UpTimeLab(time)
    self.timeLab.text = time
end

--清理缓存
function My:Clear()
    self.go = nil
    self.timeLab = nil
end
    
--释放资源
function My:Dispose()
	self:Clear()
end

return My