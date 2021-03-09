--[[
 	authors 	:Liu
 	date    	:2018-1-17 11:50:00
 	descrition 	:充值有礼模块
--]]

UIActComViewCZ = Super:New{Name = "UIActComViewCZ"}

local My = UIActComViewCZ

--local AssetMgr = Loong.Game.AssetMgr

function My:Init(go)
    local root = go.transform
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.go = go
    self.pathList = {}
    self.imgList = {}
    self.texList = {}
    self.cellList = {}

    self.countDown = CG(UILabel, root, "Countdown")
    self.fightLab = CG(UILabel, root, "platformBg/lab")
    self.grid = CG(UIGrid, root, "Container/ScrollView/Grid")
    self.getLab = CG(UILabel, root, "Container/btn2/lab")
    self.btnSpr = CG(UISprite, root, "Container/btn2")
    self.modelTran = Find(root, "model", des)
    self.BubbleTexture = Find(root, "BubbleTexture", des);
    self.FootTexture = Find(root, "FootTexture", des);
    self.HeadTexture = Find(root, "HeadTexture", des);
    --self.BubbleTexture:SetActive(false);
    --self.FootTexture:SetActive(false);
    --self.HeadTexture:SetActive(false);
    self.modelPos = nil;
    self.modelRotate = nil;

    SetB(root, "Container/btn1", des, self.OnBtn1, self)
    SetB(root, "Container/btn2", des, self.OnBtn2, self)

    self:InitImg(root, CG)
end

--更新数据
function My:UpdateData(data)
    self.data = data
    self:SetPathList()
    self:UpdateImg()
    self:UpItems()
    self:UpActTime()
    self:UpModel()
    self:UpdateItemList()
end

--点击充值按钮
function My:OnBtn1()
    VIPMgr.OpenVIP(1)
end

--点击领取按钮
function My:OnBtn2()
    local itemData = self:GetItemData()
    if itemData == nil then return end
    if itemData.state ~= 2 then return end
    local mgr = FestivalActMgr
    mgr:ReqBgActReward(self.data.type, 1)
end

--更新领取按钮
function My:UpdateItemList()
    local itemData = self:GetItemData()
    if itemData == nil then return end
    if itemData.state == 1 then
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
        self.getLab.text = "领取"
    elseif itemData.state == 2 then
        self.btnSpr.spriteName = "btn_figure_non_avtivity"
        self.getLab.text = "领取"
    elseif itemData.state == 3 then
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
        self.getLab.text = "已领取"
    end
end

--初始化模型
function My:UpModel()
    local data = self:GetData()
    local modelId = data.modelId
    local go = self.fightLab.transform.parent.gameObject
    go:SetActive(modelId~=0)
    self:UpFightLab()
    
    if modelId == 0 or self.modelName then return end
   
    self:TypeOfLoad(modelId);
    
    self.modelTran.gameObject:AddComponent(typeof(UIRotateMod))
end

--更新战斗力文本
function My:UpFightLab()
    local data = self:GetData()
    local go = self.fightLab.gameObject
    if go.activeSelf then
        self.fightLab.text = data.fight
    end
end

--判断资源类型(1--模型，2--气泡，3--脚底，4--头像)
function My:TypeOfLoad(modelId)
    local modelPath = self:GetPath(modelId);

    local footTemp = FashionAdvCfg[tostring(modelId)];
    local bubbleOrHeadTemp = FashionChat[tostring(tonumber(modelId)/100)];

    if footTemp then
        if footTemp.type == 5 then
            Loong.Game.AssetMgr.LoadPrefab(modelPath, GbjHandler(self.LoadFootTextureCb, self))
            return 3;
        end
    end
    if bubbleOrHeadTemp  then
        if bubbleOrHeadTemp.type == 2 then
            
            AssetMgr:Load(modelPath, ObjHandler(self.LoadHeadTextureCb, self))
            return 4;
        elseif bubbleOrHeadTemp.type == 1 then
            
            AssetMgr:Load(modelPath, ObjHandler(self.LoadBubbleTextureCb, self))
            return 2;
        end
    end
    Loong.Game.AssetMgr.LoadPrefab(modelPath, GbjHandler(self.LoadcloModCb, self))
    return 1;
end


--加载贴图
function My:LoadBubbleTextureCb(go)
    self.BubbleTexture.gameObject:SetActive(true);
    self.BubbleTexture:GetComponent(typeof(UITexture)).mainTexture = go;
end

function My:LoadFootTextureCb(go)  
    self.modelName = go.gameObject.name
    go.transform.parent = self.modelTran
    go.transform.localPosition = Vector3.New(-180, -50, 0);
    go.transform.localRotation = Quaternion.Euler(20, 0, 0);
    go.transform.localScale = Vector3.one * 360
    local layer = LayerMask.NameToLayer('UIModel')
    LayerTool.Set(go,layer);
end

function My:LoadHeadTextureCb(go)
    self.HeadTexture.gameObject:SetActive(true);
    self.HeadTexture:GetComponent(typeof(UITexture)).mainTexture = go;
end


