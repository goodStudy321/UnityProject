--[[
 	authors 	:Liu
 	date    	:2019-6-17 19:00:00
 	descrition 	:帮派任务项
--]]

UIFamilyHelpIt = Super:New{Name = "UIFamilyHelpIt"}

local My = UIFamilyHelpIt

function My:Init(root, index)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local ED = EventDelegate

    self.starList = {}
    self.id = nil
    self.missionId = nil
    self.pos = nil
    self.isRecord = nil
    self.count = 0
    self.maxCount = nil
    self.index = index
    self.go = root.gameObject

    self.spr = CG(UISprite, root, "headSpr/spr")
    self.nameLab = CG(UILabel, root, "headSpr/name")
    self.speedLab = CG(UILabel, root, "progress/lab")
    self.starGrid = CG(UIGrid, root, "starLab/Grid")
    self.progress = CG(UISlider, root, "progress")
    self.btn = FindC(root, "btn", des)
    self.tween = CG(UITweener, root, "tex")
    self.tex = CG(UITexture, root, "tex")
    self.complete = FindC(root, "complete", des)
    self.star = FindC(root, "starLab/Grid/star", des)
    self.star:SetActive(false)

    SetB(root, "btn", des, self.OnBtn, self)
    ED.Add(self.tween.onFinished, ED.Callback(self.Complete, self))

    self:InitBtnPos(root, index)
end

--更新数据
function My:UpData(id, name, sex, vip, count, missionId)
    local cfg = FamilyMissionInfo:GetCfg(missionId)
    if cfg == nil then return end

    self.id = id
    self.missionId = missionId
    self:UpSpr(sex)
    self:UpLab(count, name, vip)
    self:UpStar(cfg.star)
    self:UpBtnState(count, vip)
end

--更新按钮状态
function My:UpBtnState(count, vip)
    -- local val = FamilyMissionInfo:GetMaxSpeed(vip) or 0
    -- local state = count < val
    -- self.btn:SetActive(state)
    -- self.complete:SetActive(not state)
    self.btn:SetActive(true)
end

--完成状态
function My:CompleteState()
    self.complete:SetActive(true)
    self.btn:SetActive(false)
    self.isRecord = true
end

--更新头像
function My:UpSpr(sex)
    local str = (sex==0) and "TX_01" or "TX_02"
    self.spr.spriteName = str
end

--更新加速文本
function My:UpLab(count, name, vip)
    local val = FamilyMissionInfo:GetMaxSpeed(vip) or 0
    self.count = tonumber(count)
    self.maxCount = val
    self.speedLab.text = string.format("已加速：%s/%s次", count or "??", val)
    self.nameLab.text = name
    self.progress.value = count/val
end

--更新次数文本
function My:UpCountLab()
    local num = self.count + 1 or 0
    self.speedLab.text = string.format("已加速：%s/%s次", num, self.maxCount)
    self.progress.value = num/self.maxCount
end

--更新星级
function My:UpStar(count)
    local Add = TransTool.AddChild
    local list = self.starList
    local gridTran = self.starGrid.transform
    local num = count - #list

    self:HideStar()
    if num > 0 then
        for i=1, num do
            local go = Instantiate(self.star)
            local tran = go.transform
            go:SetActive(true)
            Add(gridTran, tran)
            table.insert(self.starList, go)
        end
    end
    self:RefreshStar(count)
    self.starGrid:Reposition()
end

--刷新星级
function My:RefreshStar(count)
    for i=1, count do
        self.starList[i]:SetActive(true)
    end
end

--隐藏星级
function My:HideStar()
    for i,v in ipairs(self.starList) do
        v:SetActive(false)
    end
end

--点击加速按钮
function My:OnBtn()
    if self.id and self.missionId then
        FamilyMissionMgr:ReqHelp(self.id, self.missionId)
        if self.pos then
            UIFamilyHelp:PlayTween(self.pos)
        end
    end
end

--初始化按钮坐标
function My:InitBtnPos(root, index)
    local pos = self.btn.transform.localPosition
    local x = pos.x
    local y = (pos.y + 197 - root.localPosition.y) - (index * 130)
    self.pos = Vector3(x, y, 0)
end

--播放动画
function My:PlayTween()
    self.tween:ResetToBeginning()
    self.tween.gameObject:SetActive(true)
    self.tween:PlayForward()
end

--动画播放完成
function My:Complete()
    self.tween.gameObject:SetActive(false)
end

--初始化贴图
function My:InitTex(tex)
    self.tex.mainTexture = tex
end

--清空星级
function My:ClearStar()
    for i=#self.starList, 1, -1 do
        Destroy(self.starList[i])  
    end
    ListTool.Clear(self.starList)
end

--清理缓存
function My:Clear()
    self.count = 0
    self.id = nil
    self.missionId = nil
    self.pos = nil
    self.isRecord = nil
    self.maxCount = nil
    self:ClearStar()
end
    
--释放资源
function My:Dispose()
    self:Clear()
    local ED = EventDelegate
	ED.Remove(self.tween.onFinished, ED.Callback(self.Complete, self))
end

return My