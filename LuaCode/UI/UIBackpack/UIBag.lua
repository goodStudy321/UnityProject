--[[
背包
]]
require("UI/UIBackpack/BackTip")
require("UI/UIBackpack/UIContentY")
require("UI/UIBackpack/Deal")
require("UI/UIBackpack/KeySale")
require("UI/UIBackpack/CellUpdate")

UIBag = Super:New{Name="UIBag"}
local My = UIBag

function My:Init(go)
    self.mOpen = false;

    self.go=go
    local CG = ComTool.Get
	local TF=TransTool.FindChild
    local U=UITool.SetBtnClick
    local trans = go.transform
    
    U(trans,"SaleBtn",self.Name,self.OnKeySale,self)
    U(trans,"StoreBtn",self.Name,self.OnStoreHouse,self)
    U(trans,"PutAwayBtn",self.Name,self.OnPutWay,self)

    self.pre=TF(trans,"00")
    self.panel=ObjPool.Get(UIContentY)
	self.panel:Init(go,1,true,self.pre, 4)

    self.deal=ObjPool.Get(Deal)
    self.deal:Init(TF(trans,"Deal").transform)
        
    self:OpenTip()
end

--炼器系统开启显示三个按钮
function My:OpenTip()
	local isopen=OpenMgr:IsOpen(11) or false
	if isopen==true then 
		if not self.tip then
			self.tip=ObjPool.Get(BackTip)
			self.tip:Init(TransTool.FindChild(self.go.transform,"Btns"))
		end
		self.tip:Open()
	end
end

function My:OnKeySale()
    -- self.KeySale=ObjPool.Get(KeySale)
    -- self.KeySale:Init(TF(trans,"KeySale"))
	-- self.KeySale:InitData()
    -- self.KeySale:Open()
    UIPetDevourPack.OpenPetDevPack()
end

function My:OnStoreHouse()
   UIMgr.Open(StoreHouse.Name)
end

--上架
function My:OnPutWay()
    UIAuction:OpenTabByIdxBeforOpen(4)
    UIMgr.Open(UIAuction.Name)
end

function My:SetEvent(fn)
   
end

function My:Open()
    self.mOpen = true;

    self:SetEvent("Add")
    self.go:SetActive(true)
    if self.panel then self.panel:Open() end
end

function My:Close()
    if LuaTool.IsNull(self.go)  then
        self.mOpen = false;
		return
	end
    self.go:SetActive(false)
    if self.panel then self.panel:Close() end

    if self.KeySale then self.KeySale:Close() ObjPool.Add(self.KeySale) self.KeySale=nil end
    self.mOpen = false;
end

function My:Dispose()
    self:SetEvent("Remove")
    if self.tip then ObjPool.Add(self.tip) self.tip=nil end
    if self.panel then ObjPool.Add(self.panel) self.panel=nil end   
    if self.deal then ObjPool.Add(self.deal) self.deal=nil end
    TableTool.ClearUserData(self)
    self.mOpen = false;
end

---/// LY add begin

function My:Update()
    if self.mOpen == nil or self.mOpen == false then
        return;
    end

    if self.panel ~= nil then
        self.panel:Update();
    end
end

---/// LY add end