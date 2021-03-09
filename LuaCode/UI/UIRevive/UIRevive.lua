local Time = UnityEngine.Time
UIRevive = UIBase:New{Name = "UIRevive"}
require("UI/UIRevive/UIReviveTime")
require("UI/UIRevive/UIReviveBoss")
local My = UIRevive
local rev = ReviveMgr;


--第三种
function My:OpenCB(name)
	local ui = UIMgr.Get(name)
	if ui then ui:UpdateData(GlobalTemp["43"].Value2[1],"秒后退出地图") end
	UICountDownTip.EndCb:Add(self.ExitC,self);
end
--退出
function My:ExitC()
    SceneMgr:QuitScene();
end

function My:InitCustom( )
	local TF = TransTool.FindChild;
	self.root1 = TF(self.root,"Revive","Revive")		
	self.root2 = TF(self.root,"UIReviveTime","UIReviveTime")	
	self.root3 = TF(self.root,"ReviveBoss","ReviveBoss")	
	local trans = self.root1.transform;
	local name = "复活界面";
	local CG = ComTool.Get;
	self.ReviveUI = TF(trans, "ReviveUI", name, false);
	self.TipUI = TF(trans, "TipUI", name, false);
	self.NorBtn = TF(self.ReviveUI.transform, "NomalRevive", name, false);
	self.NorBtnBG = TF(self.NorBtn.transform, "Background", name, false);
	self.NorBtnC = CG(UIButton,self.ReviveUI.transform,"NomalRevive",name,false);
	self.OriBtn = TF(trans, "OriginRevive", name, false);
	self.KillDescri = CG(UILabel, self.ReviveUI.transform, "KillDescribe", name, false);
	self.CostCoinNum = CG(UILabel, trans, "Cost/CostNum", name, false);
	self.CostCoinNumLab = CG(UILabel, trans, "Cost/CostDescribe", name, false);
	self.CostCoinNumLabSp = CG(UISprite, trans, "Cost/CostItemIcon", name, false);
	self.CostCoinNumLabSp.spriteName = "money_03"
	self.CostCoinNumLab.text = "(绑元不足消耗元宝)"
	self.ReviveCount = CG(UILabel, trans, "ReviveCount", name, false);
	self.KillDescText = self.KillDescri.text;
	self.ReviveCountText = self.ReviveCount.text;
	self.FreeReviveCount = CG(UILabel, self.TipUI.transform, "ReviveDescribe", name, false);
	self.FreeReviveCountText = self.FreeReviveCount.text;
	local US = UITool.SetBtnSelf;
	US(self.NorBtn.transform,self.NorReviveOnClick,self);
	US(self.OriBtn.transform,self.OriReviveOnClick,self);
	UIReviveTime:Init(self.root2)
	UIReviveBoss:Init(self.root3)		
end

function My:Choose(  )
	local reviveType = ReviveMgr.reviveType
	if reviveType==1 then
		self.root1:SetActive(true)
		self.root2:SetActive( false)
		self.root3:SetActive(false)
		self:doOpen( )
	elseif reviveType==2 then
		self.root1:SetActive(false)
		self.root2:SetActive( true)
		self.root3:SetActive(false)
		UIReviveTime:doOpen( )
	elseif reviveType==3 then
		self.root1:SetActive(false)
		self.root2:SetActive( false)
		self.root3:SetActive(false)
		UIMgr.Open(UICountDownTip.Name,self.OpenCB,self);
	elseif reviveType == 4 then
		self.root1:SetActive(false)
		self.root2:SetActive(false)
		self.root3:SetActive(true)
		UIReviveBoss:doOpen( )
	end
end

function My:doOpen( )
	self:SetReviveData();
	rev.eSecond:Add(self.UpdateShow,self);
end

function My:SetReviveData()
	self.FreeReviveTime = rev.freeReviveTime;
	if self.FreeReviveTime == 0  then
		self:SetUIState(true);
	else
		self.FreeReviveCount.text = string.gsub(self.FreeReviveCountText, "Count", self.FreeReviveTime);
		self:SetUIState(false);
	end
	self.KillDescri.text = string.gsub(self.KillDescText, "Who", rev.killerName);
	local costCoin = rev.GetReviveCost();
	self.CostCoinNum.text = tostring(costCoin);
	self.ReviveCount.text = string.gsub(self.ReviveCountText, "Time", rev.reviveTime);
end



--设置UI状态
function My:SetUIState(result)
	self.TipUI:SetActive(not result);
	self.NorBtnC.enabled = result;
	self:SetBtnBGColor(result);
end

--设置按钮背景图颜色
function My:SetBtnBGColor(result)
	if result then
		UITool.SetNormal(self.NorBtnBG)
	else
		UITool.SetGray(self.NorBtnBG)
	end
end

function My:NorReviveOnClick(gameObject)
	if self.FreeReviveTime > 0 then
		return;
	end
	rev.toSend(0)
	rev.hangUp(2);
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

function My:UpdateShow(ReviveTime)
	if ReviveTime < 0 then
		rev.toSend(0)
		rev.hangUp(2);
	else
		self.ReviveCount.text = string.gsub(self.ReviveCountText, "Time", ReviveTime);
	end
end

function My:CloseCustom( )
	self.FreeReviveTime=0;
	UIReviveTime:Clear();
	UIReviveBoss:Clear();
	rev.eSecond:Remove(self.UpdateShow,self);
end

return My