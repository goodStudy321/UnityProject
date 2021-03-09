SpirEquipAttr = { Name = "SpirEquipAttr"}
local My = SpirEquipAttr;
My.AttrTbl = {}

function My:Init(trans)
    self.root = trans.gameObject;
    local name = trans.name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;

    self.AttrLbl = CG(UILabel,trans,"scrollV/Table/AttrLbl",name,false);
    UC(trans,"btnClose",name,self.Close,self);
    self:SetGbjState(self.root,false);
end

--打开面板
function My:Open()
    self:SetShowAttr();
    self:SetGbjState(self.root,true);
end

--关闭面板
function My:Close()
    self:SetGbjState(self.root,false);
    TableTool.ClearDic(My.AttrTbl);
end

--设置对象显示状态
function My:SetGbjState(go,active)
    local isNull = LuaTool.IsNull(go);
    if isNull == nil then
        return;
    end
    self.root:SetActive(active);
end

--显示属性
function My:SetShowAttr()
    local des = My.GetAttrDes();
    self.AttrLbl.text = des;
end

--获取属性描述
function My.GetAttrDes()
    local des = nil;
    TableTool.ClearDic(My.AttrTbl);
    local equips = RobEquipsMgr.equipDic;
    local curSpirEqs = equips[SpirEquipList.curSpirId];
    if curSpirEqs == nil then
        return des;
    end
    for k,v in pairs(curSpirEqs) do
        local equipId = v.type_id;
        local excellents = v.excellents;
        local attrs = PropTool.GetEqAttrs(equipId);
        PropTool.AttrAddUp(My.AttrTbl,attrs);
        PropTool.AttrAddUp(My.AttrTbl,excellents);
    end
    des = PropTool.GetAttrsShow(My.AttrTbl);
    return des;
end