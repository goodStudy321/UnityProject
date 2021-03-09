--[[
读取屏蔽字.txt
--]]
require("Data/MaskWordCfg")
MaskWord={Name="MaskWord"}
local My=MaskWord
My.List={}
local content={}

function My.Init()
	My.ReadFile()
end

function My.ReadFile()
	--My.Split(Test[1])
	content = MaskWordCfg
	for i,v in ipairs(content) do
		--取首字符作为key
		local contentArray = string.gmatch(v,".[\128-\193]*")
		My.FirstWord(contentArray,v)
	end
	-- for k,v in pairs(My.List) do
	--   	print("k: ",k)
	-- end
end

function My.Split(tex)
	if(StrTool.IsNullOrEmpty(tex))then return end
	local pos=string.find(tex,'、')
	if(pos~=nil) then
		content[#content+1]=string.sub(tex,1,pos-1)
		tex=string.sub(tex,pos+3)
		My.Split(tex)
	else
		content[#content+1]=tex
	end
	return
end

function My.FirstWord(contentArray,v)
	for w in contentArray do
		local tb=My.List[w]
		if(tb==nil)then tb={} My.List[w]=tb end
		tb[#tb+1]=v
		return
	end
end

 --模式串中的特殊字符   ( ) . % + - * ? [ ^ $
 --  % 用作特殊字符的转义字符，比如%%匹配字符%     %[匹配字符[
local specialChar = {['(']=true,[')']=true,['.']=true,['%']=true,['+']=true,['-']=true,['*']=true,['?']=true,['[']=true,['^']=true,['$']=true}
    --检测是否有特殊字符
function My.CheckSpecialChar( msg )
    local tArray = string.gmatch(msg, ".[\128-\193]*")
    local contentArray = {}
    for w in tArray do  
        table.insert(contentArray,w)
    end
    local ck = {}
    for i=1,#contentArray do
        local v = contentArray[i]
        if specialChar[v] == true then
            table.insert(ck,'%')
        end
        table.insert(ck,v)
    end
    local result=''
    for i,v in ipairs(ck) do
        result = result..v
    end
    return result
end

--屏蔽字
function My.SMaskWord(text)
	if StrTool.IsNullOrEmpty(text) then return end
	local isMask=false --是否有屏蔽字
	local content=text
	local contentArray = string.gmatch(content,".[\128-\193]*")
	local mgc=My.List
	local value,startpos,endpos,length,star
	local startChar='*'
	for w in contentArray do
		value=mgc[w]
		if(w ~=startChar and value~=nil)then
			for i,v in ipairs(value) do
				local z=My.CheckSpecialChar(v)
				startpos,endpos=content:find(z)
				if(startpos~=nil and endpos~=nil)then
					isMask=true
					length=#(string.gsub(v,"[\128-\193]",""))
					star=''
					for i=1,length do
						star=star..startChar
					end
					content=string.gsub(content,z,star)
					break
				end
			end
		end
	end
	return content,isMask
end

function My.Clear()
	-- body
end

return My