--[[
VIP等级特权
--]]
LvInfo=Super:New{Name="LvInfo"}
local My=LvInfo

function My:Init(go)
	self.trans=go.transform
	local TF=TransTool.FindChild
	local CG=ComTool.Get

	self.Title=CG(UILabel,self.trans,"Title",self.Name,false)
	self.Grid=CG(UIGrid,self.trans,"Grid",self.Name,false)
	self.Lab=TF(self.Grid.transform,"Label")

	self.goList={}
end

function My:UpData(vipLv,title)
	self:CleanList()
	local lv=VIPLv[vipLv+1]
	if(lv==nil)then iTrace.eError("xiaoyu","VIP等级表为空 id:".. vipLv)return end
	for i=1,23 do
		local arg=lv["arg".. i]
		local text=VIPText[tostring(i)].text
		if(arg~=nil)then 
			if(type(arg)=="table")then 
				for i,v in ipairs(arg) do
					text=string.gsub(text,"#",v.val,1)
				end
			else
				text=string.gsub(text,"#",arg,1)
			end
			local go=GameObject.Instantiate(self.Lab)
			go:SetActive(true)
			go.transform.parent=self.Grid.transform
			go.transform.localScale=Vector3.one
			go.transform.localPosition=Vector3.zero
			self.goList[#self.goList+1]=go

			local lab=go:GetComponent(typeof(UILabel))
			lab.text=text
		end
	end
	self.Grid:Reposition()

	self:ShowTitle(title)
end

function My:ShowTitle(title)
	self.Title.text=title
end

function My:CleanList()
	while(#self.goList>0)do
		local go=self.goList[#self.goList]
	 	go.transform.parent=nil
	 	GameObject.Destroy(go)
	 	self.goList[#self.goList]=nil
	end
end

function My:Dispose()
	self:CleanList()
end