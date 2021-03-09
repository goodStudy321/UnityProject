UIRccnt = {Name = "UIRccnt"}
local My = UIRccnt;
local AssetMgr = Loong.Game.AssetMgr;
My.go = nil;
local uiName = "RccntLD";

--显示加载界面
function My.Show()
    local go = My.go;
    if go ~= nil then
        go.gameObject:SetActive(true)
    else
        AssetMgr.LoadPrefab(uiName,GbjHandler(My.LoadDone,My));
    end
end

--隐藏加载界面
function My.Hide()
    local go = My.go;
    if go == nil then
        return;
    end
    go:SetActive(false)
end

--加载完成
function My:LoadDone(go)
    if go == nil then
        return;
    end
    My.go = go;
    AssetMgr.Instance:SetPersist(uiName, ".prefab",true);
    local p = UIMgr.HCam.transform;
    local c = go.transform;
    TransTool.AddChild(p,c);
end