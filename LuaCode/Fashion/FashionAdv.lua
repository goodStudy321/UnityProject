FashionAdv = Super:New{Name="FashionAdv"}
local My = FashionAdv;
--设置数据
function My:SetData(cfg)
    self.name = cfg.name    --名称
    self.atk = cfg.atk  --攻击
    self.def = cfg.def      --防御
    self.hp = cfg.hp    --生命
    self.arm = cfg.arm   --破甲
    self.fight = cfg.fight
    self.star = cfg.star --当前阶数
    self.comsume = cfg.comsume --升星消耗
    self.skillId = cfg.skillId
end

function My:Clear()
    self.name = "";    --名称
    self.atk = 0;  --攻击
    self.def = 0;      --防御
    self.hp = 0;    --生命
    self.arm = 0;   --破甲
    self.fight = 0;
    self.star = 0; --当前阶数
    self.comsume = nil; --升星消耗
    self.skillId = 0;
end

function My:Dispose()
    self:Clear();
end