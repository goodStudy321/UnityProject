MergeTip = UIBase:New{Name="MergeTip"}
local My = MergeTip
My.eClose=Event()
My.curTimes=2
My.yesCb=Event()--返回选择次数
function My:InitCustom()
    --常用工具
    local tip = "MergeTip"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local UC = UITool.SetLsnrClick;
    local CG = ComTool.Get;
    local trans =self.root
    self.vipTip = TFC(trans,"vipTip",name);
    self.cpTmLab = CG(UILabel,trans,"cpTm",name,false);
    self.egTimeLab = CG(UILabel,trans,"meg/egTime",name,false);
    self.vipTipLab=CG(UILabel,trans,"vipTip",name,false)
    UC(trans,"meg/add",name,self.cilkAdd,self);
    UC(trans,"meg/dec",name,self.cilkDec,self);
    UC(trans,"Cancel",name,self.cilkClose,self);
    UC(trans,"Close",name,self.cilkClose,self);
    UC(trans,"Enter",name,self.EnterC,self);
end

function My:EnterC(  )
    My.yesCb(self.curTimes);
    self:Close();
end

function My:cilkAdd(  )
    self:NumChange(1)
end

function My:cilkDec(  )
    self:NumChange(-1)
end

function My:NumChange( num )
    if self.maxTimes==nil then
        return
    end
  local times = self.curTimes +num
  if times<2 then
    UITip.Log("最少两次")
     return
  end
  if times>self.maxTimes then
    UITip.Log("已达到最大合并次数")
    return
  end
  self.curTimes=times
  self.egTimeLab.text= self.curTimes
end

function My:cilkClose(  )
    My.eClose()
    self:Close();
end
--关闭提示
function My:Clear()
    My.curTimes=2
    My.yesCb:Clear()
end
--vipLv:VIP等级

function My:SetInfo(vipLv, curTimes,CopyTimes,maxTimes,NextVip,NextTimes,yesCb,yesObj )
    if curTimes==nil or curTimes<2 then
        curTimes=2
    end
    self.vipLv=vipLv
    self.maxTimes=maxTimes
    self.NextVip=NextVip
    self.NextTimes=NextTimes
    self.curTimes=curTimes
    self.CopyTimes=CopyTimes
    if yesCb then My.yesCb:Add(yesCb, yesObj) end
    self:UpdateInfo(  )
end

function My:UpdateInfo(  )
    if self.NextTimes==0 or self.NextTimes==nil then
        self.vipTip:SetActive(false)
    else
        self.vipTip:SetActive(true)
        self.vipTipLab.text=string.format( "VIP%s可合并次数增加到%s次",self.NextVip,self.NextTimes )
    end
    self.cpTmLab.text= self.CopyTimes
    self.egTimeLab.text= self.curTimes
end

return My
