UIReviveTime = {Name="UIReviveTime"}
local My = UIReviveTime;
local rev = ReviveMgr
function My:Init(root)
    self.root = root;
    root:SetActive(true);    
    local trans = root.transform;
	local name = "复活提示";
    local CG = ComTool.Get;
    self.TimeLbl = CG(UILabel,trans,"TimeCount",name,false);
end

function My:doOpen()
    rev.eSecond:Add(self.UpdateShow,self);
    self.TimeLbl.text = ReviveMgr.reviveTime    
end
--间隔计时
function My:UpdateShow(ReviveTime)
    if ReviveTime < 0 then
		rev.toSend(0)
        rev.hangUp(1);
	else
        self.TimeLbl.text = ReviveTime
    end
end

function My:Clear()
    rev.eSecond:Remove(self.UpdateShow,self);
end

function My:Dispose()
end

return My