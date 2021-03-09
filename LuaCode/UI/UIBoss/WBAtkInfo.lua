WBAtkInfo = Super:New{Name = "WBAtkInfo"}
local My = WBAtkInfo;
local BBMgr = BossBatMgr.instance;
My.Flags = {attack=1,snatch=2,hitBack=3,fighting=4}

function My:Init(trans)
    local name = trans.name;
    local TF = TransTool.Find;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;

    self.mGo = trans.gameObject;
    self.mIcon = CG(UISprite, trans, "Icon");
    self.mCurHp = CG(UISprite, trans, "CurHp");
    self.mName = CG(UILabel, trans, "Name");
    UC(trans,"BtnAttack",name,self.OnAttack,self);
    local fighting = TF(trans, "BtnAttack/UI_sJ",name);
    local hitBack = TF(trans, "BtnAttack/UI_fj",name);
    local snatch = TF(trans, "BtnAttack/Snatch",name);
    local attack = TF(trans, "BtnAttack/Attack",name);
    self.FlagGo = {}
    self.FlagGo[1] = attack.gameObject;
    self.FlagGo[2] = snatch.gameObject;
    self.FlagGo[3] = hitBack.gameObject;
    self.FlagGo[4] = fighting.gameObject;
    self:ResetState();
end

--初始化归属大奖按钮
function My:InitBlgRwdBtn(trans)
    local name = trans.name;
    local UC = UITool.SetLsnrClick;
    UC(trans,"BlgRwdBtn",name,self.OnBlgRwd,self);
end

--攻击
function My:OnAttack()
    local id = self.mGo.name;
    id = string.sub( id,2,#id);
    if id == nil then
        return;
    end
    if id == User.MapData.UIDStr then
        return;
    end
    AtkInfoMgr.SetCurTarget(id);
    id = tonumber(id);
    BBMgr:AddTarget(id);
    SelectRoleMgr.instance:StartNavPath(id,1);
end

--点击归属大奖
function My:OnBlgRwd()
    WBBlgRwd:Open();
end

--激活对象
function My:SetActive(bool)
    self.mGo:SetActive(bool)
end

--设置标识状态
function My:SetFlagsState(flag)
    self:ClearFlags();
    local go = self.FlagGo[flag];
    self:SetFlagState(go,true);
    self.curFlags = flag;
end

--清除标识
function My:ClearFlags()
    local len = 4;
    for i = 1, len do
        local go = self.FlagGo[i];
        self:SetFlagState(go,false);
    end
end

--设置标识状态
function My:SetFlagState(go,state)
    if go == nil then
        return;
    end
    go:SetActive(state);
end

--重置数据
function My:ResetData()
    self:ResetState();
    self:SetActive(false);
end

--重置状态
function My:ResetState()
    self:SetFlagsState(My.Flags.attack);
end

--更新数据
function My:UpdateData(info)
    self:SetActive(true);
    self:UpdateName(info.name);
    self:UpdateIcon(info.sex);
    self:UpdateHp(info.hp, info.maxHp);
end

--设置对象名字
function My:SetGoName(id)
    if self.mGo == nil then
        return;
    end
    self.mGo.name = id;
end

--更新名字
function My:UpdateName(name)
    self.mName.text = name;
end

--更新名字颜色
function My:UpdateNameColor(colType)
    local col = RoleList.colors[colType];
    self.mName.color = col;
end

--更新头像图标
function My:UpdateIcon(sex)
    local sprName = sex == 1 and "TX_02" or "TX_01";
    self.mIcon.spriteName = sprName;
end

--更新当前血量
function My:UpdateHp(hp, maxHp)
    hp = tonumber(hp);
    maxHp = tonumber(maxHp);
    local val = hp/maxHp;
    self.mCurHp.fillAmountValue = val;
end

--更新攻击者标识
function My:SetAtkerFlag(info,isAtker)
    local hitBack = My.Flags.hitBack;
    if isAtker == true then
        if self.curFlags >= hitBack then
            return;
        end
        self.curFlags = hitBack;
        self:SetFlagsState(hitBack);
    else
        local id = info.id;
        if id == User.MapData.UIDStr then
            self:ClearFlags();
            return;
        end
        if self.curFlags > hitBack then
            return;
        end
        local blg = RoleList.IsBelonger(id);
        if blg == true then
            self:SetBlgFlag();
        else
            self:SetAttackFlag();
        end
    end
end

--设置归属者标识
function My:SetBlgFlag()
    local snatch = My.Flags.snatch;
    self.curFlags = snatch;
    self:SetFlagsState(snatch);
end

--设置当前攻击目标标识
function My:SetFightFlag()
    local fight = My.Flags.fighting;
    self.curFlags = fight;
    self:SetFlagsState(fight);
end

--设置和平攻击者标识
function My:SetAttackFlag()
    local attack = My.Flags.attack;
    self.curFlags = attack;
    self:SetFlagsState(attack);
end

--设置条目表现信息
function My:SetItemInfo(info,colType,isAtker)
    self:UpdateNameColor(colType);
    if info == nil then
        return;
    end
    self:SetFlags(info,isAtker);
end

--设置标识
function My:SetFlags(info,isAtker)
    local id = info.id;
    local isCurTar = AtkInfoMgr.IsSltTarget(id);
    if isCurTar == true then
        self:SetFightFlag();
    else
        self:SetAtkerFlag(info,isAtker);
    end
end

--销毁对象
function My:Destroy()
    local go = self.mGo;
    if go == nil then
        return;
    end
    go.transform.parent = nil;
    Destory(go)
    self.mGo = nil;
end

