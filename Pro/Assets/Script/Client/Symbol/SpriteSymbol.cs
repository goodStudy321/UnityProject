using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:精灵符号
    /// </summary>
    public class SpriteSymbol : SymbolBase
    {
        #region 字段
        private Unit unit = null;

        private string spriteName = null;
        #endregion

        #region 属性
        /// <summary>
        /// 单位
        /// </summary>
        public Unit Unit
        {
            get { return unit; }
            set { unit = value; }
        }

        /// <summary>
        /// 精灵名称
        /// </summary>
        public string SpriteName
        {
            get { return spriteName; }
            set { spriteName = value; }
        }
        #endregion

        #region 构造方法
        public SpriteSymbol()
        {

        }
        public SpriteSymbol(Unit unit, string spriteName, string name) : base(name)
        {
            this.unit = unit;
            this.spriteName = spriteName;
        }
        #endregion

        #region 私有方法
        private void LoadCallback(GameObject go)
        {
            trans = go.transform;
            trans.parent = SymbolMgr.Root;
            trans.localScale = Vector3.one;
            go.SetActive(true);
            SymbolTool.PlayTween(go);
            UITool.SetSpriteName(trans, "Sprite", "符号", spriteName);
            float y = unit.Collider.bounds.size.y;
            Vector3 beg = unit.Position + new Vector3(0, y, 0);
            trans.position = beg;
            var timer = ObjPool.Instance.Get<Timer>();
            timer.complete += SetOver;
            timer.AutoPool = true;
            timer.Seconds = 1;
            timer.Start();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Launch()
        {
            if (string.IsNullOrEmpty(Name))
            {
                Dispose();
            }
            else if (unit == null || unit.DestroyState)
            {
                Dispose();
            }
            else
            {
                IsOver = false;
                SymbolMgr.Add(this);
                AssetMgr.LoadPrefab(Name, LoadCallback);
            }
        }

        public override void Update()
        {
            if (trans == null) return;
            trans.eulerAngles = CameraMgr.Main.transform.eulerAngles;
        }

        /// <summary>
        /// 发射
        /// </summary>
        /// <param name="unit">单位</param>
        /// <param name="spriteName">精灵名称</param>
        /// <param name="name">符号预制件名称</param>
        /// <param name="relative">true:旋转180</param>
        public static void Launch(Unit unit, string spriteName, string name, bool relative = false)
        {
            if (unit == null) return;
            if (unit.DestroyState) return;
            if (unit.UnitTrans == null) return;
            if (string.IsNullOrEmpty(name)) return;
            if (string.IsNullOrEmpty(spriteName)) return;
            var symbol = ObjPool.Instance.Get<SpriteSymbol>();
            symbol.Unit = unit;
            symbol.Name = name;
            symbol.Relative = relative;
            symbol.SpriteName = spriteName;
            symbol.Launch();
        }
        #endregion
    }
}