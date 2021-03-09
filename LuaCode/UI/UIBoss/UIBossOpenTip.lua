UIBossOpenTip = UIBase:New{Name="UIBossOpenTip"}
local My = UIBossOpenTip
function My:InitCustom()
    --常用工具
    local tip = "UIBossOpenTip"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get

    self.dec=CG(UILabel,root,"bg/lab_dec",tip)
    self.togo=CG(UIButton,root,"bg/btn_togo",tip)
    self.title=CG(UISprite,root,"bg/spr_title",tip)
    self.close=CG(UIButton,root,"bg/close",tip)
    self:ClickEvent()
    self:Show();
end

function My:Show(  )
    if LuaTool.IsNull(self.dec) then
        UIMgr.Open(UIBossOpenTip.Name)
        return
    end
    local id = 0
    if self.index==1840 then
        id=self.index
    else
        id = 1800+self.index;
    end
    local dec = InvestDesCfg[tostring(id)].des;
    if dec==nil then
        iTrace.Error("soon","配置文本表id="..id)
        return
    end
    if self.index==1840 then
        local sdate = DateTool.GetDate(NetBoss.doubleStartTime)
        local edate = DateTool.GetDate(NetBoss.doubleEndTime)
        dec=string.format( dec,sdate.Hour,edate.Hour )
    end
    self.dec.text=dec
    self.title.spriteName="boss_tips_"..self.index
end
function My:ClickEvent()
   local US = UITool.SetLsnrSelf
   US(self.togo, self.togoClick, self)
   US(self.close, self.Close, self)
end

function My:OnClose( )
    if LuaTool.IsNull(self.root) then
        return
    end
    self:Close()
end

function My:togoClick(go)
    local id = self.index
    if self.index==1840 then
        id=2
    end
     BossHelp.OpenBoss(id)
     self:Close()
end

function My:OpenChoose(index)
    if index==nil then
        iTrace.eError("soon","index的错误")
    end
    self.index=index
    local isOpen= UIMgr.GetActive(UIBossOpenTip.Name);
    if isOpen ==-1 or isOpen==false then
        UIMgr.Open(UIBossOpenTip.Name)
    else
        self:Show();
    end
end
--禁止关闭
function My:ConDisplay()
    do return true end
end

function My:Clear()


end

return My
