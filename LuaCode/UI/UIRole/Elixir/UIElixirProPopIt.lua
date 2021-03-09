--[[
 	authors 	:Liu
 	date    	:2019-7-27 11:20:00
 	descrition 	:丹药属性项
--]]

UIElixirProPopIt = Super:New{Name="UIElixirProPopIt"}

local My = UIElixirProPopIt

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild

    self.go = root.gameObject

    self.spr = FindC(root, "spr", des)
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
end

--更新文本
function My:UpLabs(lab1, lab2, show)
    if self.timer then self.timer:Stop() end
    self.lab1.text = lab1
    self.lab2.text = (show==1) and lab2.."%" or lab2
end

--更新限时文本
function My:UpLimitLabs(lab1, lab2, show, sec, key, isFirst)
    if isFirst == true then
        local cfg = ItemData[key]
        if cfg == nil then return end
        self.lab1.text = cfg.name
        self:CreateTimer()
        self:UpTimer(sec)
    else
        self.lab1.text = lab1
        self.lab2.text = (show==1) and lab2.."%" or lab2
    end
end

--更新图片显示
function My:UpSprShow(state)
    self.spr:SetActive(state)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--更新计时器
function My:UpTimer(rTime)
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
    timer:Start()
    self:InvCountDown()
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
    timer.fmtOp = 3
	timer.apdOp = 1
end

--间隔倒计时
function My:InvCountDown()
    if self.lab2 then
        self.lab2.text = self.timer.remain
    end
end

--结束倒计时
function My:EndCountDown()
	self.lab2.text = "00:00:00"
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    self:Clear()
    self:ClearTimer()
end

return My