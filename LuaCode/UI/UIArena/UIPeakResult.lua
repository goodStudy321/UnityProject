UIPeakResult = UIBase:New{Name = "UIPeakResult"}
local My = UIPeakResult;

function My:InitCustom()
    local root = self.root;
    local name = "1v1战斗结算界面";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    self.Promotion = TF(root,"Promotion",name);
    self.Promotion:SetActive(false);
    self.DanIcon = CG(UISprite,root,"Promotion/DanIcon",name,false);
    self.DanLbl = CG(UILabel,root,"Promotion/DanLbl",name,false);

    self.ResultFail = TF(root,"SoloResult/ResultFailed",name);
    self.ResultSuc = TF(root,"SoloResult/ResultSuccess",name);
    self.Challenge = CG(UILabel,root,"SoloResult/Challenge",name,false);
    self.DanScore = CG(UILabel,root,"SoloResult/DanScore",name,false);
    self.DanTip = CG(UILabel,root,"SoloResult/DanTip",name,false);
    self.ExpVal = CG(UILabel,root,"SoloResult/ExpVal",name,false);
    self.TimeLab = CG(UILabel,root,"SoloResult/TimeLab",name,false);
    self.TimeLab.text = "10秒后自动退出";
    UC(root,"SoloResult/OkBtn",name,self.OKBtnC,self);
    UC(root,"Promotion/PromBG",name,self.ClosePromo,self);
end

function My:AddEvent()

end

function My:RemoveCustom()

end

function My:InitTime()
    self.Timer = ObjPool.Get(iTimer)
    self.Timer.seconds = 10;
	self.Timer.invlCb:Add(self.InvCountDown, self)
    self.Timer.complete:Add(self.EndCountDown, self)
    self.Timer:Start();
end

function My:InvCountDown()
    if self.Timer == nil then
        return;
    end
    local time = self.Timer:GetRestTime();
    time = math.floor(time + 0.5);
    if self.TimeLab ~= nil then
        self.TimeLab.text = string.format("%d秒后自动退出",time);
    end
end

function My:EndCountDown()
    self:OKBtnC();
end

function My:OpenCustom()
    self:InitTime()
    self:SetResult();
end

function My:CloseCustom()

end

--打开晋级提示面板
function My:OpenPromo(score)
    local curInfo = UIPeak.GetDanInfoByScr(Peak.RoleInfo.score);
    local nxtInfo = UIPeak.GetDanInfoByScr(score);
    if curInfo.score == nxtInfo.score then
        return;
    end
    self.Promotion:SetActive(true);
    self.DanIcon.spriteName = nxtInfo.danIcon;
    self.DanLbl.text = nxtInfo.danName;
    self.Timer = ObjPool.Get(DateTimer)
    self.Timer.complete:Add(self.CloseProm, self)
    self.Timer.seconds = 3;
    self.Timer:Start();
end

--关闭晋级提示面板
function My:ClosePromo(go)
    self:CloseProm();
end

function My:CloseProm()
    self.Promotion:SetActive(false);
    self.Timer:Stop();
    ObjPool.Add(self.Timer);
end

function My:SetResult()
    local result = Peak.FightResult;
    local challenge = nil;
    local exp = string.format( "x%s",result.AddExp);
    if result.IsSucc == true then
        self.ResultFail:SetActive(false);
        self.ResultSuc:SetActive(true);
        challenge = string.format( "挑战[00ff00]%s[-]成功",result.soloRName);
    else
        self.ResultFail:SetActive(true);
        self.ResultSuc:SetActive(false);
        challenge = string.format( "挑战[00ff00]%s[-]失败",result.soloRName);
    end
    self.Challenge.text = challenge;
    self.DanScore.text = result.AddScore;
    self.ExpVal.text = exp;
    self:SetDanTip(result.NewScore);
    self:OpenPromo(result.NewScore);
end

function My:SetDanTip(score)
    local danInfo = UIPeak.GetNextDanByScr(score);
    if danInfo == nil then
        self.DanTip.text = "已经达到最顶阶[00ff00]钻石五阶[-]";
    else
        local lScore =danInfo.score - score;
        self.DanTip.text = string.format( "提升至[e9ac50]%s[-]还差[e9ac50]%s[-]积分",danInfo.danName, lScore);
    end
end

--确定点击
function My:OKBtnC(go)
    self:Close();
    self.Timer:AutoToPool();
    self.Timer = nil;
    SceneMgr:QuitScene();
end

return My;