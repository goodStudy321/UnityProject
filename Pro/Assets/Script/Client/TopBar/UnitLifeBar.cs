using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.10.13
    /// BG:单位血条
    /// </summary>
    public class UnitLifeBar : NameBarBase
    {
        #region 字段
        private Unit unit = null;
        /*/// <summary>
        /// 背景精灵
        /// </summary>
        private UISprite bg = null;
        /// <summary>
        /// 前景精灵
        /// </summary>
        private UISprite fg = null;*/
        /// <summary>
        /// 滑动条
        /// </summary>
        private UISlider slider = null;
        
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
        public UnitLifeBar()
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
                pos.y += unit.Collider.bounds.size.y + 0.2f;
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
        private void SetSliderValue()
        {
            if (unit.MaxHP == 0) return;
            float radio = unit.HP / ((unit.MaxHP) * 1f);
            if (radio < 0)
                radio = 0;
            slider.value = Mathf.Lerp(slider.value, radio, Time.deltaTime * 5);
        }
        /// <summary>
        /// 检查关闭血条
        /// </summary>
        private void CheckClose()
        {
            if (slider.value > 0.001f)
                return;
            this.Close();
        }
        
        #endregion

        #region 保护方法


        protected override void LoadCallback(GameObject go)
        {
            base.LoadCallback(go);
            string msg = "单位血条";
            /*bg = ComponentTool.Get<UISprite>(transform, "bg", msg);
            fg = ComponentTool.Get<UISprite>(transform, "bg/fg", msg);*/
            slider = ComTool.Get<UISlider>(transform, "bg", msg);
            float curHp = unit.HP / ((unit.MaxHP) * 1f);
            if (unit.HP <= 0)
                slider.value = 1;
            else
                slider.value = curHp;
            Update();
        }

        protected override void SetProperty()
        {
            nameLbl = ComTool.Get<UILabel>(transform, "bg/name", "单位血条");
        }

        protected override bool Check()
        {
            if (transform == null) return false;
            if (unit == null) return false;
            if (unit.UnitTrans == null) return false;
            if (slider == null) return false;
            return true;
        }

        protected override void UpdateCustom()
        {
            SetPosition();
            SetEulerAngle();
            SetSliderValue();
            CheckClose();
        }
        #endregion

        #region 公开方法

        public override void Dispose()
        {
            base.Dispose();
            unit = null;
            slider = null;
            /*fg = null;
            bg = null;*/
        }

        /// <summary>
        /// 创建普通头顶血条
        /// </summary>
        /// <param name="unit">单位</param>
        /// <param name="name">名称</param>
        /// <param name="name">头顶预制名称</param>
        public static TopBarBase Create(Unit unit, string name, string barName)
        {
            if (unit == null) return null;
            if (string.IsNullOrEmpty(barName)) return null;
            if (unit.UnitTrans == null) return null;
            if (unit.TopBar != null && (unit.TopBar is UnitLifeBar)) return null;
            if (unit.TopBar != null) unit.TopBar.Dispose();
            UnitLifeBar bar = ObjPool.Instance.Get<UnitLifeBar>();
            bar.Owner = unit;
            bar.Name = name;
            bar.BarName = barName;
            bar.Initialize();
            unit.TopBar = bar;
            return bar;
        }
        #endregion
    }
}