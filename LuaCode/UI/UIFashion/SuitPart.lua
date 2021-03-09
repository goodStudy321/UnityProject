SuitPart = Super:New{Name = "SuitPart"}

require("UI/UIFashion/SuitPartCell")
require("UI/UIFashion/SuitPartAttrs")

local M = SuitPart
M.eClickCouple = Event();

function M:Ctor()
    self.cellList = {}
    self.attrList = {}
end

function M:Init(trans)
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.go = trans.gameObject
    self.scrV = G(UIScrollView,trans,"ScrollView")
    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    self.prefab = FC(self.grid.transform, "Cell")
    self.fight = G(UILabel, trans, "Fight")
    self.name = G(UILabel, trans, "Name")

    self.SvAttr = G(UIScrollView,trans,"SvAttr");
    self.AllTable = G(UITable,trans,"SvAttr/AllTable");
    self.TableGbj = FC(trans,"SvAttr/AllTable/Table");
    self.TableGbj:SetActive(false);

    -- self.tab =  G(UITable, trans, "SvAttr/Table")
    -- self.attr = G(UILabel, self.tab.transform, "Attr")
    -- self.skillDes = G(UILabel, self.tab.transform, "SkillDes")

    self.btnsGrid = G(UIGrid, trans,"BtnsGrid")
    self.btnCouple = FC(trans,"BtnsGrid/BtnCouple")
    self.btnAdv = FC(trans, "BtnsGrid/BtnAdv")
    self.btnAdvRedP = FC(trans,"BtnsGrid/BtnAdv/RedPoint")
    self.btnAdvRedP:SetActive(false);
    self.active = FC(trans, "BtnsGrid/Active")
    self.prefab:SetActive(false)

    S(self.btnCouple, self.OnCouple, self)
    S(self.btnAdv, self.OnAdv, self)
end

--点击查看仙侣
function M:OnCouple()
    SuitPartCell:Clear();
    M.eClickCouple(self.data);
end

function M:OnAdv()
    local data = self.data;
    local actNum = FashionHelper.GetActNum(data);
    if actNum == nil then
        return;
    end
    FashionMgr:ReqFashionSuit(self.data.id,actNum)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Close()
    self:SetActive(false)
end

function M:Open(data)
    self.data = data
    self:SetActive(true)
    self:UpdateCell()
    --self:UpdateAttr()
    self:SetAttrList()
    self:UpdateActive()
    self:UpdateCoupleBtn()
    self:UpdateBtn()
    self:UpdateBtnRedP()
    self:UpdateFight()
    self:UpdateName()
    self:Reposition()
end

function M:Refresh()
    self:UpdateBtn()
    self:UpdateBtnRedP()
    self:UpdateName()
    --self:UpdateAttr()
    self:UpdateAttrsColor()
    self:UpdateActive()
    self:Reposition()
end

function M:UpdateCell()
    local data = self.data.fashionList
    local list = self.cellList
    local len = #data
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform, go.transform)
            local cell = ObjPool.Get(SuitPartCell)
            cell:Init(go)
            cell:SetActive(true)
            cell:UpdateData(data[i])
            table.insert(self.cellList, cell)
        end
    end
    self.grid:Reposition()
end

function M:UpdateAttr()
    local data = self.data.attrList
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
    local sb = self.sb
    local len = #data
    local color1, color2 = "[99886b]" , "[F39800FF]"
    if not self.data.isActive  then
        color1, color2= "[9C9C9CFF]", "[9C9C9CFF]"
    end
    for i=1, len do
        local name = PropName[data[i].k].name
        local arg = string.format("%s%s：%s%s", color1, name, color2 ,data[i].v)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.attr.text = str

    local skillId = self.data.skillId
    if skillId then
        self.skillDes.text = string.format("[99886b]激活技能:[F39800FF]【%s】[-][-]", SkillLvTemp[tostring(skillId)].name)
        self.skillDes.gameObject:SetActive(true)
    else
        self.skillDes.gameObject:SetActive(false)
    end
    self.tab:Reposition()
end

--设置属性列表
function M:SetAttrList()
    local fashionList = self.data.fashionList;
    if fashionList == nil then
        return;
    end
    local len = # fashionList;
    if self.data.type == 2 then
        len = len * 2;
    end
    TableTool.ClearDicToPool(self.attrList)
    for k = 1, len do
        local attrs = self.data.attrList;
        local skillInfo = self.data.skillInfo;
        local attr = nil;
        local skInfo = nil;
        local has = false;
        for i = 1, #attrs do
            if attrs[i] ~= nil and k == attrs[i].num then
                has = true;
                attr = attrs[i];
            end
        end
        if skillInfo ~= nil and k == skillInfo.k then
            has = true;
            skInfo = skillInfo;
        end
        if has == true then
            self:CreateAttrItem(attr,skInfo);
        end
    end
end

--创建属性
function M:CreateAttrItem(attr,skillInfo)
    local activeNum = self.data.activeNum;
    if attr == nil and skillInfo == nil then
        return;
    end
    local attrGbj = Instantiate(self.TableGbj);
    local attrTrans = attrGbj.transform;
    local parent = self.AllTable.transform;
    TransTool.AddChild(parent, attrTrans);
    attrGbj:SetActive(true);
    local active = false;
    if attr ~= nil and attr.num <= activeNum then
        active = true;
    end
    if skillInfo ~= nil and skillInfo.k <= activeNum then
        active = true;
    end
    local partAttr = ObjPool.Get(SuitPartAttrs);
    partAttr:Init(attrGbj,self.AllTable,self.SvAttr);
    partAttr:UpdateData(active,attr,skillInfo);
    table.insert(self.attrList, partAttr);
end

--设置属性颜色
function M:UpdateAttrsColor()
    local activeNum = self.data.activeNum;
    for i = 1, #self.attrList do
        local partAttrs = self.attrList[i];
        partAttrs:RefreshColor(activeNum);
    end
end

function M:UpdateCoupleBtn()
    if self.data.type == 2 then
        self.btnCouple:SetActive(true)
    else
        self.btnCouple:SetActive(false)
    end
end

function M:UpdateBtn()
    self.btnAdv:SetActive(not self.data.isActive)
end

function M:UpdateBtnRedP()
    local red = false;
    local actNum = FashionHelper.GetActNum(self.data);
    if actNum ~= nil then
        red = true;
    end
    self.btnAdvRedP:SetActive(red);
end

function M:UpdateActive()
    self.active:SetActive(self.data.isActive)
end

function M:Reposition()
    self.btnsGrid:Reposition()
    self.scrV:ResetPosition();
end

function M:UpdateFight()
    self.fight.text = self.data.fight
end

function M:UpdateName()
    local name = self.data.name;
    local allNum = #self.data.fashionList;
    if self.data.type == 2 then
        allNum = allNum * 2;
    end
    local activeNum = FashionHelper.GetAllSuitActNum(self.data);
    local text = string.format("%s (%d/%d)",name,activeNum,allNum);
    self.name.text = text;
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearDicToPool(self.attrList)
    if self.sb then
        ObjPool.Add(self.sb)
        self.sb = nil
    end
end

return M