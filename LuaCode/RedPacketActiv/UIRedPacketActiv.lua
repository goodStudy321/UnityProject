--[[
    全服红包活动
]]
require("RedPacketActiv/RedPacketItem");

UIRedPacketActiv = Super:New{Name = UIRedPacketActiv};
local My = UIRedPacketActiv;

function My:Init(root)
    local TFC = TransTool.FindChild;
    local USS = UITool.SetLsnrSelf;
    local CG = ComTool.Get;

    self.trans = root;
    self.go = root.gameObject;

    self.timeLabel = CG(UILabel, self.trans, "bg/Label2/Label");
    self.contentLabel = CG(UILabel, self.trans, "bg/Label1/Label");

    self.itemObj = TFC(self.trans, "ScrollViewAera/ScrollView/Grid/RedItem");
    self.itemObj:SetActive(false);
    self.gridObj = TFC(self.trans, "ScrollViewAera/ScrollView/Grid");

    self.grid = CG(UIGrid, self.trans, "ScrollViewAera/ScrollView/Grid");

    self.redItemList = {};
    self.redObjList ={};
    self.redCount = 0;

    self.waitTime = 0;
    self.startUp = false;

    self:InitLabel();
    self:InitRedItem();
    self:SetLuaEvent("Add");
end

function My:SetLuaEvent(fn)
    RedPacketActivMgr.eUpdateRed[fn](RedPacketActivMgr.eUpdateRed, self.InitRedItem, self);
end

function My:InitLabel()
    local info = NewActivMgr:GetActivInfo(2011);
    if not info then return end;
    local DateTime = System.DateTime;
    local startTime = DateTool.GetDate(info.startTime):ToString("MM月dd日HH:mm");
    local endTime = DateTool.GetDate(info.endTime):ToString("MM月dd日HH:mm");
    self.timeLabel.text = StrTool.Concat(startTime, " - ", endTime);
    self.contentLabel.text = InvestDesCfg["22"].des;
end


function My:InitRedItem()
    --self.redCount = RedPacketActivMgr:GetRedCount();
    self.redCount = 0;
    if #self.redItemList > 0 then
        for i = 1, #self.redItemList do
            self.redItemList[i]:Dispose();
            ObjPool.Add(self.redItemList[i]);
        end
        self.redItemList = {};
    end
    if #self.redObjList > 0 then
        for i = 1, #self.redObjList do
            Destroy(self.redObjList[i]);
        end
        self.redObjList = {};
    end
    for k,v in ipairs(RedPacketActivMgr.redPacketList) do
        self:CloneItem(v);
    end
    self.startUp = true;
end

function My:CloneItem(data)
    local AddC = TransTool.AddChild;
    local go = Instantiate(self.itemObj);
    go:SetActive(false);
    local parent = self.grid.transform;
    local trans = go.transform;
    trans.localPosition = parent.localPosition;
    go:SetActive(true);
    table.insert(self.redObjList, go);

    local redItem = ObjPool.Get(RedPacketItem);
    redItem:Init(go);
    redItem:UpdateRed(data);
    local name = tostring(data.id);
    go.name = name;
    table.insert(self.redItemList, redItem);
    AddC(parent, trans);
end

function My:Update()
    if self.startUp == true then
        self.waitTime = self.waitTime + 1;
        if self.waitTime >= 2 then
            self.grid:Reposition();
            self.waitTime = 0;
            self.startUp = false;
        end
    end
end

function My:UpShow(state)
    self.go:SetActive(state)
end

function My:Dispose()
    for i = 1, #self.redItemList do
        self.redItemList[i]:Dispose();
        ObjPool.Add(self.redItemList[i]);
    end
    self.redItemList = nil;
    self:SetLuaEvent("Remove");
    self.redCount = 0;
end


return My;