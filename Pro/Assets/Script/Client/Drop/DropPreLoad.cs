using System;
using Loong.Game;

public class DropPreLoad
{
    public static readonly DropPreLoad instance = new DropPreLoad();

    private DropPreLoad() { }
    #region 私有方法
    /// <summary>
    /// 怪物表中首次掉落
    /// </summary>
    private void PreloadFirstDrop(uint unitTypeId)
    {
        MonsterAtt moster = MonsterAttManager.instance.Find(unitTypeId);
        if (moster == null) return;
        if (moster.firstDrops.list.Count == 0) return;
        for (int i = 0; i < moster.firstDrops.list.Count; i++)
        {
            UInt32 id = moster.firstDrops.list[i].dropid;//首次掉落type_id
            ItemData data = GetItemData(id);
            if (data == null)
            {
                iTrace.eLog("xiaoyu", string.Format("道具为空，表id为{0}", id));
                return;
            }
            string modelName = data.model;
            if (!string.IsNullOrEmpty(modelName))
                PreloadMgr.prefab.Add(modelName);
        }
    }

    /// <summary>
    /// 掉落Boss表
    /// </summary>
    /// <param name="unitTypeId"></param>
    private void PreloadDropBoss(uint unitTypeId)
    {
        DropBoss dropBoss = DropBossManager.instance.Find(unitTypeId);
        if (dropBoss == null) return;
        //特殊掉落
        UInt32 specialId = dropBoss.specialDrop;
        PreloadSpecialDrop(specialId);

        //掉落组
        UInt32 drop1 = dropBoss.drop1;
        PreloadDrop(drop1);
        UInt32 drop2 = dropBoss.drop2;
        PreloadDrop(drop2);
        UInt32 drop3 = dropBoss.drop3;
        PreloadDrop(drop3);
        UInt32 drop4 = dropBoss.drop4;
        PreloadDrop(drop4);
        UInt32 drop5 = dropBoss.drop5;
        PreloadDrop(drop5);
        UInt32 drop6 = dropBoss.drop6;
        PreloadDrop(drop6);
        UInt32 drop7 = dropBoss.drop7;
        PreloadDrop(drop7);
        UInt32 drop8 = dropBoss.drop8;
        PreloadDrop(drop8);
        UInt32 drop9 = dropBoss.drop9;
        PreloadDrop(drop9);
        UInt32 drop10 = dropBoss.drop10;
        PreloadDrop(drop10);
        UInt32 drop11 = dropBoss.drop11;
        PreloadDrop(drop11);
        UInt32 drop12 = dropBoss.drop12;
        PreloadDrop(drop12);
        UInt32 drop13 = dropBoss.drop13;
        PreloadDrop(drop13);
        UInt32 drop14 = dropBoss.drop14;
        PreloadDrop(drop14);
        UInt32 drop15 = dropBoss.drop15;
        PreloadDrop(drop15);
        UInt32 drop16 = dropBoss.drop16;
        PreloadDrop(drop16);
        UInt32 drop17 = dropBoss.drop17;
        PreloadDrop(drop17);
        UInt32 drop18 = dropBoss.drop18;
        PreloadDrop(drop18);
        UInt32 drop19 = dropBoss.drop19;
        PreloadDrop(drop19);
        UInt32 drop20 = dropBoss.drop20;
        PreloadDrop(drop20);
    }

    /// <summary>
    /// 掉落表
    /// </summary>
    private void PreloadDrop(UInt32 id)
    {
        if (id == 0) return;
        DropTemp data = DropTempManager.instance.Find(id);
        if (data == null) return;
        DropTemp.dropList list1 = data.dropLists1;
        GetDropList(list1);

        DropTemp.dropList list2 = data.dropLists2;
        GetDropList(list2);

        DropTemp.dropList list3 = data.dropLists3;
        GetDropList(list3);

        DropTemp.dropList list4 = data.dropLists4;
        GetDropList(list4);

        DropTemp.dropList list5 = data.dropLists5;
        GetDropList(list5);

        DropTemp.dropList list6 = data.dropLists6;
        GetDropList(list6);
    }

    private void GetDropList(DropTemp.dropList list)
    {
        if (list.list.Count > 0)
        {
            for (int i = 0; i < list.list.Count; i++)
            {
                GetEquipId(list.list[i].b);
            }
        }
    }

    /// <summary>
    /// 获取装备id(可能是道具id,可能是装备id对应表的掉落id）
    /// </summary>
    private void GetEquipId(uint id)
    {
        ItemData data = GetItemData(id);
        if (data != null)
        {
            string modelName = data.model;
            if (string.IsNullOrEmpty(modelName)) return;
            PreloadMgr.prefab.Add(modelName);
        }
        else //再从装备对应表里面找
        {
            EquipId equipId = EquipIdManager.instance.Find(id);
            if (equipId == null)
            {
                iTrace.eError("xiaoyu", "掉落表里的 id 从道具表找不到从装备对应表也找不到 id:  " + id);
                return;
            }
            UInt32 id0 = equipId.id0;
            PreloadItemData(id0);

            UInt32 id1 = equipId.id1;
            PreloadItemData(id1);


            UInt32 id2 = equipId.id2;
            PreloadItemData(id2);

            UInt32 id3 = equipId.id3;
            PreloadItemData(id3);

        }
    }

    private void PreloadItemData(UInt32 id)
    {
        ItemData data = GetItemData(id);
        if (data == null) return;
        string modelName = data.model;
        if (string.IsNullOrEmpty(modelName)) return;
        PreloadMgr.prefab.Add(modelName);
    }

    private ItemData GetItemData(UInt32 id)
    {
        ItemData data = null;
        if (id > 70000 && id < 90000)
        {
            ItemCreate create = ItemCreateManager.instance.Find(id);
            if (create != null)
            {
                int cate = User.instance.MapData.Category;
                if (cate == 1)
                    id = create.w1;
                else
                    id = create.w2;
            }
        }
        data = ItemDataManager.instance.Find((UInt32)id);
        return data;
    }


    /// <summary>
    /// 特殊掉落
    /// </summary>
    private void PreloadSpecialDrop(UInt32 id)
    {
        for (int i = 0; i < SpecialDropManager.instance.Size; i++)
        {
            SpecialDrop data = SpecialDropManager.instance.Get(i);
            if (data.groupId == id)
            {
                UInt32 dropid = data.dropid;
                PreloadDrop(dropid);
            }
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 场景中掉落物
    /// </summary>
    /// <param name="unitTypeId"></param>
    public void PreLoadDropModelByTypeId(uint unitTypeId)
    {
        PreloadFirstDrop(unitTypeId);
        PreloadDropBoss(unitTypeId);
    }
    #endregion
}
