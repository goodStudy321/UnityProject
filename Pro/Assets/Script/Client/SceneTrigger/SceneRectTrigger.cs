using System;
using Phantom;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        fcf1d419-7eec-4050-a942-d3666ed3ff7b
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/6 10:29:17
    /// BG:场景流程树矩形触发
    /// </summary>
    public class SceneRectTrigger : SceneTriggerBase
    {
        #region 字段
        /// <summary>
        /// 主角
        /// </summary>
        private Unit hero = null;

        /// <summary>
        /// 左下角点
        /// </summary>
        private Vector3 leftDownPoint = Vector3.zero;

        /// <summary>
        /// 右上角点
        /// </summary>
        private Vector3 rightUpPoint = Vector3.zero;

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 设置点
        /// </summary>
        /// <param name="src">配置数据</param>
        /// <param name="des">目标数据</param>
        private void SetPoint(SceneTrigger.vector3 src, ref Vector3 des)
        {
            float factor = 0.01f;
            float x = src.x * factor;
            float z = src.z * factor;
            des.Set(x, des.y, z);
        }
        #endregion

        #region 保护方法
        /// <summary>
        /// 设置点
        /// </summary>
        protected override void SetData()
        {
            if (Data == null)
            {
                rightUpPoint.Set(0, 0, 0);
                leftDownPoint.Set(0, 0, 0);
            }
            else
            {
                SetPoint(Data.left, ref leftDownPoint);
                SetPoint(Data.right, ref rightUpPoint);
            }
        }
        protected override bool Contains()
        {
            if (Data == null) return false;
            if (string.IsNullOrEmpty(Data.triggerName)) return false;
            hero = InputMgr.instance.mOwner;
            if (hero == null) return false;
            if (hero.Dead) return false;
            if (hero.UnitTrans == null) return false;
            if (AreaTool.Contains(leftDownPoint, rightUpPoint, hero.UnitTrans.position)) return true;
            return false;
        }
        protected override void Enter()
        {
            //UITip.eLog(string.Format("主角进入流程树范围:{0}", Data.triggerName));
            //TODO:断线后,重连被干掉时就会报此错误,此问题已知,但策划说没问题,因为无影响流程内容
            var triggerName = Data.triggerName;
            FlowChart flowChart = FlowChartMgr.Get(Data.triggerName);
            if (flowChart == null)
            {
                FlowChartMgr.Start(triggerName);
            }
            else
            {
                //配置为不可多次触发时
                if (Data.times == 0)
                {
                    if (flowChart.Times == 0)
                    {
                        //UITip.eLog(string.Format("流程树:{0}不可多次触发时,第一次启动", Data.triggerName));
                        FlowChartMgr.Start(triggerName);
                    }
                    else
                    {
                        //UITip.eLog(string.Format("流程树:{0}不可多次触发时,已运行过一次,无法再次运行", Data.triggerName));
                    }
                }
                else
                {
                    //执行完毕后才能多次触发条件
                    if (Data.premiseTimes == 1)
                    {
                        if (flowChart.Running)
                        {
                            //UITip.eLog(string.Format("流程树:{0}执行完毕后才可多次运行时,还在运行状态,无法再次运行", Data.triggerName));
                            return;
                        }
                    }
                    FlowChartMgr.Start(Data.triggerName);
                }
            }
        }

        protected override void Run()
        {
            if (!Contains()) State = ProcessState.Exit;
        }

        protected override void Exit()
        {
            //UITip.eLog(string.Format("主角离开流程树范围:", Data.triggerName));
        }
        #endregion

        #region 公开方法
        public override void Dispose()
        {
            ObjPool.Instance.Add(this);
            SceneTriggerMgr.Remove(this);
            Data = null;
            hero = null;
        }
        #endregion
    }
}