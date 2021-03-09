/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/6 10:32:19
 ============================================================================*/

using System;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// PackCtrl
    /// </summary>
    public class PackCtrl : IProgress
    {
        #region 字段
        private LuaTable table = null;

        //private LuaFunction setMsgFunc = null;

        private LuaFunction setTipFunc = null;

        private LuaFunction setTotalFunc = null;

        private LuaFunction setCountFunc = null;

        private LuaFunction downloadedFunc = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init()
        {
            MsgBoxProxy.Instance.Real = null;
            ProgressProxy.Instance.Real = this;
            var tableName = "PackCtrl";
            table = LuaMgr.Lua.GetTable(tableName);
            if (table == null)
            {
                iTrace.Error("Loong", "PackDl not find luaTable:{0}", tableName);
            }
            else
            {
                setTipFunc = LuaTool.GetFunc(table, "SetTip");
                setTotalFunc = LuaTool.GetFunc(table, "SetTotal");
                setCountFunc = LuaTool.GetFunc(table, "SetCount");
                downloadedFunc = LuaTool.GetFunc(table, "Downloaded");
            }
        }

        public void Init(GameObject go)
        {

        }

        public void Open()
        {

        }

        public void Close()
        {

        }

        public void Dispose()
        {

        }

        public void Downloaded()
        {
            LuaTool.Call(downloadedFunc);
        }

        public void SetTip(string tip)
        {
            LuaTool.Call(setTipFunc, tip);
        }

        public void SetCount(int count)
        {
            LuaTool.Call(setCountFunc, count);
        }


        public void SetTotal(string size, int total)
        {
            LuaTool.Call(setTotalFunc, size, total);
        }

        public void SetProgress(float val)
        {

        }


        public void SetMessage(string msg)
        {
            //LuaTool.Call(setMsgFunc, table, msg);
        }


        public void Update()
        {
            //MsgBoxProxy.Instance.Update();
            ProgressProxy.Instance.Update();
        }
        #endregion
    }
}