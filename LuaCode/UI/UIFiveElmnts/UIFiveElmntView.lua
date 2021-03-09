UIFiveElmntView = {Name = "UIFiveElmntView"}
local My = UIFiveElmntView;
local BKMgr = BossKillMgr.instance;

function My:Init(trans)
    self.root = trans.gameObject;
    local name = trans.name;
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    self.DefAttr = TF(trans,"DefAttrInfo",name);
    self.DefAttrLbl = CG(UILabel,trans,"DefAttrInfo",name,false);
    self.NonDefAttr = TF(trans,"NoneDefAttr",name);
    UC(trans,"CloseBtn",name,self.Close,self);
    UC(trans,"DefAttrInfo/GotoBtn",name,self.GotoBtnC,self);
    UC(trans,"NoneDefAttr/GotoBtn",name,self.GotoBtnC,self);
    self:SetGoActive(self.root,false);
end

--打开界面
function My:Open(monsId)
    self:SetDefAttr(monsId);
    self:SetGoActive(self.root,true);
    self.monsId = tonumber(monsId);
end

--关闭
function My:Close()
    self:SetGoActive(self.root,false);
    --取消选择
    UIFiveElmntAttr.SelectItem(nil);
end

--设置位置
function My:SetViewPos(noDef)
    local item = UIFiveElmntAttr.monsItem;
    local localPos = nil;
    local pos = nil;
    if noDef == true then
        localPos = Vector3.New(148,40,0);
        pos = item.trans:TransformPoint(localPos);
        self:SetGoPos(self.NonDefAttr,pos);
    else
        localPos = Vector3.New(143,142,0);
        pos = item.trans:TransformPoint(localPos);
        self:SetGoPos(self.DefAttr,pos);
    end
end

--设置对象位置
function My:SetGoPos(go,pos)
    if go == nil then
        return;
    end
    local trans = go.transform;
    if trans == nil then
        return;
    end
    trans.position = pos;
end

--设置属性
function My:SetDefAttr(monsId)
    local noDef,text,stfy = FiveElmtMgr.GetMonsFEDef(monsId);
    self.stfy = stfy;
    self:SetViewPos(noDef);
    if noDef == true then
        self:SetGoActive(self.DefAttr,false);
        self:SetGoActive(self.NonDefAttr,true);
    else
        self:SetGoActive(self.DefAttr,true);
        self:SetGoActive(self.NonDefAttr,false);
        self:SetDefAttrLbl(text);
    end
end

--设置抗性文本
function My:SetDefAttrLbl(text)
    if self.DefAttrLbl == nil then
        return;
    end
    self.DefAttrLbl.text = text;
end

--设置对象状态
function My:SetGoActive(go,active)
    if go == nil then
        return;
    end
    go:SetActive(active);
end

--点击前往
function My:GotoBtnC()
    if self.stfy == true then
        local monsId = UIFiveElmntAttr.monsItem.monsId;
        local pos = FiveElmtMgr.GetMonsPos(monsId);
        BKMgr:StartNavPath(pos,0,2,monsId);
        self:Close();
    else
        local msg = "你的五行攻击属性不足以攻破怪物的防御，将不会对怪物产生伤害，是否继续前往？";
        MsgBox.ShowYesNo(msg,self.YesCb, self, "前往" , self.NoCb, self, "取消");
    end
end

--前往回调
function My:YesCb()
    local monsId = UIFiveElmntAttr.monsItem.monsId;
    local pos = FiveElmtMgr.GetMonsPos(monsId);
    BKMgr:StartNavPath(pos,0,2,monsId);
    self:Close();
end

--取消回调
function My:NoCb()
    self:Close();
end

function My:Dispose()
    -- body
end