require("UI/UIFiveElmnts/DropEffInfo")
SecretDropEff = {Name = "SecretDropEff"}
local My = SecretDropEff;
local AssetMgr=Loong.Game.AssetMgr
--掉落特效列表
My.DropEffList = {}
My.MainCam = nil;

function My:Init(pos)
    My.FindMainCamera();
    self:AddTarPos(pos);
end

--获取主摄像机
function My.FindMainCamera()
    local name = "Root<Camera>";
    local camGo = GameObject.Find(name);
    if camGo == nil then
        return;
    end
    local CGS = ComTool.GetSelf;
    My.MainCam = CGS(Camera,camGo,name);
end

--添加监听
function My:AddLsnr()
    EventMgr.Add("PickDrop",EventHandler(self.AddDrop,self));
end

--移除监听
function My:RemoveLsnr()
    EventMgr.Remove("PickDrop",EventHandler(self.AddDrop,self));
end

--添加目标位置
function My:AddTarPos(pos)
    self.TarPos = pos;
end

--添加天机印掉落位置
function My:AddDrop(dropId,itemId,pos)
    itemId = tostring(itemId);
    local cfg = SMSProTemp[itemId];
    if cfg == nil then
        return;
    end
    local info = My.DropEffList[dropId];
    if info ~= nil then
        return;
    end
    info = ObjPool.Get(DropEffInfo);
    info:SetData(dropId,pos,self.TarPos);
    My.DropEffList[dropId] = info;
    local path = "FX_UI_GoldlTrail";
	AssetMgr.LoadPrefab(path,GbjHandler(info.LoadCb,info));
end

--清除数据
function My:Clear()
    TableTool.ClearListToPool(My.DropEffList);
end

--更新特效位置
function My.UpdateEffPos()
    for k,v in pairs(My.DropEffList) do
        local done = v:Update();
        if done == true then
            v:DestroyGo();
            ObjPool.Add(v);
            My.DropEffList[k] = nil;
        end
    end
end

--更新
function My:Update()
    My.UpdateEffPos();
end