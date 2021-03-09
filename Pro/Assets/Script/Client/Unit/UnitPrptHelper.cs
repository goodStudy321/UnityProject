public class UnitPrptHelper
{
    public static readonly UnitPrptHelper instance = new UnitPrptHelper();

    private UnitPrptHelper() { }

    #region 公有方法
    /// <summary>
    /// 属性改变
    /// </summary>
    /// <param name="actData"></param>
    /// <param name="unit"></param>
    /// <param name="pType"></param>
    /// <param name="value"></param>
    public void PrptChange(ActorData actData, Unit unit, PropertyType pType, long value)
    {
        if (pType == PropertyType.ATTR_MOVE_SPEED)
        {
            unit.MoveSpeed = (float)value * 0.01f;
            unit.mNetUnitMove.SetMoveSpeed(unit, MoveType.Normal);
        }
        else if (pType == PropertyType.ATTR_WEAPON_CHANGE)
        {
            PendantStateEnum state = (PendantStateEnum)value;
            PendantMgr.instance.ChangePendantsAction(unit, state);
        }
        else if (pType == PropertyType.ATTR_STATUS)
        {
            UnitStateOnline state = (UnitStateOnline)value;
            if (state == UnitStateOnline.Dead)
            {
                UnitEventMgr.ExecuteDie(unit);
                UnitMgr.instance.SetUnitDead(unit);
            }
            else if (state == UnitStateOnline.Normal)
            {
                //可能上个状态是战斗状态
                if (unit.mStateOnLine == UnitStateOnline.Dead)
                    UnitMgr.instance.SetUnitRevive(unit);
            }
            else if (state == UnitStateOnline.NoFighting)
            {
                if (unit.TopBar != null)
                {
                    if (unit.Camp != (CampType)User.instance.MapData.Camp)
                    {
                        unit.TopBar.Dispose();
                        unit.TopBar = null;
                        LockTarMgr.instance.DisTopBar(unit);
                    }
                }
            }
            unit.mStateOnLine = state;
        }
        else if (pType == PropertyType.ATTR_BUFF_UPDATE)
        {
            if (unit.UnitUID == User.instance.MapData.UID)
                return;
            unit.mBuffManager.AddBuff((uint)value, 0, 0, 0);
        }
        else if (pType == PropertyType.ATTR_BUFF_DEL)
        {
            if (unit.UnitUID == User.instance.MapData.UID)
                return;
            unit.mBuffManager.DelBuf((uint)value);
        }
        else if (pType == PropertyType.ATTR_PK_MODE)
        {
            int fightType = (int)value;
            actData.FightType = fightType;
            unit.FightType = fightType;
        }
        else if (pType == PropertyType.ATTR_PK_VALUE)
        {
            actData.PkValue = value;
            unit.PkValue = value;
            unit.mUnitRedNameInfo.SetRedName(actData);
        }
        else if (pType == PropertyType.ATTR_CAMP_ID)
        {
            actData.Camp = (int)value;
            unit.Camp = (CampType)value;
        }
        else if (pType == PropertyType.ATTR_FAMILY_ID_CHANGE)
        {
            long fmlId = actData.FamilyID;
            actData.FamilyID = value;
            unit.FamilyId = value;
            if(value != fmlId)
            {
                EventMgr.Trigger(EventKey.ChgTmOrFml, actData.UID, actData.TeamID, value);
            }
        }
        else if (pType == PropertyType.ATTR_POSITION_CHANGE)
        {
            actData.FamilyTitle = (int)value;
            TitleHelper.instance.ChgFmlTitle(unit, actData);
        }
        else if (pType == PropertyType.ATTR_TEAM_ID)
        {
            int teamId = (int)value;
            int tmId = actData.TeamID;
            unit.TeamId = teamId;
            actData.TeamID = teamId;
            if(teamId != tmId)
            {
                EventMgr.Trigger(EventKey.ChgTmOrFml, actData.UID, teamId, actData.FamilyID);
            }
        }
        else if (pType == PropertyType.ATTR_POWER_CHANGE)
        {
            unit.FightVal = value;
            actData.AllFightValue = (int)value;
        }
        else if (pType == PropertyType.ATTR_CONFINE_CHANGE)
        {
            actData.Confine = (int)value;
            TitleHelper.instance.ChgConfine(unit, actData.Confine);
            PendantMgr.instance.PutOn(unit, (uint)value, actData.PdState, actData);

        }
        else if (pType == PropertyType.ATTR_BATTLE_OWNER)
        {
            CamBatMgr.instance.SetPileInfo(unit, value);
        }
        else if (pType == PropertyType.ATTR_TITLE_CHANGE)
        {
            actData.Title = (int)value;
        }
        else if (pType == PropertyType.ATTR_COUNTDOWN)
        {
            if (value == 0)
                unit.mUnitTimer.Stop();
            else
                unit.mUnitTimer.Start(unit, value);
        }
        else if (pType == PropertyType.ATTR_LEVEL_CHANGE)
        {
            actData.Level = (int)value;
            TitleHelper.instance.ChgRebirth(unit, actData);
        }
        else if (pType == PropertyType.ATTR_LEVEL_REBIRTH)
        {
            actData.ReliveLV = (int)value;
            TitleHelper.instance.ChgRebirth(unit, actData);
        }
        else if(pType == PropertyType.ATTR_MarryID_CHANGE)
        {
            actData.MarryID = (int)value;
        }
        
    }
    
    /// <summary>
    /// 字符属性改变
    /// </summary>
    /// <param name="actData"></param>
    /// <param name="unit"></param>
    /// <param name="pType"></param>
    /// <param name="value"></param>
    public void PrptChgStr(ActorData actData, Unit unit, PropertyType pType, string value)
    {
        if (pType == PropertyType.ATTR_FAMILY_NAME_CHANGE)
        {
            actData.FamlilyName = value;
            TitleHelper.instance.ChgFmlTitle(unit, actData);
        }
        else if (pType == PropertyType.ATTR_Marry_CHANGE)
        {
            actData.MarryName = value;
            TitleHelper.instance.ChgMarry(unit, actData.MarryName);
        }
    }
    #endregion
}
