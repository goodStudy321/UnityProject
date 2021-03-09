--[[
第一名
]]
FirstCharmRank=CharmRankCell:New{Name="FirstCharmRank"}
local My = FirstCharmRank


function My:ShowModel(sex)
    local temp = GlobalTemp["196"]
    local va = temp.Value2
    self.fight.text=va[3]
    local id = nil
    if sex==1 then
        id=va[1]
    elseif sex==0 then 
        id=va[2]
    end
    local isTrue,path = DisplayModel.IsTrue(id)
    if isTrue==true then 
        self.displayModel.path=path
        self.displayModel:LoadTex()
    end
end

function My:InitCustom()
    local trans = self.go.transform
    local CG = ComTool.Get
    self.fight=CG(UILabel,trans,"fight",self.Name,false)
    self.displayModel=ObjPool.Get(DisplayModel)
    self.displayModel.layer=19
    self.displayModel:Init(trans.gameObject)
    self.severLab=CG(UILabel,trans,"serverLab",self.Name,false)
end

function My:GetName(data)
    return data.role_name
end

function My:UpDataCustom(data)
    local text =type(data)=="table" and data.server_name or ""
    self.severLab.text=text
end