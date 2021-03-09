BlackEffShow={Name="BlackEffShow"}
local My = BlackEffShow

My.CanUseLst={}
My.UseedLst={}
--一次要的数量
My.onceGetNum=3;


function My.GetCanShow( num )
    if num>1 then
       print()
    end
    My.onceGetNum=num
    local lst = {}
    -- for i=1,#My.CanUseLst do
    --     iTrace.eError("soonCanUse",My.CanUseLst[i])
    -- end
    local len1 = #My.CanUseLst
    local len2 = #My.UseedLst
    local dec = My.onceGetNum-len1
    if dec<1 then
        My.FromCanUse(  My.onceGetNum,len1,My.CanUseLst,lst,true )
    elseif dec>0 then
        My.FromCanUse(  len1,len1,My.CanUseLst,lst,true )
        My.FromCanUse( dec,len2,My.UseedLst,lst,false )
    end
    -- for i=1,#lst do
    --     iTrace.eError("soonuse",lst[i])
    -- end
    -- for i=1,#My.CanUseLst do
    --     iTrace.eError("soonUseddddddddddd",My.CanUseLst[i])
    -- end
    return lst
end

function My.FromCanUse( num,len,useLst,lst,reMove )
    if num<1 then
       return
    end
    if len<1 then
        return
     end
    local findLst = {}
    while num~=#findLst do
        local num = math.random(1,len)
        if not My.LstHave(num,findLst) then
            table.insert( findLst, num )
            table.insert( lst, useLst[num] )
        end
    end
    if reMove then
      for i=#lst,1,-1 do
        for k=1,#My.CanUseLst do
            if lst[i]==My.CanUseLst[k] then
             local t = table.remove( My.CanUseLst, k )
              table.insert( My.UseedLst, t )
            end
        end
      end
    end
end
function My.LstHave( num , lst )
    local len = #lst
    for i=1,len do
        if num==lst[i] then
            return true
        end
    end
    return false
end

function My.SetCanUseLst( id )
   table.insert( My.CanUseLst,id )
end

function My.Clear(  )
    soonTool.ClearList(My.CanUseLst)
    soonTool.ClearList(My.UseedLst)
end

return My;