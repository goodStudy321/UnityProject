using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:符号管理
    /// </summary>
    public static class SymbolMgr
    {
        #region 字段
        private static Transform root = null;
        private static UIPanel uiPanel = null;

        /// <summary>
        /// 符号列表
        /// </summary>
        private static List<SymbolBase> symbols = new List<SymbolBase>();

        private static TweenPath redTween = null;

        /// <summary>
        /// 红色符号 (玩家自己）
        /// </summary>
        public const string Red = "RedSymbol";

        private static TweenPath greenTween = null;

        /// <summary>
        /// 绿色符号 经验提升/血量恢复等
        /// </summary>
        public const string Green = "GreenSymbol";

        private static TweenPath shanBiTween = null;

        /// <summary>
        /// 绿色符号 闪避
        /// </summary>
        public const string ShanBiSymbol = "ShanBiSymbol";

        private static TweenPath orangeTween = null;

        /// <summary>
        /// 橘红色符号 非玩家被伤害
        /// </summary>
        public const string Orange = "OrangeSymbol";

        private static TweenPath orangeBaoJiTween = null;

        /// <summary>
        /// 灰色符号 （怪物）
        /// </summary>
        public const string Gray = "GraySymbol";

        private static TweenPath grayTween = null;

        /// <summary>
        /// 红色暴击（所有单位）
        /// </summary>
        public const string RedBaoJi = "RedBaoJi";

        private static TweenPath redBaojiTween = null;

        /// <summary>
        /// 橘红色符号 非玩家被暴击
        /// </summary>
        public const string OrangeBaoJi = "OrangeBaoJi";

        private static TweenPath yellowTween = null;

        /// <summary>
        /// 黄色符号 战力提升
        /// </summary>
        public const string Yellow = "YellowSymbol";

        /// <summary>
        /// 普通精灵符号预制件名称
        /// </summary>
        public const string Sprite = "SpriteSymbol";

        /// <summary>
        /// 暴击符号
        /// </summary>
        public const string BaoJiStr = "baoji";

        /// <summary>
        /// 闪避符号
        /// </summary>
        public const string ShanBiStr = "shanbi";

        /// <summary>
        /// 格挡符号
        /// </summary>
        public const string GeDangStr = "gedang";

        /// <summary>
        /// 吸收符号
        /// </summary>
        public const string AbsortStr = "xishou";

        /// <summary>
        /// 防御符号
        /// </summary>
        public const string FangYuStr = "fangyu";

        /// <summary>
        /// 经验符号
        /// </summary>
        public const string JingYanStr = "jingyan";

        /// <summary>
        /// 命中符号
        /// </summary>
        public const string MingZhongStr = "mingzhong";
        #endregion

        #region 属性
        /// <summary>
        /// 根结点
        /// </summary>
        public static Transform Root
        {
            get
            {
                if (root == null)
                {
                    SetRoot();
                }
                return root;
            }
        }

        #endregion

        #region 构造方法
        static SymbolMgr()
        {
            if (!Application.isPlaying) return;
            MonoEvent.lateupdate += Update;
        }
        #endregion

        #region 私有方法
        private static void SetRoot()
        {
            if (root != null) return;
            root = TransTool.CreateRoot("SymbolMgr");
            root.gameObject.layer = LayerTool.ThreeDUI;
            uiPanel = root.gameObject.AddComponent<UIPanel>();
            UIPanel.symbolPanel = uiPanel;
        }

        private static void Update()
        {
            if (symbols.Count == 0) return;
            int beg = symbols.Count - 1;
            for (int i = beg; i > -1; i--)
            {
                var cur = symbols[i];
                cur.Update();
                if (cur.IsOver)
                {
                    ListTool.Remove<SymbolBase>(symbols, i);
                    cur.Dispose();
                }
            }
        }

        private static TweenPath GetTween(Object o)
        {
            var text = o as TextAsset;
            var bytes = text.bytes;
            var tween = new TweenPath();
            tween.Read(bytes);
            return tween;
        }

        private static void SetRedTween(Object o)
        {
            redTween = GetTween(o);
        }

        private static void SetGreenTween(Object o)
        {
            greenTween = GetTween(o);
        }

        private static void SetShanBiTween(Object o)
        {
            shanBiTween = GetTween(o);
        }

        private static void SetOrangeTween(Object o)
        {
            orangeTween = GetTween(o);
        }

        private static void SetOrangeBaoJiTween(Object o)
        {
            orangeBaoJiTween = GetTween(o);
        }

        private static void SetGrayTween(Object o)
        {
            grayTween = GetTween(o);
        }

        private static void SetRedBaojiTween(Object o)
        {
            redBaojiTween = GetTween(o);
        }

        private static void SetYellowTween(Object o)
        {
            yellowTween = GetTween(o);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 添加符号
        /// </summary>
        /// <param name="symbol"></param>
        public static void Add(SymbolBase symbol)
        {
            if (symbol == null) return;
            if (symbols.Contains(symbol)) return;
            symbols.Add(symbol);
        }

        /// <summary>
        /// 移除符号
        /// </summary>
        /// <param name="symbol"></param>
        public static void Remove(SymbolBase symbol)
        {
            if (symbol == null) return;
            symbols.Remove(symbol);
        }

        /// <summary>
        /// 创建暴击符号
        /// </summary>
        /// <param name="owner"></param>
        /// <param name="value"></param>
        /// <param name="relative">true:旋转180</param>
        public static void BaoJi(Unit owner, long value, bool relative = false)
        {
            var msg = string.Format("{0}+{1}", value, BaoJiStr);
            var name = RedBaoJi;
            var buf = redBaojiTween;
            DigitSymbol.Launch(owner, msg, false, name, buf, relative);
        }

        /// <summary>
        /// 创建伤害符号
        /// </summary>
        /// <param name="owner">被伤害者</param>
        /// <param name="value">伤害值</param>
        /// <param name="relative">true:旋转180</param>
        public static void Damage(Unit owner, long value, bool isOwner, bool isRole, bool relative = false)
        {
            var name = isOwner ? Red : (isRole ? Orange : Gray);
            var buf = isOwner ? redTween : (isRole ? orangeTween : grayTween);
            DigitSymbol.Launch(owner, value.ToString(), false, name, buf, relative);
        }

        /// <summary>
        /// 创建恢复HP符号
        /// </summary>
        /// <param name="owner">恢复者</param>
        /// <param name="value">值</param>
        public static void RestoreHp(Unit owner, long value, bool relative = false)
        {
            var msg = string.Format("+{0}", value);
            DigitSymbol.Launch(owner, msg, false, Green, greenTween, relative);
        }

        /// <summary>
        /// 创建经验符号
        /// </summary>
        /// <param name="owner">恢复者</param>
        /// <param name="value">值</param>
        public static void JingYan(Unit owner, int value, bool relative = false)
        {
            string msg = string.Format("{0}+{1}", JingYanStr, value);
            DigitSymbol.Launch(owner, msg, false, Green, greenTween, relative);
        }

        /// <summary>
        /// 创建防御符号
        /// </summary>
        /// <param name="owner">恢复者</param>
        /// <param name="value">值</param>
        public static void FangYu(Unit owner, int value, bool relative = false)
        {
            string msg = string.Format("{0}+{1}", FangYuStr, value);
            DigitSymbol.Launch(owner, msg, false, Green, greenTween, relative);
        }

        /// <summary>
        /// 创建闪避符号
        /// </summary>
        public static void ShanBi(Unit owner, bool relative = false)
        {
            DigitSymbol.Launch(owner, ShanBiStr, false, ShanBiSymbol, shanBiTween, relative);
        }

        /// <summary>
        /// 创建格挡符号
        /// </summary>
        public static void GeDang(Unit owner, bool relative = false)
        {
            DigitSymbol.Launch(owner, GeDangStr, false, ShanBiSymbol, shanBiTween, relative);
        }

        /// <summary>
        /// 创建吸收符号
        /// </summary>
        /// <param name="owner"></param>
        /// <param name="relative"></param>
        public static void Absorb(Unit owner, bool relative = false)
        {
            DigitSymbol.Launch(owner, AbsortStr, false, Green, greenTween, relative);
        }

        /// <summary>
        /// 创建未命中符号
        /// </summary>
        public static void MingZhong(Unit owner, bool relative = false)
        {
            DigitSymbol.Launch(owner, MingZhongStr, false, Green, greenTween, relative);
        }

        public static void Init()
        {
            SetRoot();
        }

        /// <summary>
        /// 预加载
        /// </summary>
        public static void Preload()
        {
            PreloadMgr.prefab.Add(Red, true);
            PreloadMgr.prefab.Add(Orange, true);
            PreloadMgr.prefab.Add(Yellow, true);
            PreloadMgr.prefab.Add(Green, true);
            PreloadMgr.prefab.Add(OrangeBaoJi, true);
            PreloadMgr.prefab.Add(ShanBiSymbol, true);

            var sfx = Suffix.Bytes;
            if (redTween == null) AssetMgr.Instance.Add(Red, sfx, SetRedTween);
            if (greenTween == null) AssetMgr.Instance.Add(Green, sfx, SetGreenTween);
            if (shanBiTween == null) AssetMgr.Instance.Add(ShanBiSymbol, sfx, SetShanBiTween);
            if (orangeTween == null) AssetMgr.Instance.Add(Orange, sfx, SetOrangeTween);
            if (orangeBaoJiTween == null) AssetMgr.Instance.Add(OrangeBaoJi, sfx, SetOrangeBaoJiTween);
            if (redBaojiTween == null) AssetMgr.Instance.Add(RedBaoJi, sfx, SetRedBaojiTween);
            if (grayTween == null) AssetMgr.Instance.Add(Gray, sfx, SetGrayTween);
            if (yellowTween == null) AssetMgr.Instance.Add(Yellow, sfx, SetYellowTween);
        }

        public static void Dispose()
        {

        }

        #endregion
    }
}