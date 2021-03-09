using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:
    /// BG:旁白节点
    /// </summary>
    [Serializable]
    public class BubbleNode : BubbleNodeBase<BubbleInfo>
    {
        #region 字段

        /// <summary>
        /// 绑定单位
        /// </summary>
        private Unit unit = null;

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Die(Unit u)
        {
            if (u != unit) return;
            if (idx == (infos.Count - 1))
            {
                Complete();
            }
            else
            {
                Next();
            }
        }


        protected override void Clear()
        {
            base.Clear();
            UnitEventMgr.die -= Die;
            unit = null;
        }

        #endregion

        #region 保护方法

        protected override void StartUp(GameObject go)
        {
            base.StartUp(go);
            if (go == null) return;
            UnitEventMgr.die += Die;
            SetBubble();
        }
        /// <summary>
        /// 设置气泡
        /// </summary>
        protected override void SetBubble()
        {

            cur = infos[idx];
            if (cur.UID < 1)
            {
                unit = InputVectorMove.instance.MoveUnit;
            }
            else
            {
                unit = UnitMgr.instance.FindUnitByUid(cur.UID);
            }
            if (unit == null)
            {
#if GAME_DEBUG
                LogError(string.Format("未发现UID为:{0}的单位", cur.UID));
#endif
                Complete();
            }
            else
            {
                UILabel textLbl = ComTool.Get<UILabel>(bTran, "text", "气泡");
                textLbl.text = Localization.Instance.GetDes(cur.textID);//cur.text;
                target = unit.UnitTrans;
                //设置高度位置
                ht = UnitHelper.instance.GetHeight(unit);
                ht += cur.ht;
            }
        }

        #endregion

        #region 公开方法


        #endregion


        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override bool CanFlag
        {
            get
            {
                return true;
            }
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }
        public override void EditDrawProperty(Object o)
        {
            UIDrawTool.IDrawLst<BubbleInfo>(o, infos, "Infos", "信息列表");
        }
#endif
        #endregion
    }
}