--[[
 	authors 	:Liu
 	date    	:2018-5-2 10:27:40
 	descrition 	:退出前的提示界面
--]]

UIAnswerExitTip = Super:New{Name = "UIAnswerExitTip"}

local My = UIAnswerExitTip

function My:Init(root)
    local des, CG = self.Name ,ComTool.Get
    self.go = root.gameObject
    self.timeLab = CG(UILabel, root, "timeCount")
end

--更新倒计时文本
function My:UpTimeLab(time)
    self.timeLab.text = time
    UIAnswer.tips:UpShow(false)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    
end

return My