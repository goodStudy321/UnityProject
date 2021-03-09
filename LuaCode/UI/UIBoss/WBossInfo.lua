WBossInfo={Name="WBossInfo"}
local My = WBossInfo

My.what=0;

function My:Init(go,go2)
    self.root2 = go2;
    self.root = go;
    local root = self.root;
    local name = root.name;
    local CG = ComTool.Get;
    self.HP = CG(UILabel,root,"Life",name,false);
    self.ATK = CG(UILabel,root,"Attack",name,false);
    self.DEF = CG(UILabel,root,"Defence",name,false);
    self.HIT = CG(UILabel,root,"Hited",name,false);
    self.AGL = CG(UILabel,root,"Dodge",name,false);
    self.BRK = CG(UILabel,root,"ArmBreak",name,false);
end

function My:chosType(bossId,what  )
    My.what=what;
   self:doActive();
    if what==0 or what==4 then
        self:SetInfo(bossId)
    elseif what ==3 then
        WBossRem:Init(self.root2);   
    end
end

function My:doActive( )
    local b = My.what==0  or My.what==4
    if self.root2~=nil then
        self.root2.gameObject:SetActive(not b);
    end
    self.root.gameObject:SetActive(b);  
end

function My:SetInfo(bossId)
    local info = BossCheater[bossId];
    if info == nil then
        return;
    end
    self.HP.text = math.NumToStrCtr(info.HP,1);
    self.ATK.text = math.NumToStrCtr(info.ATK,1);
    self.DEF.text = math.NumToStrCtr(info.DEF,1);
    self.HIT.text = math.NumToStrCtr(info.HIT,1);
    self.AGL.text = math.NumToStrCtr(info.AGL,1);
    self.BRK.text = math.NumToStrCtr(info.BRK,1);
end

--设置激活
function My:SetAct(show)
    if self.root == nil then
        return;
    end
    local go = self.root.gameObject;
    local act = go.activeSelf;
    if act == show then
        return;
    end
    go:SetActive(show);
end

function My:Dispose()
    if self.root2~=nil then
        WBossRem:Clear();
    end
    self.what=0;
    TableTool.ClearUserData(self);
end