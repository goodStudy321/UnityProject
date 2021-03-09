using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitBoneInfo
{
    #region 私有字段

    #endregion

    #region 属性
    /// <summary>
    /// 角色跟节点
    /// </summary>
    public Transform Root { get; private set; }
    /// <summary>
    /// 头骨
    /// </summary>
    public Transform BoneHead { get; private set; }
    /// <summary>
    /// 身体
    /// </summary>
    public Transform BoneBody { get; private set; }
    /// <summary>
    /// 脚部
    /// </summary>
    public Transform BoneFeet { get; private set; }
    /// <summary>
    /// 特效头部
    /// </summary>
    public Transform BoneHeadFx { get; private set; }
    /// <summary>
    /// 特效质心
    /// </summary>
    public Transform BoneBip001Fx { get; private set; }
    /// <summary>
    /// 特效左手
    /// </summary>
    public Transform BoneLHandFx { get; private set; }
    /// <summary>
    /// 特效右手
    /// </summary>
    public Transform BoneRHandFx { get; private set; }
    /// <summary>
    /// 特效左脚
    /// </summary>
    public Transform BoneLFootFx { get; private set; }
    /// <summary>
    /// 特效右脚
    /// </summary>
    public Transform BoneRFootFx { get; private set; }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化骨骼信息
    /// </summary>
    public void InitBoneInfo(Transform model)
    {
        Root = model;
        BoneHead = Utility.FindNode<Transform>(model.gameObject, "Bip001 Head");
        BoneFeet = Utility.FindNode<Transform>(model.gameObject, "Bip001 Main");
        BoneBody = Utility.FindNode<Transform>(model.gameObject, "Bip001 Spine");
    }

    /// <summary>
    /// 根据名字获取骨骼名
    /// </summary>
    /// <returns></returns>
    public Transform GetBoneByName(string boneName)
    {
        if (string.IsNullOrEmpty(boneName))
            return Root;
        Transform bone = Utility.FindNode<Transform>(Root.gameObject, boneName);
        return bone;
    }

    public void Dispose()
    {
        Root = null;
        BoneHead = null;
        BoneFeet = null;
        BoneBody = null;
    }
    #endregion
}
