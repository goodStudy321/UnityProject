FeverHelp={Name="FeverHelp"}
local My = FeverHelp
---数据形式
    -- Region[i].start
    -- Region[i].over
    -- Region[i].num
--end
My.priceRegion=nil
My.OnePrice=0
My.curLayer=1

function My.BuyBack( )
    FeverFindView:ShowKeyNum(My.curLayer)
    local rwdls = TreaFeverMgr.curAwardIds[My.curLayer]
    FeverFindView:DoAnim(rwdls)
end
function My.ShowData(index )
    FeverFindView:Show(index)
end

function My.GetAllPrice( num,layer )
    local OpenNumLst = TreaFeverMgr:GetOpenNum()
    local OpenStart = OpenNumLst[layer]+1
    local OpenEnd = OpenStart+num-1
    local once = num==1
    local needKey = 0
    local needGold = 0
    local AllGold = 0
    local Region= My.priceRegion
    local len = #Region
    for i=1,len do
        local info = Region[i]
        if info.start<=OpenStart and OpenStart<=info.over then
            local hkey = info.over-OpenStart+1
            if hkey>=num then
                needKey=num*info.num
                break;
            else
                needKey=needKey+hkey*info.num
            end
        else
            if not once then
                if info.start<=OpenEnd and OpenEnd<=info.over then
                    local hkey = OpenEnd-info.start+1
                    if hkey>=num then
                        needKey=num*info.num
                        break;
                    else
                        needKey=needKey+hkey*info.num
                    end
                elseif OpenEnd>=info.over and OpenStart<=info.start then
                    local hkey = info.over-info.start+1
                    needKey=needKey+hkey*info.num
                end
            end
        end
    end
    local iconId = GlobalTemp["153"].Value2[1]
    local haveKey = PropMgr.TypeIdByNum(iconId)
    needGold = (needKey-haveKey)*My.OnePrice 
    AllGold=needKey*My.OnePrice 
    return needKey,haveKey ,needGold,AllGold
end
function My.IsHasMoney(needGold)
    if RoleAssets.Gold <= needGold then
        StoreMgr.JumpRechange()
        return false
    end
    return true
end
--获取bossUI位置
function My.GetBossUi(montId)
    local info = tFeverBoss[tostring(montId)];
    if info == nil then
        iTrace.Error("soon","配置宝藏副本UI表id"..montId)
        return nil;
    end
    return info;
end

function My.Clear()
    My.curLayer=1
end

return My;