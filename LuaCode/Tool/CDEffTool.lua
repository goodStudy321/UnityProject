CDEffTool = {Name = "CDEffTool"}
local My = CDEffTool;
My.vct = Vector3.New(0,0,0);
--根据百分比设置角度
--trans(Transform)
--cdPct(float)百分比
function My.PctSetAgl(trans,cdPct)
    if LuaTool.IsNull(trans) == true then
        return;
    end
    if LuaTool.IsNull(cdPct) == true then
        return;
    end
    local angle = cdPct * 360 - 360;
    local angles = My.vct:Set(0,0,angle);
    trans.localEulerAngles = angles;
end