SpirEquipPack = {Name = "SpirEquipPack"}
local My = SpirEquipPack;
local GO = UnityEngine.GameObject;
--格子数量
My.CellNum = 21;
My.horNum = 7;
My.cellDic = {}
My.flag = {none = 1,up = 2,down = 3}
My.btn = {"Equip"}

function My:Init(trans)
    self.root = trans.gameObject;
    local name = trans.name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    self.ScrollV = CG(UIScrollView,trans,"ScrollView",name,false);
    self.Grid = CG(UIGrid,trans,"ScrollView/Grid",name,false);
    self.ItemCell = TF(trans,"ScrollView/Grid/ItemCell",name);
    self.ItemCell.gameObject:SetActive(false);

    UC(trans,"Button",name,self.GetEquipC,self);
    UC(trans,"closeBtn",name,self.CloseC,self);

    self:SetPackState(false);
end

function My:AddLsnr()
    PropMgr.eAdd:Add(self.AddEquip,self);
    PropMgr.eRemove:Add(self.RemoveEquip,self);
end

function My:RemoveLsnr()
    PropMgr.eAdd:Remove(self.AddEquip,self);
    PropMgr.eRemove:Remove(self.RemoveEquip,self);
end

--打开面板
function My:Open(part)
    self:SetPackState(true);
    self:InitCells(part);
    self:AddLsnr();
end

--关闭面板
function My:Close()
    self:SetPackState(false);
    self:Clear();
    self:RemoveLsnr();
end

--设置背包状态
function My:SetPackState(active)
    local root = self.root;
    if root ~= nil then
        root:SetActive(active);
    end
end

--增加装备
function My:AddEquip(tb,action,tp)
    if tp ~= 1 then
        return;
    end
    if tb == nil then
        return;
    end
    local isEquip = RobEquipsMgr.IsEquip(tb.type_id);
    if isEquip == false then
        return;
    end
    local typeId = tostring(tb.type_id);
    local part=PropTool.FindPart(typeId);
    if part ~= self.part then
        return;
    end
    self:CreateCell(tb);
end

--删除装备
function My:RemoveEquip(id,tp,typeId,action)
    if tp ~= 1 then
        return;
    end
    local isEquip = RobEquipsMgr.IsEquip(typeId);
    if isEquip == false then
        return;
    end
    local cellDic = My.cellDic;
    if cellDic == nil then
        return;
    end
    for k,v in pairs(cellDic) do
        local tb = v.tb;
        if tb ~= nil then
            if tb.id == id then
                self:RcvName(v.trans);
                v:Clean();
            end
        end
    end
    self:RfrAllFlag();
end

--恢复格子名字
function My:RcvName(trans)
    local isNull = LuaTool.IsNull(trans);
    if isNull == false then
        trans.name = "ItemCell";
    end
end

--创建格子
function My:InitCells(part)
    self.part = part;
    local equips = RobEquipsMgr.GetPartEquips(part);
    local cellNum = My.cellNum;
    local len = 0;
    if equips ~= nil then
        len = #equips;
    end
    cellNum = My.GetCellNum(len);
    self.cellNum = cellNum;
    for i = 1,cellNum do
        local go = self:CloneItem();
        local cell = ObjPool.Get(UIItemCell);
        cell:Init(go);
        My.cellDic[i] = cell;
    end
    self.Grid:Reposition();
    self.ScrollV:ResetPosition();
    if len == 0 then
        return;
    end
    for i = 1,len do
        local propTb = equips[i];
        if propTb ~= nil then
            self:SetCellData(i,propTb);
        end
    end
end

--设置格子数据
function My:SetCellData(index,propTb)
    local cell = My.cellDic[index];
    local typeId = propTb.type_id;
    local tb = propTb
    -- propTb:CopyTbData(tb);
    cell:UpData(typeId,1);
    cell:TipData(tb,tb.num,My.btn,true,true);
    cell:UpBind(tb.bind);
    cell.trans.name = tostring(tb.id);
    self:SetFlag(cell,self.part,propTb);
