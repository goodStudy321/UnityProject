require("UI/UICharm/UICharm")
require("UI/UILoveAtFirst/UILoveAtFirst");
require("UI/UIGoodByeSingle/UIGoodByeSingle")
require("UI/UIMoonLove/UIMoonLove");
require("UI/UILimitDrop/UILimitDrop");
require("UI/UIHotLove/UIHotLove");
HeavenTg=EquipTgBase:New{Name="HeavenTg"};
local My = HeavenTg

function My:InitCustom(go)
    local TF=TransTool.FindChild
    self:InitTog(6)

    --添加要加的类
    self:InitTab(UICharm,2)
    self:InitTab(UILoveAtFirst,1); --一见钟情
    self:InitTab(UIGoodByeSingle, 4) --告别单身
    self:InitTab(UIMoonLove,6); --情缘对碰
    self:InitTab(UILimitDrop,5); -- 限时掉落
    self:InitTab(UIHotLove,3); -- 全程热恋

    local depth=self.trans:GetComponent(typeof(UIPanel)).depth
    self.depth=depth+1
    self:InitRed()
end

function My:InitRed()
    for i,v in ipairs(self.togRedList) do
        local red = HeavenLoveMgr.redList[i]
        v:SetActive(red)
    end
end

--TGTAB 表  index:对应分页的位置
function My:InitTab(TGTAB,index)
    local tg = ObjPool.Get(TGTAB)
    local uiName = tg.Name
    local del = ObjPool.Get(DelGbj)
	del:Adds(tg,index)
	del:SetFunc(self.LoadCb,self)
    LoadPrefab(uiName,GbjHandler(del.Execute,del))
end

function My:LoadCb(go,tg,index)
    go.transform:SetParent(self.trans)
	go.transform.localPosition=Vector3.zero
	go.transform.localScale=Vector3.one
    tg:Init(go)
    self.tgList[index]=tg
    UITool.Sort(go,self.depth,1)
end

function My:SetEvent(fn)
    LoveAtFirstMgr.eRed[fn](LoveAtFirstMgr.eRed,self.OnRed,self)
    GoodByeSingleMgr.eRed[fn](GoodByeSingleMgr.eRed, self.OnRed, self)
    MoonLoveMgr.eRed[fn](MoonLoveMgr.eRed,self.OnRed,self)
    HotLoveMgr.eRed[fn](HotLoveMgr.eRed, self.OnRed, self);
end

function My:SwitchTgCustom()
    local tp = self.bTp
    if tp==1 or tp == 6 or tp == 3 then return end  --过滤掉打开界面红点消失操作
    local tg = self.tgList[tp]
    local togList = self.togRedList
    local red = false
    togList[tp]:SetActive(false)
    HeavenLoveMgr.redList[tp]=red
end

function My:OnRed(isred,index)
    local togList = self.togRedList
    togList[index]:SetActive(isred)
end

