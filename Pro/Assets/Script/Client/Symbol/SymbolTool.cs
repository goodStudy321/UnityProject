using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Random = UnityEngine.Random;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:符号工具
    /// </summary>
    public static class SymbolTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 设置符号动画
        /// </summary>
        /// <param name="unit">单位</param>
        /// <param name="symbol">符号游戏对象</param>
        public static void SetTween(Unit unit, GameObject symbol)
        {
            if (unit == null) return;
            if (symbol == null) return;
            TweenPosition tweenPos = symbol.GetComponent<TweenPosition>();
            if (tweenPos != null)
            {
                Vector3 pos = unit.Position;
                float height = unit.Collider.height * unit.UnitTrans.localScale.y;
                pos.y = height + pos.y;
                tweenPos.from = pos;
                /*pos.z = Rand.Range(-2f, 2f) + pos.z;
                pos.x = Rand.Range(-2f, 2f) + pos.x;*/
                pos.y += Random.Range(1f, 2f);
                tweenPos.to = pos;
            }
            else
            {
                iTrace.Error("Loong", string.Format("符号:{0}上没有TweenPosition组件", symbol.name));
            }
        }


        /// <summary>
        /// 设置符号位置
        /// </summary>
        /// <param name="unit">单位</param>
        /// <param name="symbol">符号游戏对象</param>
        /// <param name="factor"></param>
        public static void SetPosition(Unit unit, GameObject symbol, float factor = 2)
        {
            if (unit == null) return;
            if (symbol == null) return;
            Vector3 pos = unit.Position;
            float height = unit.Collider.height * unit.UnitTrans.localScale.y;
            float offset = Random.Range(0, 1) + factor;
            pos.y = height + pos.y + offset;
            symbol.transform.position = pos;
        }

        /// <summary>
        /// 播放动画
        /// </summary>
        /// <param name="symbol">符号游戏对象</param>
        public static void PlayTween(GameObject symbol)
        {
            UIPlayTween playTween = symbol.GetComponent<UIPlayTween>();
            if (playTween != null)
            {
                playTween.resetOnPlay = true;
                playTween.Play(true);
            }
            else
            {
                iTrace.Error("Loong", string.Format("符号:{0}上没有UIPlayTween组件", symbol.name));
            }
        }

        #endregion
    }
}