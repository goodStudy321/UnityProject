JoystickMgr = { Name = "JoystickMgr"}
local My = JoystickMgr
local JoyStickCtrl = JoyStickCtrl.instance

My.UnCtrlUIList = {}

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
    local cfg = UICfg[uiName];
    if cfg == nil then
        return;
    end
    if cfg.isJsCtrl == 1 then
        return;
    end
    self:AddUnCtrlUI(uiName);
    JoyStickCtrl:SetJsCtrl(false);
end

--关闭UI
function My:CloseUI(uiName)
    local cfg = UICfg[uiName];
    if cfg == nil then
        return;
    end
    if cfg.isJsCtrl == 1 then
        return;
    end
    self:RemoveUnCtrlUI(uiName);
    local hasUctrlUI = self.HasUnCtrlUI();
    if hasUctrlUI == true then
        return;
    end
    JoyStickCtrl:SetJsCtrl(true);
end

--添加不可控UI
function My:AddUnCtrlUI(name)
    local val = self.UnCtrlUIList[name];
    if val ~= nil then
        return;
    end
    self.UnCtrlUIList[name] = 1;
end

--移除不可控UI
function My:RemoveUnCtrlUI(name)
    local val = self.UnCtrlUIList[name];
    if val == nil then
        return;
    end
    self.UnCtrlUIList[name] = nil;
end

--是否有不可控UI
function My.HasUnCtrlUI()
    for k,v in pairs(My.UnCtrlUIList) do
        if v ~= nil then
            return true;
        end
    end
    return false;
end

function My:Clear()
    for k,v in pairs(My.UnCtrlUIList) do
        My.UnCtrlUIList[k] = nil;
    end
end

function My:Dispose()
    self:RemoveLsnr();
end

return My;