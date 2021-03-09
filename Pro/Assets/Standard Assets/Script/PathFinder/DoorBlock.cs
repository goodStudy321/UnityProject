using UnityEngine;
using System.Collections;

using Loong.Game;


/// <summary>
/// 动态阻挡物（可开关）
/// </summary>
public class DoorBlock : MonoBehaviour
{
    /// <summary>
    /// 阻挡物Id（唯一）
    /// </summary>
    [HideInInspector][SerializeField]
    public uint mDoorBlockId = 0;
    /// <summary>
    /// 默认开关状态
    /// </summary>
    [HideInInspector][SerializeField]
    public bool mDefaultState = true;


    private void Awake()
    {

    }

    private void Start()
    {
        
    }

    /// <summary>
    /// 转变
    /// </summary>
    /// <param name="state"></param>
    public void ChangeState(bool blockState)
    {
        mDefaultState = blockState;
    }
}
