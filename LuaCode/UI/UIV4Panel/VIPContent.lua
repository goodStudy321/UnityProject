VIPContent = Super:New{Name = "VIPContent"}
local M = VIPContent

function M:Init()
    self.AttList = {}
    self.SpriteList = {}
end

-- 1.文本 2.物体 3.间距 4.是否有图片
function M:CreateLb(root,text,pre,lerpY,value,sprRoot,sprPre)
	local t = self.AttList
	local go = GameObject.Instantiate(pre)
	go.transform.parent=root.transform
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	local y=0
	if(#t>0)then
        local last = t[#t]
        self.lbLerpY = last.printedSize.y
		y = last.transform.localPosition.y-last.printedSize.y-lerpY
	end
	go.transform.localPosition=Vector3.New(0,y,0)

	local label=go:GetComponent(typeof(UILabel))
	label.text=text
    self.AttList[#self.AttList+1]=label
    if value then
        self:CreateSprite(sprRoot,sprPre,lerpY,self.lbLerpY)
    end
end

function M:CreateSprite(root,pre,LbLerp,lerp)
    local s = self.SpriteList
    local go = GameObject.Instantiate(pre)
	go.transform.parent=root.transform
	go:SetActive(true)
    go.transform.localScale=Vector3.one
    local y = 0
	if(#s>0)then
		local last = s[#s]
		y = last.transform.localPosition.y-lerp-LbLerp
	end
	go.transform.localPosition=Vector3.New(0,y,0)

	local sprite=go:GetComponent(typeof(UISprite))
    
    self.SpriteList[#self.SpriteList+1]=sprite
end

function M:Clean()
	while(#self.AttList>0)do
		local att = self.AttList[#self.AttList].gameObject
		GameObject.Destroy(att)
		self.AttList[#self.AttList]=nil
    end
    while(#self.SpriteList>0)do
		local att = self.SpriteList[#self.SpriteList].gameObject
		GameObject.Destroy(att)
		self.SpriteList[#self.SpriteList]=nil
	end
end

function M:Dispose()
   self:Clean()
end

return M