--[[

]]
TongtianCell=Super:New{Name="TongtianCell"}
local My = TongtianCell
local bgList = {"rank_info_g","rank_info_z","rank_info_b",""}
My.eClick=Event()

function My:Init(go)
    self.go=go
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick
    local trans = go.transform
    self.bg=CG(UISprite,trans,"bg",self.Name,false)
    self.BG=TF(trans,"BG")
    self.rank=CG(UISprite,trans,"rank",self.Name,false)
    self.lvLab=CG(UILabel,trans,"lvLab",self.Name,false)
    self.serverLab=CG(UILabel,trans,"serverLab",self.Name,false)
    self.nameLab=CG(UILabel,trans,"nameLab",self.Name,false)
    self.titleLab=CG(UILabel,trans,"titleLab",self.Name,false)
    self.numLab=CG(UILabel,trans,"numLab",self.Name,false)
    self.timeLab=CG(UILabel,trans,"timeLab",self.Name,false)
    self.btn=TF(trans,"btn")
    self.infoBtn=TF(trans,"infoBtn")
    self.light=TF(trans,"light")
    U(trans,"btn",self.Name,self.OnClick,self)
    U(trans,"infoBtn",self.Name,self.OnReqInfo,self)
    UITool.SetLsnrSelf(go,self.OnBtnState,self,self.Name)
end

function My:OnBtnState()
    if not self.data then return end
    self:InfoBtnState(true)
    My.eClick(self)
end

function My:OnReqInfo()
    local isCross = false
	if self.data.server_name~=tostring(FamilyBossInfo.server_name) then isCross=true end
    UserMgr:ReqRoleObserve(tonumber(self.data.role_id),isCross) 
end

function My:InfoBtnState(isActive)
    self.infoBtn:SetActive(isActive)
    self.light:SetActive(isActive)
end

--[[
{rank,                           int32,                           "排行"},
{role_id,                        int64,                           "role_id"},
{role_name,                      string,                          "角色名字"},
{server_name,                    string,                          "服务器名字"},
{confine_id,                     int32,                           "境界ID"},
{copy_id,                        int32,                           "最大通关副本ID"},
{use_time,                       int32,                           "用时"}
]]
function My:UpData(data)
    self.data=data
    if not data then
        self:UpMyData()
        return
    end

    local rank = data.rank
    self.bg.spriteName=bgList[rank]
    self.rank.spriteName="rank_icon_"..rank
    local color = TongtianRank.lvColor[rank] or "[F4DDBD]"
    self.lvLab.text=color..rank

    self.serverLab.text=data.server_name

    self.nameLab.text=data.role_name

    local temp = BinTool.Find(AmbitCfg,data.confine_id)
    local cfg = ""
    if temp then 
        cfg=temp.stateName or ""
    end
    self.titleLab.text=cfg


    local num = CopyMgr:GetTxIndex(data.copy_id)
    self.num=num
    self.numLab.text=tostring(num).."层"

    self.timeLab.text=DateTool.FmtSS(data.use_time)

    --是自己不显示挑战按钮
    self.btn:SetActive(self.data.role_id~=User.instance.MapData.UIDStr)

    local sss,s = math.modf( rank/2 )
    self.BG:SetActive(s==0)
    self:InfoBtnState(false)
end

function My:UpMyData()
    self.rank.spriteName=""
    self.lvLab.text="[F4DDBD]未上榜"
    self.serverLab.text=AgentMgr:GetData().serverName
    self.nameLab.text=User.instance.MapData.Name
    local robcfg = RobberyMgr:GetCurCfg()
    local cfg = ""
    if robcfg then 
        cfg=robcfg.stateName or "" 
    end
    self.titleLab.text=cfg

    local numStr,timeStr="--","--"
    if CopyMgr.TXTowerLimitIndex>-1 then
        numStr=tostring(CopyMgr.TXTowerLimitIndex)
        timeStr=DateTool.FmtSS(CopyMgr.TXTowerTimer)
    end
    self.numLab.text=numStr.."层"
    self.timeLab.text=timeStr
end

function My:OnClick()
    --未达到该层
    local lay = CopyMgr.TXTowerLimitIndex
    if lay<self.num then 
        UITip.Log("你仍未达到该层，不可挑战")
    else
        SceneMgr:ReqPreEnter(self.data.copy_id, true, true)
    end
end

function My:Open( ... )
    self.go:SetActive(true)
end

function My:Close( ... )
    self.go:SetActive(false)
end

function My:Dispose()
    Destroy(self.go)
end