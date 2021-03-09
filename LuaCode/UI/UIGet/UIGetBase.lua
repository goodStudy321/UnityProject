--[[
获得来源
--]]
UIGetBase=Super:New{Name="UIGetBase"}
local My=UIGetBase

function My:Init(trans,pos)
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    
    local U = UITool.SetBtnClick
    self.att=TF(trans,"att")
    U(trans,"yesBtn",self.Name,self.YesBtn,self)
    self.cell=ObjPool.Get(Cell)
    self.cell:InitLoadPool(trans,nil,nil,nil,nil,pos)
    self.name=CG(UILabel,trans,"name",self.Name,false)
    self.des=CG(UILabel,trans,"des",self.Name,false)
end

--戒指，手镯，小精灵，小仙女
function My:UpData(type)
    self.type=type
    local global=GlobalTemp["78"]
    local val2 = global.Value2
    local addNum = 1025+type
    local data = InvestDesCfg[tostring(addNum)]
    self.des.text=data.des

    local item = ItemData[tostring(val2[type])]
    self.type_id=item.id
    self.cell:UpData(item)
    self.name.text=UIMisc.LabColor(item.quality)..item.name

    self:AttActive(type<=2)
end

function My:YesBtn()
    if not self.type then return end
    if self.type<=2 then 
        UITreasure:OpenTab(1)
    elseif self.type>2 then
        StoreMgr.OpenStoreId(self.type_id)
    end
end

function My:AttActive(active)
    self.att:SetActive(active)
end

function My:Dispose()
    self.type=nil
    if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end
end