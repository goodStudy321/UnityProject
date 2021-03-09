--[[
 	authors 	:Liu
 	date    	:2019-5-14 10:40:40
 	descrition 	:答题信息窗口
--]]

UIAnswerTips = Super:New{Name = "UIAnswerTips"}

local My = UIAnswerTips

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.res = nil
    self.go = root.gameObject

    self.right = FindC(root, "right", des)
    self.wrong = FindC(root, "wrong", des)
    self.score = CG(UILabel, root, "score/lab")
    self.exp = CG(UILabel, root, "exp/lab")

    SetB(root, "mask", des, self.OnMask, self)
end

--更新答案
function My:UpRes(res)
    self.res = res
end

function My:UpData()
    if self.res == nil then return end
    self:UpBtnState(self.res==1)
    self.exp.text = CustomInfo:ConvertNum(AnswerInfo.curExp)
    self.score.text = AnswerInfo.curScore
end

function My:UpBtnState(state)
    self.right:SetActive(state)
    self.wrong:SetActive(not state)
end

function My:OnMask()
    self:UpShow(false)
end

function My:UpShow(state)
    self.go:SetActive(state)
end

function My:Clear()
    
end

function My:Dispose()
    self:Clear()
end

return My