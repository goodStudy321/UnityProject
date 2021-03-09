using System;
using System.Collections;
using System.Collections.Generic;

/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        ad831d63-b937-4ca3-81a9-2d512fdace85
*/

/// <summary>
/// AU:Loong
/// TM:2017/6/2 11:18:49
/// BG:运行状态
/// </summary>
public enum TransitionState
{
    /// <summary>
    /// 等待
    /// </summary>
    Wait,

    /// <summary>
    /// 准备
    /// </summary>
    Ready,

    /// <summary>
    /// 运行
    /// </summary>
    Update,

    /// <summary>
    /// 结束
    /// </summary>
    Complete,

    /// <summary>
    /// 停止
    /// </summary>
    Stop
}