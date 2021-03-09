--[[
获取来源
--]]
UIGetItemPanel=UIBase:New{Name="UIGetItemPanel"}
local My = UIGetItemPanel

function My:InitCustom()
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = self.root
    
    self.title=CG(UILabel,trans,"title",self.Name,false)
    local U = UITool.SetBtnClick
    U(trans,"CloseBtn",self.Name,self.Close,self)
    U(trans,"yesBtn",self.Name,self.YesBtn,self)
    self.yesLab=CG(UILabel,trans,"yesBtn/Label",self.Name,false)
    self.cell=ObjPool.Get(Cell)
    self.cell:Init(TF(trans,"ItemCell"))
    self.name=CG(UILabel,trans,"name",self.Name,false)
    self.des=CG(UILabel,trans,"des",self.Name,false)

end

function My:UpData(part)  
    local gid = nil
    local global=GlobalTemp["78"]
    if part=="10" then --手镯
        gid="1027"
        local id = global.Value1[1].id
        local item = ItemData[tostring(id)]
        self.cell:UpData(item)
        self.name.text=UIMisc.LabColor(item.quality)..item.name
        local data = InvestDesCfg[gid]
        self.des.text=data.des
    elseif part=="9" then --戒指
        gid="1026"
        local id = global.Value1[2].id
        local item = ItemData[tostring(id)]
        self.cell:UpData(item)
        self.name.text=UIMisc.LabColor(item.quality)..item.name
        local data = InvestDesCfg[gid]
        self.des.text=data.des
    elseif part=="11" then --精灵
        -- local idList = global.Value2
        -- for i,v in ipairs(idList) do
        --     local item = ItemData[tostring(v)]
        --     self.cell:UpData(item)
        --     self.name.text=UIMisc.LabColor(item.quality)..item.name
        --     if i==1 then gid="1028"               
        --     elseif i==2 then gid="1029" end
        --     local data = InvestDesCfg[gid]
        --     self.des.text=data.des
        -- end
    end
    
   
end


--前往获取
function My:YesBtn()
    self:Close()
    UIMgr.Open(UITreasure.Name)
end

function My:CloseCustom()
    TableTool.ClearUserData(self)
end

return My