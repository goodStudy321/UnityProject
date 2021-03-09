FashionAttr = Super:New{Name = "FashionAttr"}

local M = FashionAttr

function M:Init(root)
    local G = ComTool.Get
    local FG = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf

    self.go = root.gameObject
    self.fight = G(UILabel, root, "Fight")
 
    local starList = {}
    for i=1,5 do
        local path = string.format("Star/Star_%d/Highlight", i)
        table.insert(starList,FG(root, path))
    end
    self.starList = starList

    self.title = G(UILabel, root, "Title")
    self.consume = G(UILabel, root, "Consume")
 
    self.scrollView = G(UIScrollView, root, "Container/ScrollView")
    self.grid = G(UIGrid, root, "Container/ScrollView/TotalAttr")

    local trans = self.grid.transform
    self.attr1 = G(UILabel, trans, "Attr_1")
    self.attr2 = G(UILabel, trans, "Attr_2")
    self.attr3 = G(UILabel, trans, "Attr_3")
    self.attr4 = G(UILabel, trans, "Attr_4")
    self.nAttr1 = G(UILabel, trans, "Attr_1/NAttr_1")
    self.nAttr2 = G(UILabel, trans, "Attr_2/NAttr_2")
    self.nAttr3 = G(UILabel, trans, "Attr_3/NAttr_3")
    self.nAttr4 = G(UILabel, trans, "Attr_4/NAttr_4")
    self.skillDes = G(UILabel, trans, "SkillDes")

    local btnAdv = F(root, "BtnAdv")
    self.advName = G(UILabel ,btnAdv, "Name")
    local btnChange = F(root, "BtnChange")
    S(btnAdv, self.OnAdv, self)
    S(btnChange, self.OnChange, self)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:UpdateData(baseId)
    local data = FashionMgr:GetFashionData(baseId)
    if not data then return end
    self.data = data

    local text = nil;
    if data.isLimitTime == true then
        text = "激活";
    else
        text = data.isActive and "进阶" or "激活";
    end
    self.advName.text = text;

    local cfg = data.cfg
    if not cfg then return end
    self.attr1.text = string.format("[99886b]攻击：[f39800]%d[-][-]", cfg.atk)
    self.attr2.text = string.format("[99886b]防御：[f39800]%d[-][-]", cfg.def)
    self.attr3.text = string.format("[99886b]生命：[f39800]%d[-][-]", cfg.hp)
    self.attr4.text = string.format("[99886b]破甲：[f39800]%d[-][-]", cfg.arm)
    self.title.text = cfg.name
    self.fight.text = cfg.fight

    local list = self.starList
    for i=1,#list do
        list[i]:SetActive(i<=cfg.star)
    end

    local nCfg = data.nCfg
    local state = nCfg ~= nil
    if state then
        self.nAttr1.text = nCfg.atk
        self.nAttr2.text = nCfg.def
        self.nAttr3.text = nCfg.hp
        self.nAttr4.text = nCfg.arm
        local item = cfg.comsume[1]
        local str =  data.isActive and "进阶消耗:" or "激活消耗:"
        self.consume.text = string.format("[99886b]%s[f39800]【%s】[-][-]%s", str, cfg.name, ItemTool.GetConsumeOwn(item.k, item.v))
        if cfg.skillId then
            self.skillDes.text = string.format("[99886b]%s[f39800]【%s】[-][-]", data.isActive and "升级技能:" or "激活技能:", SkillLvTemp[tostring(cfg.skillId)].name)
        end
    else
        self.consume.text = "[99886b]该时装已满阶[-]"
    end


    self.attr1.gameObject:SetActive(cfg.atk > 0 or (state and nCfg.atk > 0))
    self.attr2.gameObject:SetActive(cfg.def > 0 or (state and nCfg.def > 0))
    self.attr3.gameObject:SetActive(cfg.hp > 0 or (state and nCfg.hp > 0))
    self.attr4.gameObject:SetActive(cfg.arm > 0 or (state and nCfg.arm > 0))
    self.nAttr1.gameObject:SetActive(state and nCfg.atk > 0)
    self.nAttr2.gameObject:SetActive(state and nCfg.def > 0)
    self.nAttr3.gameObject:SetActive(state and nCfg.hp > 0)
    self.nAttr4.gameObject:SetActive(state and nCfg.arm > 0)
    self.skillDes.gameObject:SetActive(cfg.skillId and state)
    self.grid:Reposition()
    self.scrollView:ResetPosition()
end


function M:OnAdv()
    if not self.data then return end
    if self.data.isLimitTime == true then
        self:DealOperation();
        return;
    end
    if not self.data.nCfg then
        UITip.Log("已升满五星")
        return 
    end
    self:DealOperation();
end

--处理操作
function M:DealOperation()
    local item = self.data.cfg.comsume[1]
    if ItemTool.NumCond(item.k, item.v) then
        FashionMgr:ReqFashionAdv(item.k, item.v)
    else
        GetWayFunc.OpenGetWay(item.k, Vector3(437, -137, 0))
    end
end

function M:OnChange()
    if User.InJump then
        UITip.Error("跳跃中不能切换奥")
        return
    end
    if not self.data.isActive then 
        UITip.Error("请先激活时装")
        return
    end
    local _type = self.data.isUse and 2 or 1
    FashionMgr:ReqFashionChange(_type, self.data.curId)
end

function M:Dispose()
    TableTool.ClearUserData(self)
    TableTool.ClearDic(self.starList)
    self.starList = nil
    self.data = nil
end

return M