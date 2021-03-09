using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.10.13
    /// BG:普通名称条
    /// </summary>
    public class CommenNameBar : NameBarBase
    {
        #region 字段
        private float orgHeight = 0;
        private float height = 0;

        private Transform target = null;

        protected GameObject confineRoot = null;
        protected GameObject confineEff = null;

        protected GameObject rebirthRoot = null;

        protected UILabel serverLbl = null;
        protected UILabel falmilyLbl = null;
        protected UILabel marryLbl = null;

        /// <summary>
        /// 血条字体颜色参数
        /// </summary>
        private int colorParam = 0;


        private int level = 0;
        private int confineLv = 0;
        private int rebirthLv = 0;
        private string server = "";
        private string falmily = "";
        private string marry = "";

        #endregion

        #region 属性


        /// <summary>
        /// 名称条显示的目标物体
        /// </summary>
        public Transform Target
        {
            get { return target; }
            set { target = value; }
        }
        /// <summary>
        /// 服务器 在下
        /// </summary>
        public string Server
        {
            get { return server; }
            set
            {
                server = value;
                SetText(serverLbl, server);
            }
        }
        /// <summary>
        /// 帮派 在下
        /// </summary>
        public string Flamily
        {
            get { return falmily; }
            set
            {
                falmily = value;
                SetText(falmilyLbl, falmily);
            }
        }

        /// <summary>
        /// 对象 在下
        /// </summary>
        public string Marry
        {
            get { return marry; }
            set
            {
                marry = value;
                SetText(marryLbl, marry);
            }
        }
        #endregion

        #region 构造方法
        public CommenNameBar()
        {

        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 设置位置
        /// </summary>
        private void SetPosition()
        {
            pos = target.position;
            pos.y += height;
            transform.position = pos;
        }

        /// <summary>
        /// 设置欧拉角
        /// </summary>
        private void SetEulerAngle()
        {
            transform.eulerAngles = CameraMgr.Main.transform.eulerAngles;
        }

        /// <summary>
        /// 设置颜色
        /// </summary>
        /// <param name="camp"></param>
        private void SetFgColor()
        {
            if (nameLbl == null) return;
            if (colorParam == 1)
                nameLbl.color = Color.green;
            else if (colorParam == 2)
                nameLbl.color = Color.white;
        }

        /// <summary>
        /// 设置主角资源持久化
        /// </summary>
        /// <param name="go"></param>
        private void Setpersist(GameObject go)
        {
            if (go == null)
                return;
            Unit owner = InputMgr.instance.mOwner;
            if (owner == null)
                return;
            if (Target != owner.UnitTrans)
                return;
            UnityEngine.Object.DontDestroyOnLoad(go);
            AssetMgr.Instance.SetPersist(go.name);
        }

        private void LoadConfineCb(GameObject go)
        {
            if (TransTool.IsNull(confineRoot))
            {
                GameObject.Destroy(go);
                SetRootPos();
                return;
            }
            go.transform.parent = confineRoot.transform;
            go.transform.localScale = Vector3.one;
            go.transform.localEulerAngles = Vector3.zero;
            go.transform.localPosition = Vector3.left * 0.3f;
            confineEff = go;
            go.SetActive(true);
            UIEffectBinding eff = go.AddComponent<UIEffectBinding>();
            if (eff != null)
            {
                eff.mNameLayer = LayerMask.LayerToName(LayerTool.ThreeDUI);
                eff.noClip = true;
            }
            LayerTool.Set(go.transform, LayerTool.ThreeDUI);
            go.SetActive(true);
            SetRootPos();
            AssetMgr.Instance.SetPersist(go.name, Suffix.Prefab);
        }

        private void SetConfinePos(Vector3 pos, float w, float offset)
        {
            if (confineRoot == null) return;
            pos.x -= w / 2;
            pos.x += offset;
            pos.y = confineRoot.transform.localPosition.y;
            confineRoot.transform.localPosition = pos;
        }

        private void SetRebirthPos(Vector3 pos, float w, float offset)
        {
            if (rebirthRoot == null) return;
            pos.x += w / 2;
            pos.x += offset;
            pos.y = rebirthRoot.transform.localPosition.y;
            rebirthRoot.transform.localPosition = pos;
        }

        private float SetLabelPos(UILabel lab, Vector3 pos, float h)
        {
            if (lab == null) return h;
            h = lab.height * 0.006f + h;
            lab.transform.localPosition = pos + Vector3.up * h;
            return h;
        }
        #endregion

        #region 保护方法
        protected override bool Check()
        {
            if (target == null) return false;
            if (transform == null) return false;
            return true;
        }
        protected override void UpdateCustom()
        {
            SetPosition();
            SetEulerAngle();
        }

        protected override void SetProperty()
        {
            nameLbl = ComTool.Get<UILabel>(transform, "name", "名称条");
            titleLbl = ComTool.Get<UILabel>(transform, "title", "名称条");
            string name = transform.name;
            if (name == TopBarFty.LocalPlayerBarStr || transform.name == TopBarFty.OtherPlayerBarStr)
            {
                confineRoot = TransTool.Find(transform, "confine", "名称条/境界节点");
                rebirthRoot = TransTool.Find(transform, "rebirth", "名称条/转生的");
                serverLbl = ComTool.Get<UILabel>(transform, "server", "名称条/服务器");
                falmilyLbl = ComTool.Get<UILabel>(transform, "falmily", "名称条/帮派");
                marryLbl = ComTool.Get<UILabel>(transform, "marry", "名称条/对象");
            }
            if (transform.name == TopBarFty.OtherPlayerBarStr)
                timeLbl = ComTool.Get<UILabel>(transform, "time", "名称条");
        }

        protected override void LoadCallback(GameObject go)
        {
            Setpersist(go);
            base.LoadCallback(go);
            SetText(serverLbl, server);
            SetText(falmilyLbl, falmily);
            SetText(marryLbl, marry);
            SetHeight();
            SetFgColor();
            UpdateConfine(confineLv);
            UpdateRebirthStatus(level, rebirthLv);
        }

        protected override void SetRootPos()
        {
            if (nameLbl == null) return;
            Vector3 pos = Vector3.up * -0.184f;
            float w = nameLbl.CalculatePrintedSize(nameLbl.text).x * nameLbl.transform.localScale.x;
            float offset = 0;
            if (confineEff != null) offset += 0.29f;
            if (rebirthRoot && rebirthRoot.activeSelf == true) offset -= 0.1f;
            SetConfinePos(pos, w, offset);
            SetRebirthPos(pos, w, offset);
            float h = 0;
            if (!string.IsNullOrEmpty(Title)) h = SetLabelPos(titleLbl, pos, h);
            if (!string.IsNullOrEmpty(server)) h = SetLabelPos(serverLbl, pos, h);
            if (!string.IsNullOrEmpty(falmily)) h = SetLabelPos(falmilyLbl, pos, h);
            if (!string.IsNullOrEmpty(marry)) h = SetLabelPos(marryLbl, pos, h);
            SetTitlePos(pos, h);
            pos.x += offset;
            nameLbl.transform.localPosition = pos;
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 设置高度（是否折半高度）
        /// </summary>
        /// <param name="isHalve"></param>
        public void SetHeight(bool isHalve)
        {
            if (isHalve)
            {
                height = orgHeight * 0.6f;
            }
            else
                height = orgHeight;
        }
        /// <summary>
        /// 设置高度
        /// </summary>
        /// <param name="value">高度值</param>
        public void SetHeight(float value)
        {
            height = value;
            orgHeight = height;
            Update();
        }

        /// <summary>
        /// 设置高度/自动获取游戏对象的高度
        /// </summary>
        public void SetHeight()
        {
            height = BoundTool.MaxHeight(Target);
            orgHeight = height;
            Update();
        }

        /// <summary>
        /// 重置名字颜色
        /// </summary>
        public void ResetNameColor()
        {
            SetNameColor(Color.white);
        }

        /// <summary>
        /// 设置颜色
        /// </summary>
        /// <param name="label"></param>
        /// <param name="color"></param>
        public void SetNameColor(Color color)
        {
            if (nameLbl == null)
                return;
            nameLbl.color = color;
        }

        public void ClearLabels()
        {
            SetText(serverLbl, server);
            SetText(falmilyLbl, falmily);
            SetText(marryLbl, marry);
        }

        public override void Dispose()
        {
            if (confineRoot != null) confineRoot.SetActive(false);
            confineRoot = null;
            if (confineEff != null)
                GameObject.Destroy(confineEff);
            if (rebirthRoot != null) rebirthRoot.SetActive(false);
            rebirthRoot = null;
            server = "";
            falmily = "";
            marry = "";
            confineLv = 0;
            level = 0;
            confineLv = 0;
            rebirthLv = 0;
            ResetNameColor();
            ClearLabels();
            base.Dispose();
            target = null;
            marryLbl = null;
            falmilyLbl = null;
        }

        /// <summary>
        /// 创建普通名称条
        /// </summary>
        /// <param name="target">目标物体</param>
        /// <param name="title">称号</param>
        /// <param name="name">名称</param>
        /// <param name="name">头顶预制名称</param>
        public static CommenNameBar Create(Transform target, string title, string name, string barName, int colorParam = 0, int titleId = 0, ActorData actor = null)
        {
            if (target == null) return null;
            if (string.IsNullOrEmpty(barName)) return null;
            CommenNameBar bar = ObjPool.Instance.Get<CommenNameBar>();
            bar.Target = target;
            bar.Name = name;
            bar.Title = title;
            bar.BarName = barName;
            bar.colorParam = colorParam;
            bar.TitleId = titleId;
            if (actor != null)
            {
                bar.Server = string.IsNullOrEmpty(actor.ServerName) ? string.Empty : string.Format("[{0}]", actor.ServerName);
                bar.UpdateFlamily(TitleHelper.instance.GetTitleStr(actor));
                bar.UpdateMarry(TitleHelper.instance.GetMarryStr(actor.MarryName));
                bar.UpdateConfine(actor.Confine);
                bar.UpdateRebirthStatus(actor.Level, actor.ReliveLV);
            }
            bar.Initialize();
            return bar;
        }


        public void UpdateFlamily(string name)
        {
            Flamily = name;
        }

        public void UpdateMarry(string name)
        {
            Marry = name;
        }

        public void UpdateConfine(int confine)
        {
            confineLv = confine;
            if (confineRoot == null) return;
            confineRoot.gameObject.SetActive(confineLv > 0);
            if (confineLv == 0) return;
            Confine cf = ConfineManager.instance.Find((uint)confineLv);
            if (cf == null) return;
            string path = QualityMgr.instance.GetQuaEffName(cf.path);
            if (string.IsNullOrEmpty(path)) return;
            if (confineEff != null)
                GameObject.Destroy(confineEff);
            string name = string.Format("{0}.prefab", path);
            if (!AssetMgr.Instance.Exist(name))
                return;
            AssetMgr.LoadPrefab(path, LoadConfineCb);
        }

        /// <summary>
        /// 设置转生
        /// </summary>
        public void UpdateRebirthStatus(int lv, int reliveLv)
        {
            level = lv;
            rebirthLv = reliveLv;
            if (rebirthRoot == null) return;
            GlobalData lvData = GlobalDataManager.instance.Find(90);
            GlobalData rebirthData = GlobalDataManager.instance.Find(91);
            bool IsLv = false;
            bool IsRL = false;
            if (lvData != null)
            {
                IsLv = lv > Convert.ToInt32(lvData.num3);
            }
            if (rebirthData != null)
            {
                IsRL = reliveLv >= Convert.ToInt32(rebirthData.num3);
            }
            rebirthRoot.gameObject.SetActive(IsRL && IsLv);

            SetRootPos();
        }
        #endregion
    }
}