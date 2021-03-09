UIReviveBoss = {Name="UIReviveBoss"}
local My = UIReviveBoss;
local rev = ReviveMgr

function My:Init(go )
    self.root= go.transform
    local TF = TransTool.FindChild;
    local name = "复活界面";
    local CG = ComTool.Get;
    local US = UITool.SetBtnSelf;
    local trans = self.root;
    self.go = go;
    self.ReviveCount = CG(UILabel, trans, "ReviveCount", name, false);
    self.KillDescri = CG(UILabel, trans, "KillDescribe", name, false);
	self.CostCoinNum = CG(UILabel, trans, "Cost/CostNum", name, false);
	self.CostCoinNumLab = CG(UILabel, trans, "Cost/CostDescribe", name, false);
	self.CostCoinNumLabSp = CG(UISprite, trans, "Cost/CostItemIcon", name, false);
	self.CostCoinNumLabSp.spriteName = "money_03"
	self.CostCoinNumLab.text = "(绑元不足消耗元宝)"

    self.OriBtn = TF(trans, "OriginRevive", name, false);
    self.KillDescText = self.KillDescri.text;
	self.ReviveCountText = self.ReviveCount.text;
    US(self.OriBtn.transform,self.OriReviveOnClick,self);
end
function My:doOpen( )
	self:SetReviveData();
	rev.eSecond:Add(self.UpdateShow,self);
end

function My:SetReviveData()
	self.KillDescri.text = string.gsub( self.KillDescText, "Who", rev.killerName);
	local costCoin = rev.GetReviveCost();
	self.CostCoinNum.text = tostring(costCoin);
	self.ReviveCount.text = string.gsub(self.ReviveCountText , "Time", rev.reviveTime);
end

function My:UpdateShow(ReviveTime)
	if ReviveTime < 0 then
		rev.toSend(0)
		rev.hangUp(2);
    else
        local text =self.ReviveCountText 
        text=string.gsub(text, "Time", ReviveTime);
		self.ReviveCount.text = text
	end
end

function My:OriReviveOnClick(gameObject)
	local bindGold = RoleAssets.BindGold;
	local Gold = RoleAssets.Gold;
	local costCoin = rev.GetReviveCost();
	if bindGold + Gold < costCoin then
		UITip.Log("元宝不足");
		return;
	end
	rev.toSend(1)
	rev.hangUp(1)
end
function My:Clear()
    rev.eSecond:Remove(self.UpdateShow,self);
end
function My:Dispose()
end

return My