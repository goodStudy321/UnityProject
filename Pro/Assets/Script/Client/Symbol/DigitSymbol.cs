using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:数字符号
    /// </summary>
    public class DigitSymbol : SymbolBase
    {
        #region 字段
        private TweenPath buf;

        private string mValue = "";

        private Unit unit = null;

        private bool italic = false;


        #endregion

        #region 属性

        /// <summary>
        /// 值
        /// </summary>
        public string Value
        {
            get { return mValue; }
            set { mValue = value; }
        }

        /// <summary>
        /// 单位
        /// </summary>
        public Unit Unit
        {
            get { return unit; }
            set { unit = value; }
        }

        /// <summary>
        /// true:斜体
        /// </summary>
        public bool Italic
        {
            get { return italic; }
            set { italic = value; }
        }

        #endregion

        #region 构造方法
        public DigitSymbol()
        {

        }

        public DigitSymbol(Unit unit, string value, bool italic, string name) : base(name)
        {
            this.unit = unit;
            this.mValue = value;
            this.italic = italic;
        }

        #endregion

        #region 私有方法
        private void LoadCallback(GameObject go)
        {
            trans = go.transform;
            trans.parent = SymbolMgr.Root;
            trans.localScale = Vector3.one;
            go.SetActive(true);
            SetValue();
            SymbolTool.PlayTween(go);
            float y = unit.Collider.bounds.size.y;
            y = y > 2.8f ? 2.8f : y;
            Vector3 beg = unit.UnitTrans.position + new Vector3(0, y, 0);
            trans.position = beg;
            var tween = ObjPool.Instance.Get<TweenSymbolPath>();
            tween.StartUp(trans, SetOver, Relative, buf);
        }

        private void SetValue()
        {
            UILabel msg = ComTool.Get<UILabel>(trans, "msg", "符号");
            if (msg == null) return;
            string text = Value;
            if (italic) text = string.Format("[i]{0}[/i]", text);
            msg.text = text;
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

        public override void Dispose()
        {
            base.Dispose();
            Unit = null;
            Value = null;
        }

        /// <summary>
        /// 发射符号
        /// </summary>
        /// <param name="unit">单位</param>
        /// <param name="value">值</param>
        /// <param name="italic">是否斜体</param>
        /// <param name="name">符号预制件名称</param>
        /// <param name="buf">路径配置</param>
        /// <param name="relative">true:旋转180</param>
        public static void Launch(Unit unit, string value, bool italic, string name, TweenPath buf, bool relative = false)
        {
            if (unit == null) return;
            if (unit.DestroyState) return;
            if (unit.UnitTrans == null) return;
            if (string.IsNullOrEmpty(name)) return;
            var symbol = ObjPool.Instance.Get<DigitSymbol>();
            symbol.buf = buf;
            symbol.Name = name;
            symbol.Unit = unit;
            symbol.Value = value;
            symbol.Italic = italic;
            symbol.Relative = relative;
            symbol.Launch();
        }
        #endregion
    }
}