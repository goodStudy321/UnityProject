require("UI/UIRccnt/UIRccnt");
Rccnt = {Name = "Rccnt"}
local My = Rccnt;

function My:Init()
    self:AddLsnr();
end

--添加监听
function My:AddLsnr()
    EventMgr.Add("ShowLoading",UIRccnt.Show);
    EventMgr.Add("HideLoading",UIRccnt.Hide);
end

function My:Clear()

end

return My;