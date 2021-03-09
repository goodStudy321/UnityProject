UICtrlHgup = { Name = "UICtrlHgup"}
local My = UICtrlHgup


function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    euiopen:Add(self.OpenUI,self);
    euiclose:Add(self.CloseUI,self);
end

function My:RemoveLsnr()
    euiopen:Remove(self.OpenUI,self);
    euiclose:Remove(self.CloseUI,self);
end

--打开UI
function My:OpenUI(uiName)
    local filted = My.FiltedUI(uiName);
    if filted == true then
        return;
    end
    local cfg = UICfg[uiName];
    if cfg == nil then
        return;
    end
    if cfg.isPauseHg == 0 then
        return;
    end
    Hangup:Pause(uiName);
end

--关闭UI
function My:CloseUI(uiName)
    local filted = My.FiltedUI(uiName);
    if filted == true then
        return;
    end
    local cfg = UICfg[uiName];
    if cfg == nil then
        return;
    end
    if cfg.isPauseHg == 0 then
        return;
    end
    Hangup:Resume(uiName);
end

--过滤UI
function My.FiltedUI(name)
    if name == nil then
        return false;
    end
    if name == UIGdAward.Name then
        return true;
    end
    if name == UIShowPendant.Name then
        return true;
    end
    if name == UIOnWay.Name then
        return true;
    end
end

function My:Clear()

end

function My:Dispose()
    self:RemoveLsnr();
end

return My;