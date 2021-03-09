--[[
首充特惠礼包
]]
FirstChangePack=UIBase:New{Name="FirstChangePack"}
local My = FirstChangePack

function My:InitCustom()
    local trans = self.root
    local U = UITool.SetBtnClick
    U(trans,"CloseBtn",self.Name,self.Close,self)
    U(trans,"Btn",self.Name,self.OnClick,self)
    local CG = ComTool.Get

    self.title=CG(UILabel,trans,"bg/Label",self.Name,false)
    self.OldPrice=CG(UILabel,trans,"OldPrice",self.Name,false)
    self.PriceLab=CG(UILabel,trans,"Price",self.Name,false)
    self.Grid=CG(UIGrid,trans,"Grid",self.Name,false)

    if self.list==nil then self.list={} end
    self.twoPos=Vector3.New(131.6,-71.1,0)
    self.onePos=Vector3.New(0,-71.1,0)
    self.str=ObjPool.Get(StrBuffer)
end

function My:UpData(type_id)
    self:CleanData()
    self.type_id = type_id
    local item = UIMisc.FindCreate(type_id)
    local uFxArg = item.uFxArg
    if #uFxArg==2 then
        self.str:Dispose()
        self.str:Apd("[s]"):Apd("  "):Apd(item.uFxArg[1]):Apd("  ")
        self.OldPrice.text=self.str:ToStr()
        self.PriceLab.text=item.uFxArg[2]
    else
        self.PriceLab.text=item.uFxArg[1]
    end
    self.title.text=item.name
    self.OldPrice.gameObject:SetActive(#uFxArg==2)
    
    self.PriceLab.transform.localPosition=#uFxArg==1 and self.onePos or self.twoPos

    local gift = GiftData[tostring(type_id)]
    if not gift then iTrace.eError("xiaoyu","礼包表为空 id： "..type_id)return end
    for i=1,10 do
        local item = gift["item"..i]
        if item then 
            for i1,data in ipairs(item.val) do
                local id=data.i1
                if id~=0 then 
                    local num = data.i2
                    local cell = ObjPool.Get(UIItemCell)
                    cell:InitLoadPool(self.Grid.transform)
                    cell:UpData(id,num)
                    self.list[#self.list+1]=cell
                end
            end          
        end
    end
    self.Grid:Reposition()
end

function My:OnClick()
    PropMgr.ReqUse(self.type_id,1,1)
    self:Close()
end

function My:CleanData()
    while #self.list>0 do
        local cell=self.list[#self.list]
        cell:DestroyGo()
        ObjPool.Add(cell)
        self.list[#self.list]=nil
    end
end

function My:DisposeCustom()
   self:CleanData()
end

return My