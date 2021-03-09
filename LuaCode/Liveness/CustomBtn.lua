--[[
 	authors 	:Liu
 	date    	:2018-12-6 14:25:00
 	descrition 	:公共按钮
--]]

CustomBtn = Super:New{Name = "CustomBtn"}

local My = CustomBtn

function My:Init(root, index, lab, btnList, modList)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local SetS = UITool.SetBtnSelf

    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.mark = FindC(root, "mark", des)
    self.action = FindC(root, "action", des)
    self.lab = lab
    self.index = index
    self.btnList = btnList
    self.modList = modList
    SetS(root, self.OnClick, self)
    self:InitLab()
end

--点击自身
function My:OnClick()
    -- local isMarry = MarryInfo:IsMarry()
    -- if self.index == 5 and not isMarry then
    --     UITip.Log("您尚未拥有仙侣")
    --     return
    -- end
    if self.index == 5 then
        MarryMgr:SetActionDic(5,false)
        local list = self.modList
        list[5]:Open()
        -- UIMarryGiven:Open()
    end
    self:UpState(self.index)
    self:SetModState(self.index)
end

--初始化文本
function My:InitLab()
    self.lab1.text = self.lab
    self.lab2.text = self.lab
end

--初始化状态
function My:InitState(index)
    if self.btnList == nil then return end
    for i,v in ipairs(self.btnList) do
        if index == i then
            self:UpState(index)
            self:SetModState(index)
        end
    end
end

--更新状态
function My:UpState(index)
    if self.btnList == nil then return end
    for i,v in ipairs(self.btnList) do
        if i == index then
            self:SetState(true)
        else
            v:SetState(false)
        end
    end
end

--设置模块状态
function My:SetModState(index)
    if self.modList == nil then return end
    for i,v in ipairs(self.modList) do
        if i == index then
            v.go:SetActive(true)
        else
            v.go:SetActive(false)
            if i==3 then
                v:Close()
            end
        end
    end
end

--设置状态
function My:SetState(state)
    self.mark:SetActive(state)
    self.lab2.gameObject:SetActive(state)
    self.lab1.gameObject:SetActive(not state)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My