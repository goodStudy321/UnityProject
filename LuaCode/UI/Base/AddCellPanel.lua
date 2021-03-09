--[[
增加背包格子数量
--]]
AddCellPanel = UIBase:New{Name = "AddCellPanel"}
local My=AddCellPanel

function My:InitCustom()
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    
    self.Cell=ObjPool.Get(Cell)
    self.Cell:InitLoadPool(self.root,nil,nil,nil,nil,Vector3.New(-53.7,-11.5,0))

    self.numLab=CG(UILabel,self.root,"num",self.Name,false)
    local U=UITool.SetBtnClick
    U(self.root,"Button",self.Name,self.Close,self)
    U(self.root,"OpenBtn",self.Name,self.OnOpen,self)
    U(self.root,"ReBtn",self.Name,self.ReBtn,self)
    U(self.root,"AddBtn",self.Name,self.AddBtn,self)
    --PropMgr.eUpdate:Add(self.NumUpdate,self)
    StoreMgr.eBuyResp:Add(self.BuyResp,self)
    PropMgr.eGrid:Add(self.ResqBuy,self)
    self.num=1
end

--立即开启
function My:OnOpen()
    local lack = false
    local lerp=self.num*2-self.hasNum
    if lerp>0 then lack=true end
    if lack==true then 
        StoreMgr.TypeIdBuy(102,lerp)
    else
        PropMgr.ReqGrid(self.bagId,self.num)
    end
end

function My:ReBtn()
    if self.num==1 then return end
    self.num=self.num-1
    self.numLab.text=tostring(self.num)
    self.Cell:UpLab(tostring(self.hasNum).."/"..self.num*2)
end

function My:AddBtn()
    local max = BagGrid["1"].maxNum-PropMgr.cellNumDic["1"]
    if self.num==max then return end
    self.num=self.num+1
    self.numLab.text=tostring(self.num)
    self.Cell:UpLab(tostring(self.hasNum).."/"..self.num*2)
end

function My:NumUpdate(tb,tp)
    self:UpData(self.bagId)  
end

function My:BuyResp()
    self:UpData(self.bagId)
end

function My:ResqBuy()
    self:Close()
end

function My:UpData(bagId)
    self.bagId=bagId
    local item = ItemData["102"]
    if item==nil then iTrace.eError("xiaoyu","道具表id 102 为空")return end
    
    self.hasNum = PropMgr.TypeIdByNum(102)
    self.Cell:UpData(item,tostring(self.hasNum).."/"..self.num*2)
end

function My:CloseCustom()
    StoreMgr.eBuyResp:Remove(self.BuyResp,self)
    PropMgr.eGrid:Remove(self.ResqBuy,self)
    if self.Cell then self.Cell:DestroyGo() ObjPool.Add(self.Cell) self.Cell=nil end
end

return My