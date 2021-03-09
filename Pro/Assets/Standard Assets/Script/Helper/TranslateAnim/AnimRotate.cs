using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;


/// <summary>
/// 旋转动画
/// </summary>
[AddComponentMenu("Component/SampleAnim/Tween Rotation")]
public class AnimRotate : MonoBehaviour
{
    /// <summary>
    /// 旋转坐标系
    /// </summary>
    [SerializeField]
    public bool mWorld = false;
    /// <summary>
    /// 旋转方向
    /// </summary>
    [SerializeField]
    public Vector3 mRotateDir = Vector3.up;
    /// <summary>
    /// 旋转速度
    /// </summary>
    [SerializeField]
    public float mRotateSpeed = 1;


    private void Awake()
    {

    }

    private void Start()
    {
        
    }

    private void Update()
    {
        float tDTime = Time.deltaTime;
        RotateUpdate(tDTime);
    }
    
    /// <summary>
    /// 旋转更新
    /// </summary>
    /// <param name="dTime"></param>
    private void RotateUpdate(float dTime)
    {
        if (mWorld)
        {
            transform.Rotate(mRotateDir.normalized * mRotateSpeed * dTime, Space.World);
        }
        else
        {
            transform.Rotate(mRotateDir.normalized * mRotateSpeed * dTime);
        }
    }
}