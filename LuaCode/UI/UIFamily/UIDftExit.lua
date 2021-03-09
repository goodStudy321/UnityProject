UIDftExit = {Name="UIDftExit"}
local My = UIDftExit;

function My:Init(root)
    self.root = root;
    self.root:SetActive(false);
    local trans = root.transform;
	local name = "退出地图提示";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    self.WinG = TF(trans,"ResultSuccess",name);
    self.FailG = TF(trans,"ResultFailed",name);
    self.Star = CG(UISprite,trans,"StarLv",name);
    self.KMonsNum = CG(UILabel,trans,"KillMonsNum",name,false);
    self.Exp = CG(UILabel,trans,"Exp",name,false);
    self.HamRkExp = CG(UILabel,trans,"HamRankExp",name,false);
    self.StarExp = CG(UILabel,trans,"StarExp",name,false);
    self.FmlDaoji = CG(UILabel,trans,"FmlDaoji",name,false);
    self.FmlZijin = CG(UILabel,trans,"FmlZijin",name,false);
    UC(trans,"ExitBtn",name,self.ExitBtnC,self)
    self.TimeLbl = CG(UILabel,trans,"TimeCount",name,false);
    self.timer = ObjPool.Get(iTimer);
    self.timer.invlCb:Add(self.Tick,self);
    self.timer.complete:Add(self.TimeDone,self);
    self:Open();
end

--打开退出地图界面
function My:Open()
    local info = FamilyActivityMgr.GetDftEndInfo();
    if info == nil then
        return;
    end
    if info.dftEnd == false then
        return;
    end
    info.dftEnd = false;
    if self.root == nil then
        return;
    end
    self.root:SetActive(true);
    self:SetGbjState(info);
    if info.isWin == true then
        self:ShowWin(info);
    else
        self:ShowFail(info);
    end
    if self.timer.running == true then
        self.timer:Stop();
    end
    local time = 10;
    self.timer.seconds = time;
    self.timer:Start();
    self.TimeLbl.text = tostring(time);
end

--显示胜利
function My:ShowWin(info)
    local index = My.GetStarIndex(info.star);
    local star = string.format("star%s", index);
    self.Star.spriteName = star;
    self.KMonsNum.text = tostring(info.killMonsNum);
    self.Exp.text = math.NumToStr(info.killMonsExp);
    self.HamRkExp.text = math.NumToStr(info.harmRankExp);
    self.StarExp.text = math.NumToStr(info.starExp);
    local val1,val2 = My.GetData();
    self.FmlDaoji.text = tostring(val1);
    self.FmlZijin.text = tostring(val2);
end

--获取星级对应图片索引
function My.GetStarIndex(star)
    if star == 5 then
        return 3;
    elseif star == 4 or star == 3 then
        return 2;
    elseif star == 2 or star == 1 then
        return 1;
    end
    return 0;
end

--获取数据
function My.GetData()
    local info = GlobalTemp["28"];
    if info == nil then
        return 0,0;
    end
    local val = info.Value2;
    if val == nil then
        return 0,0;
    end
    return val[1],val[2];
end

--显示失败
function My:ShowFail(info)
    self.KMonsNum.text = tostring(info.killMonsNum);
    self.Exp.text = math.NumToStr(info.killMonsExp);
end

--设置对象状态
function My:SetGbjState(info)
    self.KMonsNum.gameObject:SetActive(true);
    self.Exp.gameObject:SetActive(true);
    if info.isWin == true then
        self.WinG:SetActive(true);
        self.FailG:SetActive(false);
        self.Star.gameObject:SetActive(true);
        self.HamRkExp.gameObject:SetActive(true);
        self.StarExp.gameObject:SetActive(true);
        self.FmlDaoji.gameObject:SetActive(true);
        self.FmlZijin.gameObject:SetActive(true);
    else
        self.WinG:SetActive(false);
        self.FailG:SetActive(true);  
        self.Star.gameObject:SetActive(false);
        self.HamRkExp.gameObject:SetActive(false);
        self.StarExp.gameObject:SetActive(false);
        self.FmlDaoji.gameObject:SetActive(false);
        self.FmlZijin.gameObject:SetActive(false);  
    end
    
end

--点击退出
function My:ExitBtnC(go)
    self.root:SetActive(false);
    SceneMgr:QuitScene();
end

--间隔计时
function My:Tick()
    if self.TimeLbl == nil then
        return;
    end
    if self.timer == nil then
        return;
    end
    local time = self.timer:GetRestTime();
    time = math.floor(time + 0.5);
    self.TimeLbl.text = string.format("%d",time);
end

--退出地图倒计时完成
function My:TimeDone()
    self.root:SetActive(false);
    SceneMgr:QuitScene();
end

function My:Clear()
    self.timer:Stop();
end

function My:Dispose()
    self.timer.complete:Clear()
    self.timer:AutoToPool();
    self.timer = nil
    TableTool.ClearUserData(self);
end