--region UIPicCollectItem.lua
--Date
--此文件由[HS]创建生成


UIPicCollectItem = Super:New{Name="UIPicCollectItem"}
local M = UIPicCollectItem

local PCMgr = PicCollectMgr

function M:Init(go, noAction)
	self.Root = go
	local name = "图鉴Item"
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.NoAction = noAction
	self.Name = C(UILabel, trans, "Name", name, false)
	self.Pic = C(UITexture, trans, "Pic", name, false)
	self.Select = T(trans, "Select")
	self.NotActive = T(trans, "NotActive")
	self.Stars = ObjPool.Get(UIPicCollectStars)
	self.Stars:Init(T(trans, "Stars"))
	self.Quality = C(UISprite, trans, "Quality", name, false)
	self.IsFull = T(trans, "IsFull")
	self.Action = T(trans, "Action")
	self.Path = nil
end

function M:UpdateData(tKey, gKey, key)
	self:Clear()
	local tDic = PCMgr.TypeDic[tKey]
	if not tDic then return end
	local gDic = tDic[gKey]
	if not gDic then return end
	local pic = gDic[key]
	if not pic then return end
	self.PicId = pic.Temp.picId
	self:UpdatePicIcon(pic.Path)
	self:UpdatePic(pic)
	self:UpdateAction()
end

function M:UpdatePic(pic)
	self.Root.name = tostring(pic.Temp.picId)
	self:UpdateName(pic.Name)
	self:UpdateActive(pic.Active)
	local temp = PicCollectTemp[tostring(pic.Temp.id)]
	if temp then
		self:UpdateStar(temp)
		self:UpdateQuality(temp)
	end
end

function M:UpdateName(name)
	if self.Name then self.Name.text = name end
end

function M:UpdatePicIcon(path)
	local pic = self.Pic
	if pic then
		if not StrTool.IsNullOrEmpty(path) then	
			self.Path = path
			local del = ObjPool.Get(DelLoadTex)
			del:Add(pic)
			del:SetFunc(self.SetPicIcon,self)
			AssetMgr:Load(path,ObjHandler(del.Execute, del))
			return
		end
	end
end

function M:SetPicIcon(tex, pic)
	if pic then
		pic.mainTexture = tex
	end
end

function M:UpdateStar(temp)
	local star = self.Stars
	if star then
		star:ShowStar(temp.star)
	end
	local isfull = self.IsFull
	if isfull then
		isfull:SetActive(temp.star >= PCMgr.FullStar and temp.lv >= PCMgr.FullLv)
	end
end

function M:UpdateQuality(temp)
	local quality = self.Quality 
	if quality then
		quality.spriteName = string.format("kuang_%s",temp.quality)
	end
end

function M:SetSelect(value)
	if self.Select then
		self.Select:SetActive(value)
	end
end

function M:UpdateActive(active)
	if self.NotActive then self.NotActive:SetActive(not active) end
	if self.Stars then self.Stars:SetActive(true) end
	if self.Pic then 
		local color = Color.white
		if not active then
			color.r = 0
		end
		 self.Pic.color = color
	end
end

function M:UpdateAction()
	if self.NoAction == true then return end
	local action = self.Action
	if action then action:SetActive(PCMgr:GetPicToRed(self.PicId)) end
end

function M:Clear()
	self:UnloadPic()
	if self.Name then self.Name.text = "" end
	if self.Pic then self.Pic.mainTexture = nil end
	if self.Stars then self.Stars:Clear() end
	if self.Select then self.Select:SetActive(false) end
	self:SetSelect(false)
end

function M:UnloadPic()
	if not StrTool.IsNullOrEmpty(self.Path) then
		AssetMgr:Unload(self.Path, ".jpg", false)
	end
	self.Path = nil
end

function M:Dispose()
	if self.Stars then
		self.Stars:Dispose()
		ObjPool.Add(self.Stars)
	end
	if self.Root then 
		self.Root.transform.parent = nil
		Destroy(self.Root)
	end
	self.Root = nil
end
--endregion
