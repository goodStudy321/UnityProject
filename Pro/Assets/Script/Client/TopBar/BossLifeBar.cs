using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.6.13
    /// BG:Boss血条
    /// </summary>
    public class BossLifeBar : NameBarBase
    {
        #region 字段

        private Unit owner = null;

        /// <summary>
        /// 当前HP
        /// </summary>
        private long curHp = 0;

        /// <summary>
        /// 失去的血量
        /// </summary>
        private long difHp = 0;

        /// <summary>
        /// 段数
        /// </summary>
        public int segments = 5;
   
        /// <summary>
        /// 当前Boss血条信息的索引
        /// </summary>
        private int curIdx = 0;

        /// <summary>
        /// 上一Boss血条信息的索引
        /// </summary>
        private int lastIdx = 0;

        /// <summary>
        /// 下一Boss血条信息的索引
        /// </summary>
        private int nextIdx = 1;

        /// <summary>
        /// 当前段数
        /// </summary>
        private int curSeg = 0;

        /// <summary>
        /// 上次段数
        /// </summary>
        private int lastSeg = 0;


        /// <summary>
        /// 每一段血量 等于总血量除以段数
        /// </summary>
        private float segHp = 100f;

        /// <summary>
        /// 血条信息长度 前4个循环 最后一管血时播放红色,即血条段数不能小于5
        /// </summary>
        private int length = 5;

        private int threshold = 4;

        /// <summary>
        /// 标题标签
        /// </summary>
        private UILabel title = null;

        /// <summary>
        /// 掉落归属人
        /// </summary>
        private UILabel dropPeople = null;
        /// <summary>
        /// boss怒气
        /// </summary>
        private UILabel AngryLb = null;
        /// <summary>
        /// 归属人信息
        /// </summary>
        private ActorData onwDate = null;

        /// <summary>
        /// 剩余段数
        /// </summary>
        private UILabel remainLbl = null;

        /// <summary>
        /// 血条信息列表
        /// </summary>
        private List<BossLifeBarInfo> infos = new List<BossLifeBarInfo>();

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        public Unit Owner
        {
            get { return owner; }
            set { owner = value; }
        }

        #endregion

        #region 构造方法
        public BossLifeBar()
        {

        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 设置标题信息
        /// </summary>
        private void SetTitle()
        {
            if (title == null) return;
            int level = UnitHelper.instance.GetMonsterLevel(Owner.UnitUID);
            string val = string.Format("[CC2500FF]{0}[-] [F4DDBDFF]{1}{2}[-]", Owner.Name, Phantom.Localization.Instance.GetDes(690022), level.ToString());
            title.text = val;
            long onrUID = BossBarMgr.instance.bossOnr;
            if (onrUID != 0)
            {
                UpDropPeople(onrUID);
            }
        }

        /// <summary>
        /// 设置剩余血条数量
        /// </summary>
        private void SetRemain()
        {
            int remain = segments - curSeg;
            if (remainLbl != null) remainLbl.text = string.Format("x{0}", remain);
        }

        private void SetCurHP()
        {
            curHp = owner.HP;
        }

        /// <summary>
        /// 显示死亡血条
        /// </summary>
        private void ShowDeath()
        {
            SetRemain();
            infos[threshold].OpenForward();
            for (int i = 0; i < threshold; i++)
            {
                infos[i].Close();
            }
        }

        /// <summary>
        /// 死亡事件
        /// </summary>
        /// <param name="unit"></param>
        private void Dead(Unit unit)
        {
            if (unit != owner) return;
            curIdx = threshold;
            curSeg = segments;
            infos[curIdx].SetValue(0);
            ShowDeath();
        }
        #endregion

        #region 保护方法
        protected override bool Check()
        {
            if (transform == null) return false;
            if (owner == null) return false;
            if (owner.UnitTrans == null) return false;
            return true;
        }

        protected override void SetProperty()
        {
            TransTool.AddChild(UIMgr.Root, transform);
            string msg = "Boss血条";
            infos.Clear();
            for (int i = 0; i < 5; i++)
            {
                string bgName = string.Format("under/slider{0}", i);
                UISlider bg = ComTool.Get<UISlider>(transform, bgName, msg);
                if (bg == null) continue;
                string fgName = string.Format("{0}/fg", bgName);
                UISlider fg = ComTool.Get<UISlider>(transform, fgName, msg);
                if (fg == null) continue;
                BossLifeBarInfo info = ObjPool.Instance.Get<BossLifeBarInfo>();
                info.Bg = bg; info.Fg = fg;
                infos.Add(info);
                info.Close();
            }
            title = ComTool.Get<UILabel>(transform, "under/title", msg);
            dropPeople = ComTool.Get<UILabel>(transform, "under/title/dropPeople", msg);
            AngryLb = ComTool.Get<UILabel>(transform, "under/title/angry", msg);
            dropPeople.gameObject.SetActive(false);
            dropPeople.text = "";
            remainLbl = ComTool.Get<UILabel>(transform, "under/remain", msg);
            MonsterAtt att = MonsterAttManager.instance.Find(Owner.TypeId);
            segments = (att == null ? 5 : att.hpSeg);
            if (segments == 0) segments = 5;
            segHp = owner.MaxHP / segments;
            UnitEventMgr.die += Dead;
            threshold = length - 1;
            infos[0].OpenForward();
            infos[1].Reset();
            infos[1].Open();
            UpdateCustom();
            difHp = owner.MaxHP - owner.HP;
            curSeg = Mathf.FloorToInt(difHp / segHp);
            SetCurHP();
            SetTitle();
            Angry(att);
            SetRemain();
            AddLsnr();
        }

        protected  void Angry(MonsterAtt att )
        {
            if (att == null || att.angryTime == 0)
                AngryLb.gameObject.SetActive(false);
            else
            {
                AngryLb.gameObject.SetActive(true);
                int num = att.angryTime / 60;
                AngryLb.text = num.ToString();
            }
        }

        protected override void UpdateCustom()
        {
            infos[curIdx].Update();
            if (owner.HP <= 0)
            {
                return;
            }
            if (owner.MaxHP == owner.HP) return;
            if (curHp == owner.HP) return;
            curHp = owner.HP;
            double send = Convert.ToDouble(owner.HP) / Convert.ToDouble(owner.MaxHP);
            EventMgr.Trigger(EventKey.BossBlood, owner.TypeId, send.ToString());
            #region 计算当前值
            difHp = owner.MaxHP - owner.HP;
            curSeg = Mathf.FloorToInt(difHp / segHp);
            int difSeg = curSeg - lastSeg;
            if (difSeg > 0)
            {

                if (curSeg < (segments - 1))
                {
                    curIdx = curSeg % threshold;
                }
                else
                {
                    curIdx = threshold;
                }
                lastSeg = curSeg;

                #region 设置下一血条
                if (difSeg > 1)
                {
                    infos[nextIdx].Close();
                }

                if (curIdx != lastIdx)
                {
                    infos[lastIdx].Close();
                    lastIdx = curIdx;
                }

                if (curIdx < threshold)
                {

                    nextIdx = curIdx + 1;
                    nextIdx = (nextIdx < threshold) ? nextIdx : 0;
                    infos[curIdx].OpenForward();
                    if (curIdx != nextIdx)
                    {
                        infos[nextIdx].Reset();
                        infos[nextIdx].Open();
                    }
                }
                else
                {
                    ShowDeath();
                }

                #endregion
                SetRemain();
            }
            #endregion

            #region 设置血条进度
            float hurt = (difHp < segHp) ? difHp : (difHp % segHp);
            float value = (segHp - hurt) / segHp;
            infos[curIdx].SetValue(value);
            #endregion
        }
        #endregion

        #region 公开方法
        public override void Dispose()
        {
            base.Dispose();
            curIdx = 0;
            lastIdx = 0;
            nextIdx = 1;
            curSeg = 0;
            lastSeg = 0;
            difHp = 0;
            Owner = null;
            RemoveLsnr();
            UnitEventMgr.die -= Dead;
            ListTool.Clear<BossLifeBarInfo>(infos);
        }

        /// <summary>
        /// 创建Boss头顶血条
        /// </summary>
        /// <param name="unit">单位</param>
        /// <param name="name">名称</param>
        /// <returns></returns>
        public static BossLifeBar Create(Unit unit, string name)
        {
            if (unit == null) return null;
            if (unit.Dead) return null;
            if (unit.UnitTrans == null) return null;
            if (unit.TopBar != null && (unit.TopBar is BossLifeBar)) return null;
            if (unit.TopBar != null) unit.TopBar.Dispose();
            BossLifeBar bar = ObjPool.Instance.Get<BossLifeBar>();
            bar.BarName = TopBarFty.BossLifeBarStr;
            bar.Owner = unit;
            bar.Name = name;
            bar.Initialize(); 
            unit.TopBar = bar;
           
            return bar;
        }
        #endregion

        #region 归属
        public void AddLsnr() {
            EventMgr.Add(EventKey.MonsterExtra,UpDropPeople);
        }
        public  void RemoveLsnr()
        {
            EventMgr.Add(EventKey.MonsterExtra, UpDropPeople);
        }

        public void UpDropPeople(params object[] obj)
        {
            var bossOnr = Convert.ToInt64(obj[0]);
            if (owner == null) return;
            bool isSaveZone = MapPathMgr.instance.IsSaveZone(owner.Position);
            dropPeople.gameObject.SetActive(true);
            if (bossOnr==0 || isSaveZone)
            {
                dropPeople.text = "";
                dropPeople.gameObject.SetActive(false);
                return;
            }
            if (bossOnr == User.instance.MapData.UID)
            {
                onwDate = User.instance.MapData;
                dropPeople.text = onwDate.Name;
            }
            else if (bossOnr == User.instance.MapData.TeamID)
            {
                  onwDate = User.instance.MapData;
                dropPeople.text = onwDate.Name;
            }
            else if (User.instance.OtherRoleDic.ContainsKey(bossOnr))
            {
                onwDate = User.instance.OtherRoleDic[bossOnr];
                dropPeople.text = onwDate.Name;
            }
            else 
            {
                foreach (KeyValuePair<long, ActorData> item in User.instance.OtherRoleDic)
                {
                    if (item.Value.TeamID.ToString() == bossOnr.ToString())
                    {
                        onwDate = item.Value;
                        break;
                    }
                }
                if (onwDate != null)
                {
                    dropPeople.text = string.Format("{0}队", onwDate.Name);
                }
            }
        }
    }
    #endregion
}
