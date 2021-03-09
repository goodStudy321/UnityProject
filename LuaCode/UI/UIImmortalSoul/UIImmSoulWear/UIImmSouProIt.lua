--[[
 	authors 	:Liu
 	date    	:2018-11-10 11:10:00
 	descrition 	:仙魂属性项
--]]

UIImmSouProIt = Super:New{Name = "UIImmSouProIt"}

local My = UIImmSouProIt

function My:Init(root)
    local des = self.Name
    local CGS = ComTool.GetSelf
    local CG = ComTool.Get

    self.nameLab = CGS(UILabel, root, des)
    self.valLab = CG(UILabel, root, "lab")
    self.go = root.gameObject
end

--更新文本
function My:UpLab(name, val)
    self.go:SetActive(true)
    self.nameLab.text = name.."："
    self.valLab.text = val
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
    Destroy(self.go)
end
    
return My