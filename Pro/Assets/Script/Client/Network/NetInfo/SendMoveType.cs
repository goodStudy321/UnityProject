using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum SendMoveType
{
    SendMovePoint,      //只发送移动目标点
    SendMoveRoleWalk,   //只发送移动过程路点
    SendStickMove,      //发送摇杆移动
}
