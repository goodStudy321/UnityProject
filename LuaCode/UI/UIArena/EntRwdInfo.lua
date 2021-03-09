EntRwdInfo = {Name = "EntRwdInfo"}
local My = EntRwdInfo;
local GO = UnityEngine.GameObject;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:SetData(go, sldTrans, sldW, times,sprName)
    local name = go.name;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrSelf;
    local boxO = GO.Instantiate(go);
    boxO.gameObject:SetActive(true);
    boxO.name = name;
    self.root = boxO;
    local pos = self:GetPos(sldTrans.localPosition,sldW,times);
    self.BoxSprite = CG(UISprite,boxO.transform,"RwdBIcon",name,false);
    self.BoxSprite.spriteName = sprName;
    self.spriteName = sqrName;
    self.red = CG(UISprite,boxO.transform,"red",name,false);
    local label = CG(UILabel,boxO.transform,"Label",name,false);
    boxO.transform.parent = sldTrans.parent;
    boxO.transform.localPosition = pos;
    boxO.transform.localScale = Vector3.one;
    UC(boxO,self.GetRwdC,self,nil,false);
    label.text = string.format( "第%s场",times);
    self.times = times;
    self.isOpen = false;
end

function My:GetPos(sldPos,sldW,times)
    local maxTime = UIPeak.GetMaxTime();
    local posX = sldPos.x + sldW/(maxTime-1)*(times-1);
    sldPos.x = posX;
    return sldPos;
end

--领取宝箱
function My:GetRwdC(go)
    if self.isOpen then
        return;
    end
    local time = Peak.RoleInfo.enterTime
    if time == nil then
        return
    end
    if self.times > time then
        return;
    end
    Peak.ReqSoloEnterRwd(self.times);
end

function My:SetOpen()
    if self.BoxSprite == nil then
        return;
    end
    if self.isOpen == true then
        return;
    end
    self.isOpen = true;
    --self.BoxSprite.spriteName = "pvp_02";
end

function My:SetClose()
    if self.BoxSprite == nil then
        return;
    end
    if self.isOpen == false then
        return;
    end
    self.isOpen = false;
    self.BoxSprite.spriteName = self.spriteName;
end

function My:SetRed(ac)
    self.red.gameObject:SetActive(ac)
end

function My:Clear()
    GO.Destroy(self.root.gameObject);
    TableTool.ClearUserData(self);
end