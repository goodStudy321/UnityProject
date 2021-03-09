using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.10.13
    /// BG:单位名称条
    /// </summary>
    public class UnitNameBar : NameBarBase
    {
        #region 字段
        private Unit unit = null;
        #endregion

        #region 属性

        /// <summary>
        /// 拥有者
        /// </summary>
        public Unit Owner
        {
            get { return unit; }
            set { unit = value; }
        }
        #endregion

        #region 构造方法
        public UnitNameBar()
        {

        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 设置位置
        /// </summary>
        private void SetPosition()
        {
            pos = unit.Position;
            if (unit.Collider == null)
            {
                pos.y += 1;
            }
            else
            {
                pos.y += unit.Collider.bounds.size.y + 1;
            }
            transform.position = pos;
        }

        /// <summary>
        /// 设置欧拉角
        /// </summary>
        private void SetEulerAngle()
        {
            transform.eulerAngles = CameraMgr.Main.transform.eulerAngles;
        }

        #endregion

        #region 保护方法
        protected override bool Check()
        {
            if (transform == null) return false;
            if (unit == null) return false;
            if (unit.UnitTrans == null) return false;
            return true;
        }
        protected override void SetProperty()
        {
            nameLbl = ComTool.Get<UILabel>(transform, "name", "单位名称条");
        }
        protected override void UpdateCustom()
        {
            SetPosition();
            SetEulerAngle();
        }
        #endregion

        #region 公开方法

        public override void Dispose()
        {
            base.Dispose();
            unit = null;
        }

        /// <summary>
        /// 创建单位名称条
        /// </summary>
        /// <param name="unit">单位</param>
        /// <param name="name">名称</param>
        /// <returns></returns>
        public static UnitNameBar Create(Unit unit, string name)
        {
            if (unit == null) return null;
            if (unit.UnitTrans == null) return null;
            UnitNameBar bar = ObjPool.Instance.Get<UnitNameBar>();
            bar.Owner = unit;
            bar.Name = name;
            bar.Initialize();
            return bar;
        }
        #endregion
    }
}