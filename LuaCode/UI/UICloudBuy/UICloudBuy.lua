UICloudBuy=UIBase:New{Name="UICloudBuy"};
local My = UICloudBuy;
local tmBuy=require("UI/UICloudBuy/UITimeBuy")
local BigRcd=require("UI/UICloudBuy/UIBigRecord")
local activeEm = {timeBuy=1,crossBuy=2};
--当前活动
My.switch=activeEm.timeBuy;
--活动哪一个
function My:InitCustom()
    local str = ActivityTemp["135"].name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local root = self.root;
    UC(root, "CloseBtn", self.Name, self.OnClose, self);
    self.timeBuy=TF(root,"timeBuy");
    self.bigRecord=TF(root,"UIBigRecord");
    self:choose(str);
    self:OpenBigRecord(false);
    --打开后刷新红点状态
    CloudBuyMgr.isDot=false;
    CloudBuyMgr:UpRedDot();
end
--开关大奖记录
function My:OpenBigRecord(bool)
    self.bigRecord.gameObject:SetActive(bool);
    if bool==true then
        BigRcd:Init(self.bigRecord);
    end
end
--选择活动
function My:choose(str)
    self.timeBuy.gameObject:SetActive(false);
    self.timeBuy.gameObject:SetActive(false);
    if My.switch==activeEm.timeBuy then
        self.timeBuy.gameObject:SetActive(true);
        tmBuy:Init(self.timeBuy);
    elseif My.switch==activeEm.crossBuy then

    end
end

function My:OnClose()
    self:Close()
    JumpMgr.eOpenJump()
end

function My:DisposeCustom( )
    
end 

function My:Clear( )
    tmBuy:Clear();
    --BigRcd:Clear();
end

return My;