end

--创建格子
function My:CreateCell(propTb)
    if propTb == nil then
        return;
    end
    local index = self:GetUnUseIndex();
    if index == nil then
        index = self.cellNum + 1;
        self.cellNum = self.cellNum + My.horNum;
        for i = index,self.cellNum do
            local go = self:CloneItem();
            local cell = ObjPool.Get(UIItemCell);
            cell:Init(go);
            My.cellDic[i] = cell;
        end
        self.Grid:Reposition();
    end
    self:SetCellData(index,propTb);
end

--获取不使用格子索引
function My:GetUnUseIndex()
    local cellDic = My.cellDic;
    for k,v in pairs(cellDic) do
        local trans = v.trans;
        local isNull = LuaTool.IsNull(trans);
        if isNull == false then
            if trans.name == "ItemCell" then
                return k;
            end
        end
    end
    return nil;
end

--刷新所有标识
function My:RfrAllFlag()
    local cellDic = My.cellDic;
    if cellDic == nil then
        return;
    end
    for k,v in pairs(cellDic) do
        local trans = v.trans;
        local isNull = LuaTool.IsNull(trans);
        if isNull == false then
            if trans.name ~= "ItemCell" then
                local typeId = tostring(v.tb.type_id);
                local part = PropTool.FindPart(typeId);
                self:SetFlag(v,part,typeId);
            end
        end
    end
end

--设置标识
function My:SetFlag(cell,part,propTb)
    local flag = self:GetUpDownFlag(part,propTb);
    if flag == My.flag.none then
        cell:IconUp(false);
        cell:IconDown(false);
    elseif flag == My.flag.up then
        cell:IconUp(true);
        cell:IconDown(false);
    else
        cell:IconUp(false);
        cell:IconDown(true);
    end
end

--获取上下箭头标识
function My:GetUpDownFlag(part,propTb)
    local curSpirId = SpirEquipList.curSpirId;
    local hasWearEq = RobEquipsMgr.IsWearEquip(curSpirId,part);
    if hasWearEq == false then
        return My.flag.up;
    end
    local flag = nil;
    local tb = RobEquipsMgr.GetSpirEqTb(curSpirId,part);
    local oldFight = PropTool.Fight(tb);
    local newFight = PropTool.Fight(propTb);
    if oldFight > newFight then
        flag = My.flag.down;
    elseif oldFight < newFight then
        flag = My.flag.up;
    else
        flag = My.flag.none;
    end
    return flag;
end

--获取格子数量
function My.GetCellNum(len)
    local cellNum = My.CellNum;
    if len > cellNum then
        local num = len - cellNum;
        local param = math.floor(num/My.horNum);
        local mod = math.fmod(num,My.horNum);
        if mod > 0 then
            mod = 1;
        end
        cellNum = cellNum + (param + mod) * My.horNum; 
    end
    return cellNum;
end

--克隆对象
function My:CloneItem()
    local go = self.ItemCell;
    local root = GO.Instantiate(go);
    root.name = go.name;
    root.transform.parent = go.transform.parent;
    root.transform.localPosition = Vector3.zero;
    root.transform.localScale = Vector3.one;
    root.gameObject:SetActive(true);
    return root;
end

--点击获取装备
function My:GetEquipC(go)
    UIMgr.Open(UIBoss.Name);
end

--点击关闭
function My:CloseC(go)
    self:Close();
end

--清除格子
function My:ClearCells()
    local cells = My.cellDic;
    if cells == nil then
        return;
    end
    local length = #cells;
    if length == 0 then
        return;
    end
    local dc = nil;
    for i = 1, length do
        dc = cells[i];
        dc:Destroy();
        ObjPool.Add(dc);
        cells[i] = nil;
    end
end

--清除数据
function My:Clear()
    self.part = 0;
    self.cellIndex = 0;
    self.cellNum = 0;
    self:ClearCells();
end

--释放
function My:Dispose()
    self:Close();
end