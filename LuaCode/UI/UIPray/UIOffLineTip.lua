--离线奖励脚本

UIOffLineTip=UIBase:New{Name ="UIOffLineTip"}
local  My = UIOffLineTip
My.Glist={}
function My:InitCustom()
    local name = self.Name
    local root =self.root
    local CG = ComTool.Get
    local TFC = TransTool.FindChild
    local TF = TransTool.Find
    local US = UITool.SetLsnrSelf


	self.des3 = TFC(root, "table/des3")
	self.des4 = TFC(root, "table/des4")
	self.des5 = TFC(root, "table/des5")
	self.des6 = TFC(root, "table/des6")

	self.oldLab = CG(UILabel,root,"des0/oldLv")
	self.newLab = CG(UILabel,root,"des0/newLv")
	self.timeLab=CG(UILabel,root,"des1/time")
	self.expLab=CG(UILabel,root,"des2/getExp")
	self.illusionLab=CG(UILabel,root,"table/des3/getIllusion")
	self.intensifyLab=CG(UILabel,root,"table/des4/getIntensify")
	self.cLab=CG(UILabel,root,"table/des5/cl")
	self.gLab=CG(UILabel,root,"table/des5/gl")
	self.dLab=CG(UILabel,root,"table/des6/dl")

	self.expTex=CG(UITexture,root,"des2/exp")
	self.illusionTex=CG(UITexture,root,"table/des3/illusion")
	self.intensifyTex=CG(UITexture,root,"table/des4/intensify")
	self.cTex=CG(UITexture,root,"table/des5/c")
	self.gTex=CG(UITexture,root,"table/des5/g")
	self.dTex=CG(UITexture,root,"table/des6/d")
	self.ysBtn = CG(UIButton,root,"bg/yesBtn")

	self.tab = CG(UITable,root,"table")
	US(self.ysBtn, self.YesCb, self)
	local cls = TFC(root, "CloseBtn")
	US(cls, self.YesCb, self)
end


function My:OpenCustom()
	self:RefreshData()
end

function My:RefreshData()
	self.tabItemId = {"100","25","700006","1","3","12"}  -- 经验    幻力   天机勾玉
	self.tabTex = {self.expTex,self.illusionTex,self.intensifyTex,self.cTex,self.gTex,self.dTex}
	self.tabTexIcon = {}
	-- local expCfg = ItemData["100"]
	-- local path = expCfg.icon
	-- AssetMgr:Load(path,ObjHandler(self.LoadTex,self))
	self:LoadTexs()
	local time = PrayMgr.OffLineTime
	local exp = PrayMgr.OffLineExp
	local old = PrayMgr.OldLv
	local new = PrayMgr.NewLv
	local illusion = PrayMgr.Illusion
	local intensify = PrayMgr.Intensify
	local coin = PrayMgr.BCopper
	local bGold = PrayMgr.BGold
	local box = PrayMgr.Box

	self.des3:SetActive(illusion >= 0)
	self.des4:SetActive(intensify >= 0)
	self.des5:SetActive(coin >= 0)
	self.des6:SetActive(box >= 0)

	exp = math.NumToStrCtr(exp)
	illusion = math.NumToStrCtr(illusion)
	intensify = math.NumToStrCtr(intensify)
	coin = math.NumToStrCtr(coin)
	time = DateTool.FmtSec(time)
	time = string.format("%s",time)
	old = string.format("%s级",old)
	new = string.format("%s级",new)
	self.timeLab.text = time
	self.expLab.text = exp
	self.illusionLab.text = illusion
	self.intensifyLab.text = intensify
	self.oldLab.text = old
	self.newLab.text = new
	self.cLab.text = coin
	self.gLab.text = bGold
	self.dLab.text = box
	self.tab:Reposition()
end

function My:LoadTexs()
	local len = #self.tabItemId
	for i = 1,len do
		self:TexFunc(i)
	end
end

function My:TexFunc(index)
	local id = self.tabItemId[index]
	local tex = self.tabTex[index]
	local cfg = ItemData[id]
	local path = cfg.icon
	if index == 1 then
		AssetMgr:Load(path,ObjHandler(self.LoadTex1,self))
	elseif index == 2 then
		AssetMgr:Load(path,ObjHandler(self.LoadTex2,self))
	elseif index == 3 then
		AssetMgr:Load(path,ObjHandler(self.LoadTex3,self))
	elseif index == 4 then
		AssetMgr:Load(path,ObjHandler(self.LoadTex4,self))
	elseif index == 5 then
		AssetMgr:Load(path,ObjHandler(self.LoadTex5,self))
	elseif index == 6 then
		AssetMgr:Load(path,ObjHandler(self.LoadTex6,self))
	end
end

function My:LoadTex1(obj)
	local tex = self.tabTex[1]
	tex.mainTexture = obj
	local texName = obj.name
	table.insert(self.tabTexIcon,texName)
end

function My:LoadTex2(obj)
	local tex = self.tabTex[2]
	tex.mainTexture = obj
	local texName = obj.name
	table.insert(self.tabTexIcon,texName)
end

function My:LoadTex3(obj)
	local tex = self.tabTex[3]
	tex.mainTexture = obj
	local texName = obj.name
	table.insert(self.tabTexIcon,texName)
end

function My:LoadTex4(obj)
	local tex = self.tabTex[4]
	tex.mainTexture = obj
	local texName = obj.name
	table.insert(self.tabTexIcon,texName)
end

function My:LoadTex5(obj)
	local tex = self.tabTex[5]
	tex.mainTexture = obj
	local texName = obj.name
	table.insert(self.tabTexIcon,texName)
end

function My:LoadTex6(obj)
	local tex = self.tabTex[6]
	tex.mainTexture = obj
	local texName = obj.name
	table.insert(self.tabTexIcon,texName)
end

function My:UnLoadExp()
	if #self.tabTexIcon > 0 then
		for i = 1,#self.tabTexIcon do
			local name = self.tabTexIcon[i]
			AssetTool.UnloadTex(name)
			self.tabTexIcon[i] = nil
		end
	end
end

function My:YesCb()
	self:Close()
end

function My:DisposeCustom()
	self:UnLoadExp()
end

return My