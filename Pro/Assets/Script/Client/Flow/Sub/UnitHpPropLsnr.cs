using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        9733694e-44b7-4bf3-a83f-a50bdc410c07
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/4 12:15:44
    /// BG:血量监听
    /// </summary>
    public class UnitHpPropLsnr : UnitPropLsnr
    {
        #region 字段
        private float percent = 0;
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public UnitHpPropLsnr(UnitPropertyInfo info)
            : base(info)
        {

        }
        #endregion

        #region 私有方法
        private void Handler(Unit u, long value)
        {
            if (!ExecuteCheckEvent()) return;
            if (Info.UID < 1) if (InputMgr.instance.mOwner != null) Info.UID = InputMgr.instance.mOwner.UnitUID;
            if (u.UnitUID != Info.UID) return;
            float max = u.MaxHP;
            percent = u.HP / max;
            percent *= 100;
            if (Info.compareType == CompareType.Leq)
            {
                if (percent <= Info.percent) IsOver = true;
            }
            else if (Info.compareType == CompareType.Geq)
            {
                if (percent >= Info.percent) IsOver = true;
            }

        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Add()
        {
            UnitEventMgr.hpChange += Handler;
        }
        public override void Dispose()
        {
            base.Dispose();
            UnitEventMgr.hpChange -= Handler;
            IsOver = false;
        }
        #endregion
    }
}