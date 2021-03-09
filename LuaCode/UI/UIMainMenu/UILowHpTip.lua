UILowHpTip = {Name = "UILowHpTip"}
local My = UILowHpTip;

--初始化
function My:Init(trans)
    self.gbj = trans.gameObject;
    self.gbj:SetActive(false);
end

--设置提示
function My:SetTip()
    if self.gbj == nil then
        return;
    end
    local ratio = User.MapData.HPRation;
    if ratio == 0 then
        self.gbj:SetActive(false);
    end
    if ratio > 0.15 then
        if self.gbj.activeSelf == true then
            self.gbj:SetActive(false);
        end
        return;
    end
    self.gbj:SetActive(true);
end