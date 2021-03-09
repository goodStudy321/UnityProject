/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015/4/15 21:37:27
 ============================================================================*/

#if UNITY_STANDALONE || UNITY_EDITOR
using System;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Loong.Game
{
    /// <summary>
    /// PC平台设备信息
    /// </summary>
    public class Device : DeviceBase
    {

#if UNITY_EDITOR_WIN
        [NoToLua]
        [StructLayout(LayoutKind.Sequential)]
        public struct MemInfo
        {
            public uint dwLength;

            public uint dwMemoryLoad;

            //系统内存总量

            public ulong dwTotalPhys;

            //系统可用内存
            public ulong dwAvailPhys;

            public ulong dwTotalPageFile;

            public ulong dwAvailPageFile;

            public ulong dwTotalVirtual;

            public ulong dwAvailVirtual;

        }
        [NoToLua]
        [DllImport("kernel32")]
        public static extern void GlobalMemoryStatus(ref MemInfo memInfo);

        private MemInfo memInfo = default(MemInfo);
#endif
        #region 字段

        public static readonly Device Instance = new Device();
        #endregion

        #region 属性
        public override int AvaiMem
        {
            get
            {
#if UNITY_EDITOR_WIN
                GlobalMemoryStatus(ref memInfo);
                int mem = (int)(memInfo.dwAvailPhys / 1024UL / 1024UL);
                return mem;
#else
                return 0;
#endif
            }
        }
#endregion

#region 委托事件

#endregion

#region 构造方法
        private Device()
        {

        }
#endregion

#region 私有方法

#endregion

#region 保护方法

#endregion

#region 公开方法

#endregion
    }
}
#endif