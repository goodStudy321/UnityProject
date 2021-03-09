/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015/4/15 21:37:16
 ============================================================================*/

#if (UNITY_IOS || UNITY_IPHONE) && !UNITY_EDITOR
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2015-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        20cd414c-b0be-479b-b955-8e9eca2c2f6b
    */

    /// <summary>
    /// IOS平台设备信息
    /// </summary>
    public class Device : DeviceBase
    {
#region 字段
        private string idfa = null;
        private string model = null;
        private string simName = null;
        private string cpuName = null;
        private int totalRom = -1;
        private string bbVer = null;
        private string kernelVer = null;
        private string sysVer = null;
        private int sysSDKVer = -1;

        public static readonly Device Instance = new Device();
#endregion

#region 属性
        public override string IMEI
        {
            get
            {
                return idfa;
            }
        }

        public override string Brand
        {
            get
            {
                return "Apple";
            }
        }

        public override string Model
        {
            get
            {
                return model;
            }
        }

        public override string SIMName
        {
            get
            {
                return simName;
            }
        }

        public override int WifiRSSI
        {
            get
            {
                return GetWifiRSSI();
            }
        }

        public override string NetType
        {
            get
            {
                return GetNetType();
            }
        }

        public override string CpuName
        {
            get
            {
                return cpuName;
            }
        }

        public override int AvaiMem
        {
            get
            {
                return GetAvaiMem();
            }
        }

        public override int TotalRom
        {
            get
            {
                return totalRom;
            }
        }

        public override int AvaiRom
        {
            get
            {
                return GetAvaiRom();
            }
        }

        public override string BBVer
        {
            get
            {
                return bbVer;
            }
        }

        public override string KernelVer
        {
            get
            {
                return kernelVer;
            }
        }

        public override string SysVer
        {
            get
            {
                return sysVer;
            }
        }

        public override int SysSDKVer
        {
            get
            {
                return sysSDKVer;
            }
        }
#endregion

#region 委托事件

#endregion

#region 构造方法

#endregion

#region 私有方法
        [DllImport("__Internal")]
        private static extern string _getIDFA();

        [DllImport("__Internal")]
        private static extern string _getModel();

        [DllImport("__Internal")]
        private static extern string _getSIMName();

        [DllImport("__Internal")]
        private static extern int _getWifiRSSI();


        [DllImport("__Internal")]
        private static extern string _getNetType();


        [DllImport("__Internal")]
        private static extern long _getAvaiMem();

        [DllImport("__Internal")]
        private static extern long _getTotalMem();

        [DllImport("__Internal")]
        private static extern long _getAvaiRom();

        [DllImport("__Internal")]
        private static extern long _getTotalRom();


        //[DllImport("__Internal")]
        //private static extern string _getBBVer();

        //[DllImport("__Internal")]
        //private static extern string _getKernelVer();

        [DllImport("__Internal")]
        private static extern string _getSysVer();



        private void SetIDFA()
        {
            try
            {
                idfa = _getIDFA();
            }
            catch (Exception e)
            {
                idfa = base.IMEI;
                Debug.LogErrorFormat("Loong, getidfa err:{0}", e.Message);
            }
        }

        private void SetModel()
        {
            try
            {
                model = _getModel();
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, getModel err:{0}", e.Message);
            }
        }

        private void SetSIMName()
        {
            try
            {
                simName = _getSIMName();
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, getSIMName err:{0}", e.Message);
            }
        }

        private int GetWifiRSSI()
        {
            int val = base.WifiRSSI;
            try
            {
                val = _getWifiRSSI();
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, getWifiRSSI err:{0}", e.Message);
            }
            return val;
        }

        private string GetNetType()
        {
            string ty = base.NetType;
            try
            {
                ty = _getNetType();
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, GetNetType err:{0}", e.Message);
            }
            return ty;
        }

        private void SetCpuName()
        {
            cpuName = base.CpuName;
        }

        private int GetAvaiMem()
        {
            int val = base.AvaiMem;
            try
            {
                val = (int)(_getAvaiMem() / 1024 / 1024);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, getAvaiMem err:{0}", e.Message);
            }
            return val;
        }

        private void SetTotalRom()
        {
            try
            {
                totalRom = (int)(_getTotalRom() / 1024 / 1024);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, _getTotalRom err:{0}", e.Message);
            }
        }

        private int GetAvaiRom()
        {
            int val = base.AvaiMem;
            try
            {
                val = (int)(_getAvaiRom() / 1024 / 1024);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, _getAvaiRom err:{0}", e.Message);
            }
            return val;
        }

        //private void SetBBVer()
        //{
        //    try
        //    {
        //        bbVer = _getBBVer();
        //    }
        //    catch (Exception e)
        //    {
        //        Debug.LogErrorFormat("Loong, _getBBVer err:{0}", e.Message);
        //    }
        //}
        //private void SetKernelVer()
        //{
        //    try
        //    {
        //        kernelVer = _getKernelVer();
        //    }
        //    catch (Exception e)
        //    {
        //        Debug.LogErrorFormat("Loong, _getKernelVer err:{0}", e.Message);
        //    }
        //}

        private void SetSysVer()
        {
            try
            {
                sysVer = _getSysVer();
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, _getSysVer err:{0}", e.Message);
            }
        }


#endregion

#region 保护方法

#endregion

#region 公开方法
        public override void Init()
        {
            base.Init();
            SetIDFA();
            SetModel();
            SetSIMName();
            SetCpuName();
            SetTotalRom();
            //SetBBVer();
            //SetKernelVer();
            bbVer = base.BBVer;
            kernelVer = base.KernelVer;
            SetSysVer();
        }
#endregion
    }
}
#endif