--加载模型
function My:LoadcloModCb(go)
    self.modelName = go.gameObject.name
    go.transform.parent = self.modelTran
    if self.modelPos.x ~= nil then
        go.transform.localPosition = self.modelPos;
    end
    if self.modelRotate ~= nil then
        go.transform.localRotation = Quaternion.Euler(self.modelRotate.x, self.modelRotate.y, self.modelRotate.z);
    end
    go.transform.localScale = Vector3.one * 360
    local layer = LayerMask.NameToLayer('UIModel')

    --print("--------lyer:"..layer.."        -------UIModel:"..LayerMask.NameToLayer('UIModel'))
    LayerTool.Set(go,layer);
end

--获取路径
function My:GetPath(ID)
    local id = tostring(ID)
    

    local modelCfg = ItemModel[id];
    local modPath = nil;
    self.modelPos = modelCfg.CZPos;
    self.modelRotate = modelCfg.rotate;
    --local itemCfg = ItemData[id];
    if modelCfg.icon then 
        modPath = modelCfg.icon;
    elseif modelCfg.model then
        modPath = #modelCfg.model==1 and modelCfg.model[1] or modelCfg.model[User.instance.MapData.Sex+1]
    end
    --local cfg = FashionCfg[id]
    -- if cfg == nil then return end
    -- local key = (User.MapData.Sex==1) and cfg.mMod or cfg.wMod
    -- local modBase = RoleBaseTemp[key]
    -- if modBase == nil then return nil end
    -- local modPath = modBase.uipath
    -- if modPath ==nil then
    --     modPath = modBase.path        
    --     if modPath == nil then return end
    -- end
    return modPath
end

--更新活动时间
function My:UpActTime()
    local eDate = self.data.eDate
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

--间隔倒计时
function My:InvlCb()
    if self.countDown then
        self.countDown.text = string.format("活动结束倒计时：%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    self.countDown.text = "活动结束"
end

--更新奖励道具
function My:UpItems()
    TableTool.ClearListToPool(self.cellList)
    local itemData = self:GetItemData()
    if itemData == nil then return end
    local list = itemData.rewardList
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform, 0.8)
        cell:UpData(v.id, v.num, v.effNum==1)
        table.insert(self.cellList, cell)
    end
    self.grid:Reposition()
end

--初始化贴图
function My:InitImg(root, CG)
    for i=1, 2 do
        local img = CG(UITexture, root, "Img"..i)
        table.insert(self.imgList, img)
    end
end

--设置贴图路径列表
function My:SetPathList()
    local data = self:GetData()
    local list = {}
    local path1 = tostring(self.data.texPath)
    local path2 = tostring(data.modelImg)
    table.insert(list, path1)
    table.insert(list, path2)
    for i = #list, 1, -1 do
        if list[i] == "0" or list[i] == "undefined" then
            if self.imgList[i] then
                self.imgList[i].gameObject:SetActive(false)
            end
            table.remove(list, i)
            table.remove(self.imgList, i)
        end
    end
    -- for i,v in ipairs(list) do
    --     if v == "0" or v == "undefined" then
    --         if self.imgList[i] then
    --             self.imgList[i].gameObject:SetActive(false)
    --         end
    --         table.remove(list, i)
    --         table.remove(self.imgList, i)
    --     end
    -- end
    for i,v in ipairs(list) do
        if not StrTool.IsNullOrEmpty(v) then
            table.insert(self.pathList, v)
        end
    end
end

--更新贴图
function My:UpdateImg()
    local list = self.pathList
    local path = list[#list]
    if not path then return end 
    WWWTool.LoadTex(path, self.LoadTex, self)
end

--加载贴图
function My:LoadTex(tex, err)
    if err then
        iTrace.sLog("XGY", "图片加载失败")
    else
        local len = #self.pathList
        local it = self.imgList[len]
        if it then
            it.mainTexture = tex
            table.insert(self.texList, tex)
            table.remove(self.pathList, len)
            if #self.pathList > 0 then
                self:UpdateImg()
            end
        else
            Destroy(tex)
        end
    end
end

--获取道具项数据
function My:GetItemData()
    return self.data.itemList[1]
end

--获取数据
function My:GetData()
    return FestivalActInfo.rechargeData
end

--打开
function My:Open(data)
    self:SetActive(true)
    self:UpdateData(data)
end

--关闭
function My:Close()
    self:SetActive(false)
end

--设置状态
function My:SetActive(state)
    self.go:SetActive(state)
end

--卸载模型
function My:UnloadModel()
    if self.modelName then
        Loong.Game.AssetMgr.Instance:Unload(self.modelName, ".prefab", false)
        self.modelName = nil
    end
end

--清空贴图
function My:ClearTexList()
    local list = self.texList
    local len = #list
    for i = len, 1, -1 do
        if list[i] then
            Destroy(list[i])
            list[i] = nil
        end
    end
end

--清理缓存
function My:Clear()
    self.data = nil
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
end

-- 释放资源
function My:Dispose()
    self:Clear()
    self:ClearTexList()
    self:UnloadModel()
    TableTool.ClearListToPool(self.cellList)
end

return My