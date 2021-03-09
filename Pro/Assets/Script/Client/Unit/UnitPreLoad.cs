using ProtoBuf;
using Loong.Game;
using System.Collections.Generic;

public class UnitPreLoad
{
    public static readonly UnitPreLoad instance = new UnitPreLoad();

    private UnitPreLoad() { }
    #region 私有方法
    /// <summary>
    /// 从动作编辑器获取单位资源
    /// </summary>
    /// <param name="unitModelId"></param>
    /// <returns></returns>
    private void SetUnitAssetsFromActionEditor(ushort unitModelId, bool persist = false)
    {
        if (Global.ActionSetupData == null)
            return;
        for (int i = 0; ; i++)
        {
            ActionGroupData actionGroupData = ActionHelper.GetGroupData(unitModelId, i);
            if (actionGroupData == null)
                break;
            foreach (ActionData act in actionGroupData.ActionDataList)
            {
                for (int k = 0; k < act.AttackDefList.Count; k++)
                {
                    AttackDefData atDD = act.AttackDefList[k];
                    if (!string.IsNullOrEmpty(atDD.SelfEffect))
                        PreloadMgr.prefab.Add(atDD.SelfEffect, persist);
                    if (!string.IsNullOrEmpty(atDD.SelfSound))
                        PreloadMgr.audio.Add(atDD.SelfSound, persist);
                    if (!string.IsNullOrEmpty(atDD.HitedEffect))
                        PreloadMgr.prefab.Add(atDD.HitedEffect, persist);
                    if (!string.IsNullOrEmpty(atDD.HitedSound))
                        PreloadMgr.audio.Add(atDD.HitedSound, persist);
                }
                for (int index = 0; index < act.EventList.Count; index++)
                {
                    EventData ed = act.EventList[index].EventDetailData;
                    if (!string.IsNullOrEmpty(ed.EffectName))
                    {
                        string[] strs = ed.EffectName.Split(',');
                        PreloadMgr.prefab.Add(strs[0], persist);
                    }
                    if (!string.IsNullOrEmpty(ed.SoundName))
                        PreloadMgr.audio.Add(ed.SoundName, persist);
                    if (ed.UnitID != 0)
                        PreLoadUnitAssetsByTypeId((uint)ed.UnitID, persist);
                }
            }
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 根据单位模型Id预加载
    /// </summary>
    /// <param name="unitModelId"></param>
    /// <returns></returns>
    public void PreLoadUnitAssetsByModelId(ushort unitModelId, bool persist = false)
    {
        string modelName = UnitHelper.instance.GetUnitModelName(unitModelId);
        if (!string.IsNullOrEmpty(modelName))
            PreloadMgr.prefab.Add(modelName, persist);
        SetUnitAssetsFromActionEditor(unitModelId, persist);
    }

    /// <summary>
    /// 根据单位类型Id预加载
    /// </summary>
    /// <param name="unitTypeId"></param>
    public void PreLoadUnitAssetsByTypeId(uint unitTypeId, bool persist = false)
    {
        ushort modelId = UnitHelper.instance.GetUnitModeId(unitTypeId);
        PreLoadUnitAssetsByModelId(modelId, persist);
    }

    /// <summary>
    /// 预加载场景怪物
    /// </summary>
    /// <param name="sceneInfo"></param>
    public void PreloadSceneMonster(SceneInfo sceneInfo)
    {
        if (sceneInfo == null)
            return;
        int count = sceneInfo.updateList.list.Count;
        for (int i = 0; i < count; i++)
        {
            uint id = sceneInfo.updateList.list[i];
            WildMap wildMap = WildMapManager.instance.Find(id);
            if (wildMap == null)
                continue;
            PreLoadUnitAssetsByTypeId(wildMap.monsterId);
            DropPreLoad.instance.PreLoadDropModelByTypeId(wildMap.monsterId);
        }
    }

    /// <summary>
    /// 预加载场景所有单位
    /// </summary>
    /// <param name="sceneInfo"></param>
    public void PreloadAllUnits(SceneInfo sceneInfo)
    {
        PreloadMainPlayer();
        PreloadSceneMonster(sceneInfo);
        NPCMgr.instance.PreloadNPC(sceneInfo.npcList.list);
    }

    public void PreloadUnits(List<uint> typeIDs)
    {
        if (typeIDs == null) return;
        var length = typeIDs.Count;
        for (int i = 0; i < length; i++)
        {
            var id = typeIDs[i];
            PreLoadUnitAssetsByTypeId(id);
        }
    }

    /// <summary>
    /// 预加载主角
    /// </summary>
    public void PreloadMainPlayer()
    {
        uint unitTypeId = User.instance.MapData.UnitTypeId;
        PreLoadUnitAssetsByTypeId(unitTypeId, true);
    }

    /// <summary>
    /// 预加载主角模型
    /// </summary>
    public void PreloadMPMod()
    {
        uint unitTypeId = User.instance.MapData.UnitTypeId;
        ushort modelId = UnitHelper.instance.GetUnitModeId(unitTypeId);
        string modelName = UnitHelper.instance.GetUnitModelName(modelId);
        if (!string.IsNullOrEmpty(modelName))
            PreloadMgr.prefab.Add(modelName);
    }
    #endregion
}
