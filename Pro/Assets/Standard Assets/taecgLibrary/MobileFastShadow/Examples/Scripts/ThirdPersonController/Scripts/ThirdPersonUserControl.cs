using System;
using UnityEngine;

namespace taecg.tools.thirdPersonController
{
    [RequireComponent(typeof (ThirdPersonCharacter))]
    public class ThirdPersonUserControl : MonoBehaviour
    {
        private ThirdPersonCharacter m_Character;
        private Transform m_CamTrans; 
        private Vector3 m_CamForward; 
        private Vector3 moveVec3;

        
        void Start()
        {
            if (Camera.main != null)
                m_CamTrans = Camera.main.transform;
            else
                Debug.LogError("请设置主角的摄像机Tag为MainCamera");

            m_Character = GetComponent<ThirdPersonCharacter>();
        }


        void FixedUpdate()
        {
            //读取输入设置
            float h = Input.GetAxis("Horizontal");
            float v = Input.GetAxis("Vertical");

            if (m_CamTrans != null)
            {
                m_CamForward = Vector3.Scale(m_CamTrans.forward, new Vector3(1, 0, 1)).normalized;
                moveVec3 = v * m_CamForward + h * m_CamTrans.right;
            }

            m_Character.Move(moveVec3);
        }
    }
}
