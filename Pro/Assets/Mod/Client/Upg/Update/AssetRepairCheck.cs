/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/15 16:22:20
 ============================================================================*/

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AssetRepairCheck
    /// </summary>
    public class AssetRepairCheck
    {
        #region 字段
        #endregion

        #region 属性


        #endregion

        #region 委托事件
        public event Action complete = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Start(object o)
        {
            Debug.LogFormat("start {0}", this.GetType().Name);
            var verifyOp = (byte)AssetOp.Verify;
            bool suc = true;
            while (true)
            {
                var info = AssetRepair.Instance.GetCheck();
                if (info == null)
                {
                    Complete(); break;
                }
                suc = true;
                var path = UpgUtil.GetLocalPath(info.path);
                if (File.Exists(path))
                {
                    var md5 = Md5Crypto.GenFile(path);
                    if (md5 == info.MD5)
                    {
                        info.Op = verifyOp;
                        continue;
                    }
                    suc = false;
#if UNITY_EDITOR
                    Debug.LogWarningFormat("Loong, AssetRepairCheck: {0} invalid", info.path);
#endif
                }
                else
                {
                    suc = false;
#if UNITY_EDITOR
                    Debug.LogWarningFormat("Loong, AssetRepairCheck: {0} not exist", path);

#endif
                }
                if (!suc)
                {
                    AssetRepair.Instance.AddRepair(info);
                }
            }
        }

        private void Complete()
        {
            Debug.LogFormat("Loong, AssetRepariCheck complete");
            if (complete != null) complete();

        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void StartUp()
        {
            while (!ThreadPool.QueueUserWorkItem(Start))
            {
                Thread.Sleep(5);
            }
        }
        #endregion
    }
}