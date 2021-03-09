--[[
 	authors 	:Liu
 	date    	:2018-12-28 10:25:00
 	descrition 	:结婚弹窗
--]]

UIMarryPop = UIBase:New{Name = "UIMarryPop"}

local My = UIMarryPop

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.lab3 = CG(UILabel, root, "lab3")

    SetB(root, "close", des, self.OnPopClose, self)
	SetB(root, "cancelBtn", des, self.OnPopClose, self)
    SetB(root, "sureBtn", des, self.OnPopClick, self)
end

--更新Panel
function My:UpPanel(str, isAllShow)
    if isAllShow == nil then isAllShow = false end
    self.isAllShow = isAllShow
    if not isAllShow then
        self.lab3.text = str
        self:SetPanelLab(false)
    else
        self.lab1.text = str
        self:SetPanelLab(true)
    end
end

--设置Panel文本状态
function My:SetPanelLab(state)
    self.lab1.gameObject:SetActive(state)
    self.lab2.gameObject:SetActive(state)
    self.lab3.gameObject:SetActive(not state)
end

--Panel点击确定
function My:OnPopClick()
    self:Close()
    MarryMgr.ePopClick(self.isAllShow)
end

--Panel点击取消/关闭
function My:OnPopClose()
    self:Close()
    MarryMgr.ePopCancel(self.isAllShow)
end

--清理缓存
function My:Clear()
    
end
    
--重写释放资源
function My:DisposeCustom()
    self:Clear()
end
    
return My