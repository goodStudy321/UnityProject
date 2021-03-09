--region UICellBase.lua
--Cell 道具类 拥有品质，强化等级 UILabel 一般用作数量
--此文件由[HS]创建生成

UICellQuality = baseclass(UICellLabel)

--构造函数
function UICellQuality:Ctor(go)
	self.Name = "UICellQuality"
end

--初始化控件
function UICellQuality:Init()
	self:Super("Init")
	self.Quality = ComTool.Get(UISprite, self.trans, "Quality", self.Name, false)
	self.Quality.spriteName = ""
end

--更新Quality
function UICellQuality:UpdateQuality(path)
	if self.Quality then
		self.Quality.spriteName = string.format("cell_%s", path)
	end
end

--清楚数据
function UICellQuality:Clean()
	self:Super("Clean")
	if self.Quality then self.Quality.spriteName = "" end
end

--释放或销毁
function UICellQuality:Dispose(isDestory)
	self:Super("Dispose", isDestory)
	self.Quality = nil
end
--endregion
