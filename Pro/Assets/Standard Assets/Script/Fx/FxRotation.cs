using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FxRotation : MonoBehaviour
{
    #region 字段
    public bool UseWorldSpace = false;
    public Vector3 m_vRotationValue=new Vector3(0,360,0);
    #endregion

    #region 私有方法
    private void Update()
    {
        transform.Rotate(m_vRotationValue*Time.deltaTime,UseWorldSpace?Space.World:Space.Self);
    }
    #endregion

}
