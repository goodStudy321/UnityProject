--[[
 	authors 	:Liu
 	date    	:2018-7-9 10:00:00
 	descrition 	:符文寻宝项
--]]

UIRuneTreasIt = Super:New{Name="UIRuneTreasIt"}

local My = UIRuneTreasIt

function My:Init(root, index, len, height, type, cfg)
    local des = self.Name
    local ED = EventDelegate
    local CGS = ComTool.GetSelf
    local SetB = UITool.SetBtnClick

    self.root = root
    self.index = index
    self.len = len
    self.height = height
    self.type = type
    self.cfg = cfg

    self.tween = CGS(TweenPosition, root, des)

    ED.Add(self.tween.onFinished, ED.Callback(self.Complete, self))

    SetB(root, "bg", des, self.OnRuneClick, self)

    self:InitRune()
end

--动画播放完成
function My:Complete()
    self:ResetAnim()
end

--初始化动画
function My:InitAnim()
    self.yPos = self.root.localPosition.y
    self.tween.from = Vector3(0, self.yPos, 0)
    self.tween.duration = self.index * 3
    self.tween:PlayForward()
end

--重置动画
function My:ResetAnim()
    self.tween:ResetToBeginning()
    self.root.localPosition = Vector3(0, -(self.len-1)*self.height, 0)
    self.tween.from = Vector3(0, self.root.localPosition.y, 0)
    self.tween.duration = self.len * 3
    self.tween:PlayForward()
end

--点击符文
function My:OnRuneClick()
    UIMgr.Open(UITreasRuneTip.Name, self.OpenRuneTip, self)
end

--符文Tip的回调方法
function My:OpenRuneTip(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        local key = tostring(self.cfg.awardId)
        local cfg = RuneCfg[key]
		ui:Refresh(cfg, self.type)
    end
end

--初始化符文
function My:InitRune()
    self.rune = ObjPool.Get(UIRuneBagItem)
    self.rune:InitByID(self.cfg.awardId, self.root)
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
	ObjPool.Add(self.rune)
    self.rune = nil
    local ED = EventDelegate
	ED.Remove(self.tween.onFinished, ED.Callback(self.Complete, self))
end

return My