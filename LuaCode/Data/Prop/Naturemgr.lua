--[[
天机印合成
]]
Naturemgr={Name="Naturemgr"}
local My = Naturemgr
My.tab={}
My.bTpRed={}
My.bTpRed={}

function My.InitTab()
    for k,v in pairs(NatureCompose) do
        local bTp = v.bTp
		local sTp=v.sTp
		if bTp~=nil and sTp~=nil then 
			local part = v.part
			local bTpDic = My.tab[bTp]
			if not bTpDic then 
				bTpDic={}
				My.tab[bTp]=bTpDic
			end
			local sTpDic = bTpDic[sTp]
			if not sTpDic then
				sTpDic={}
				bTpDic[sTp]=sTpDic
			end
			sTpDic[part]=k
		end
    end
end

--装备合成
My.noshowRed=false --true 不再提示合成 大分页-小分页-部位-eneeenn
function My.SetRed()
	if OpenMgr:IsOpen(706)==false then return end
	local isred = false
	local dic = EquipMgr.red6Dic
	local list = My.tab
	for k,v in pairs(list) do
		local typeDic = dic[tostring(k)]
		if not typeDic then typeDic={} dic[tostring(k)]=typeDic end
		for rank,v1 in pairs(v) do
			local isrankred = false
			for part,v2 in pairs(v1) do
				local red = false
                if My.noshowRed==false then 
                    local data = NatureCompose[v2]
                    local needid = data.needId
                    local neednum = data.needNum
                    local has = PropMgr.TypeIdByNum(needid,5)
                    red=has>=neednum
                    if red==true then isred=true end
				end
				if red==true then isrankred=true break end
			end
			typeDic[rank]=isrankred
		end	
	end
	if isred~=EquipMgr.redBoolCom["6"] then 
		EquipMgr.eComRed(isred,6) 
		EquipMgr.redBoolCom["6"]=isred 
	end
    EquipMgr.eChangeComRed(6)
    
    -- iTrace.eError("xiaoyu","xxxxxxxxxxxxxxxxxxxxxxx")
	-- iTrace.eError("xiaoyu","xxxxxxxxxxxxxxxxxxxxxxx")
	-- iTrace.eError("xiaoyu","xxxxxxxxx天机印合成xxxxxxxxxxxxxx")
	-- for k,v in pairs(EquipMgr.red6Dic) do
	-- 	for k1,v1 in pairs(v) do
	-- 		iTrace.eError("xiaoyu","k : "..k.."  k1: "..k1.."  v1: "..tostring(v1))
	-- 	end
	-- end
	-- iTrace.eError("xiaoyu","天机印合成大标签  "..tostring(EquipMgr.redBoolCom["6"]))
end