CoupleSuitPart = Super:New{Name = "CoupleSuitPart"}
local My = CoupleSuitPart;

--点击返回我的套装
My.eBackMySuit = Event();

function My:Ctor()
    self.cellList = {};
end

function My:Init(trans)
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    local name = trans.name;

    self.go = trans.gameObject;
    self.grid = CG(UIGrid, trans, "ScrollView/Grid");
    self.prefab = TFC(self.grid.transform, "Cell");
    self.prefab:SetActive(false);
    UC(trans,"BtnMySuit",name,self.MySuitOnClick,self);
    UC(trans,"BtnGive",name,self.GiveOnClick,self);
    self:SetLsnr("Add");
end

function My:SetLsnr(key)
    SuitPartCell.eClick[key](SuitPartCell.eClick,self.OnClickCell,self);
end

--点击格子
function My:OnClickCell(data)
    self.fashion = data;
end

function My:Open(data)
    self.data = data;
    self:SetActive(true);
    self:UpdateData();
end

function My:Close()
    self:SetActive(false);
end

function My:SetActive(state)
    self.go:SetActive(state);
end

function My:UpdateData()
    local suit = FashionMgr:GetCoupleSuitUnit(self.data.id);
    local data = suit.fashionList;
    if not data then return end
    local list = self.cellList;
    local len = #data;
    local count = #list;
    local max = count >= len and count or len;
    local min = count + len - max;
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true);
            list[i]:UpdateData(data[i]);
        elseif i <= count then
            list[i]:SetActive(false);
        else
            local go = Instantiate(self.prefab);
            TransTool.AddChild(self.grid.transform, go.transform);
            local cell = ObjPool.Get(SuitPartCell);
            cell:Init(go);
            cell:SetActive(true);
            cell:UpdateData(data[i]);
            table.insert(self.cellList, cell);
        end
    end
    self.grid:Reposition();
end

--返回我的套装
function My:MySuitOnClick()
    SuitPartCell:Clear();
    My.eBackMySuit();
end

--点击赠送
function My:GiveOnClick()
    local isMarry = MarryInfo:IsMarry();
    if isMarry == true then
        local baseId = self.fashion.baseId;
        local shopId = self.fashion.shopId;
        local stCfg = StoreData[tostring(shopId)];
        if not stCfg then
            local msg = "商城无此物品，无法赠送";
            UITip.Log(msg);
            return false;
        end
        --限购VIP等级
        local vipLv = stCfg.vipLv or 0;
        if vipLv>VIPMgr.GetVIPLv() then
            local msg = "vip等级不足";
            UITip.Log(msg);
            return false;
        end
        --价格
        local price = stCfg.curPrice;
        local des = RoleAssets:GetTypeName(stCfg.priceTp);
        local fashionName = self.fashion.name;
        local msg = string.format("是否花费[00ff00]%d%s[-]赠送[00ff00]%s[-]给您的仙侣？",price,des,fashionName);
        MsgBox.CloseOpt = MsgBoxCloseOpt.No
		MsgBox.ShowYesNo(msg,self.OKBtn, self);
    else
        local msg = "您还未有仙侣,无法赠送";
        UITip.Log(msg);
    end
end

function My:OKBtn()
    local baseId = self.fashion.baseId;
    local shopId = self.fashion.shopId;
    local stCfg = StoreData[tostring(shopId)];
    local price = stCfg.curPrice;
    local isEnough=RoleAssets.IsEnoughAsset(stCfg.priceTp, price);
    if isEnough==false then
        local des = RoleAssets:GetTypeName(stCfg.priceTp);
        local msg = string.format("%s不足",des);
        UITip.Log(msg);
        return false;
    end
    FashionMgr:ReqFashionGive(baseId);
end

function My:Dispose()
    self:SetLsnr("Remove");
    TableTool.ClearDicToPool(self.cellList);
    TableTool.ClearUserData(self);
end

return My