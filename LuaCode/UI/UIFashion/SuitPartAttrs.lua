SuitPartAttrs = Super:New{Name = "SuitPartAttrs"}
local My = SuitPartAttrs;

function My:Init(go,allTable,scrollView)
    self.root = go;
    self.AllTable = allTable;
    self.scrollView = scrollView;
    local trans = go.transform;
    local name = trans.name;
    local CG = ComTool.Get;
    local CGS = ComTool.GetSelf;
    local UC = UITool.SetLsnrClick;

    self.Table = CGS(UITable,trans,name);
    self.InsideTable = CG(UITable,trans,"AttrInfo/Table");

    self.AttrTitle = CG(UILabel,trans,"AttrInfo");
    self.Attr = CG(UILabel,trans,"AttrInfo/Table/Attr");
    self.Attr.gameObject:SetActive(false);
    self.SkillIcon = CG(UITexture,trans,"AttrInfo/Table/SkillIcon");
    self.SkillIcon.gameObject:SetActive(false);
    self.SkillName = CG(UILabel,trans,"AttrInfo/Table/SkillIcon/Label");
    UC(trans,"AttrInfo/Table/SkillIcon",name,self.OnClickSk,self);
end

function My:UpdateData(active,attrs,skillInfo)
    self.num = self:GetNum(attrs,skillInfo);
    self:SetAttrTitle(self.num);
    self:SetSuitAttr(attrs);
    self:SetColor(active);

    local info = nil;
    if skillInfo ~= nil and self.num == skillInfo.k then
        info = skillInfo;
    end
    local isSetSkill = self:SetSkillIcon(info);
    if isSetSkill == true then
        return;
    end
    self:RepositionTbl();
end

--获取激活显示数
function My:GetNum(attrs, skillInfo)
    if attrs ~= nil then
        return attrs.num;
    end
    if skillInfo ~= nil then
        return skillInfo.k;
    end
    return nil;
end

function My:SetAttrTitle(num)
    if self.AttrTitle then
        local text = string.format("【%d】件激活",num);
        self.AttrTtlText = text;
        self.AttrTitle.text = text;
    end
end

--设置属性
function My:SetSuitAttr(attrs)
    if attrs == nil then
        return;
    end
    local suitAttrs = attrs.val;
    if suitAttrs == nil then
        return;
    end
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()

    local len = #suitAttrs;
    if len == 0 then
        return;
    end
    for i = 1, len do
        local suitAttr = suitAttrs[i];
        local attrId = suitAttr.id;
        local attrVal = suitAttr.val;
        local propName = PropName[attrId].name;
        local text = string.format("%s: %d",propName,attrVal);
        self.sb:Apd(text);
        if i < len then
            self.sb:Apd("\n");
        end
    end
    local text = self.sb:ToStr();
    self:SetAttr(text);
    self.Attr.gameObject:SetActive(true);
end

--设置属性
function My:SetAttr(text)
    if self.Attr then
        self.AttrText = text;
        self.Attr.text = text;
    end
end

--设置技能图片
function My:SetSkillIcon(skillInfo)
    if skillInfo == nil then
        return false;
    end
    self.skillInfo = true
    local skillId = skillInfo.v;
    self.skLvId = skillId;
    skillId = tostring(skillId);
    local skillCfg = SkillLvTemp[skillId];
    local skillName = skillCfg.name;
    local skillPath = skillCfg.icon;
    self.SkillName.text = skillName;
    self.skillPath = skillPath;
    self.skillName = skillName;
    AssetMgr:Load(skillPath, ObjHandler(self.SetIcon, self))
    return true;
end

--设置技能图片
function My:SetIcon(tex)
    if self.skillInfo then
        self.SkillIcon.mainTexture = tex;
        self.SkillIcon.gameObject:SetActive(true);
        self:RepositionTbl();
    else
        AssetTool.UnloadTex(tex.name)
    end
end

--刷新颜色
function My:RefreshColor(activeNum)
    local active = self.num <= activeNum;
    self:SetColor(active);
end

--设置颜色
function My:SetColor(isActive)
    local color1, color2 = "[00ff00]" , "[F4DDBD]";
    local color3 = Color.New(1,1,1);
    if not isActive  then
        color1, color2= "[99886b]", "[99886b]";
        color3 = Color.New(0,1,1);
    end
    if self.AttrTitle then
        local text = string.format("%s%s[-]",color1,self.AttrTtlText);
        self.AttrTitle.text = text;
    end
    if self.Attr then
        local text = string.format("%s%s[-]",color2,self.AttrText);
        self.Attr.text = text;
    end
    if self.SkillName then
        local text = string.format("%s%s[-]",color2,self.skillName);
        self.SkillName.text = text;
    end
    if self.SkillIcon then
        self.SkillIcon.color = color3;
    end
end

--重置UITable
function My:RepositionTbl()
    if self.InsideTable then
        self.InsideTable:Reposition();
    end
    if self.Table then
        self.Table:Reposition();
    end
    if self.AllTable then
        self.AllTable:Reposition();
    end
    if self.scrollView then
        self.scrollView:ResetPosition();
    end
end

--点击技能图标
function My:OnClickSk()
    SuitSkillTip:Show(self.skLvId,self.skillPath);
end

function My:Dispose()
    self.skillInfo = nil;
    self.AttrText = nil;
    self.AttrTtlText = nil;
    self.skillName = nil;
    self.num = nil;

    local root = self.root;
    if root ~= nil then
        root.transform.parent = nil; 
        Destroy(root);
        self.root = nil;
    end

    if self.skillPath ~= nil then
        AssetTool.UnloadTex(self.skillPath);
        self.skillPath = nil;
    end

    TableTool.ClearUserData(self);

    if self.sb then
        ObjPool.Add(self.sb)
        self.sb = nil
    end
end