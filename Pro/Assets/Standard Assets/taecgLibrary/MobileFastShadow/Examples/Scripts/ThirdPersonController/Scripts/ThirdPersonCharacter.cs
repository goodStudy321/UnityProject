using UnityEngine;

namespace taecg.tools.thirdPersonController
{
    [RequireComponent(typeof(Rigidbody))]
    [RequireComponent(typeof(CapsuleCollider))]
    [RequireComponent(typeof(Animator))]
    public class ThirdPersonCharacter : MonoBehaviour
    {
        public float MoveSpeed = 0.08f;
        [SerializeField] float m_MovingTurnSpeed = 360;
        [SerializeField] float m_StationaryTurnSpeed = 180;

        //[SerializeField] float m_MoveSpeedMultiplier = 1f;
        //[SerializeField] float m_GroundCheckDistance = 0.1f;

        Rigidbody m_Rigidbody;
        Animator m_Animator;
        bool m_IsGrounded;
        //float m_OrigGroundCheckDistance;
        const float k_Half = 0.5f;
        float m_TurnAmount;
        float m_ForwardAmount;
        Vector3 m_GroundNormal;
        //float m_CapsuleHeight;
        //Vector3 m_CapsuleCenter;
        //CapsuleCollider m_Capsule;

        void Start()
        {
            m_Animator = GetComponent<Animator>();
            m_Rigidbody = GetComponent<Rigidbody>();
            //m_Capsule = GetComponent<CapsuleCollider>();
            //m_CapsuleHeight = m_Capsule.height;
            //m_CapsuleCenter = m_Capsule.center;

            m_Rigidbody.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationY | RigidbodyConstraints.FreezeRotationZ;
            //m_OrigGroundCheckDistance = m_GroundCheckDistance;
        }

        //移动角色
        public void Move(Vector3 move)
        {
            if (move.magnitude > 1f) move.Normalize();
            move = transform.InverseTransformDirection(move);
            //CheckGroundStatus();
            move = Vector3.ProjectOnPlane(move, m_GroundNormal);
#if UNITY_EDITOR
            m_GroundNormal *= 1;
#endif
            m_TurnAmount = Mathf.Atan2(move.x, move.z);
            m_ForwardAmount = move.z;

            //转向
            float turnSpeed = Mathf.Lerp(m_StationaryTurnSpeed, m_MovingTurnSpeed, m_ForwardAmount);
            transform.Rotate(0, m_TurnAmount * turnSpeed * Time.deltaTime, 0);

            m_Animator.SetFloat("Forward", m_ForwardAmount, 0.1f, Time.deltaTime);
            transform.Translate(move * m_ForwardAmount * MoveSpeed);
        }

        //         void HandleGroundedMovement(bool jump)
        //         {
        //             // check whether conditions are right to allow a jump:
        //             if (jump && m_Animator.GetCurrentAnimatorStateInfo(0).IsName("Grounded"))
        //             {
        //                 // jump!
        //                 m_Rigidbody.velocity = new Vector3(m_Rigidbody.velocity.x, m_JumpPower, m_Rigidbody.velocity.z);
        //                 m_IsGrounded = false;
        //                 m_Animator.applyRootMotion = false;
        //                 m_GroundCheckDistance = 0.1f;
        //             }
        //         }


        //         public void OnAnimatorMove()
        //         {
        //             //we implement this function to override the default root motion.
        //             //this allows us to modify the positional speed before it's applied.
        //             if (m_IsGrounded && Time.deltaTime > 0)
        //             {
        //                 Vector3 v = (m_Animator.deltaPosition * m_MoveSpeedMultiplier) / Time.deltaTime;

        //                 // we preserve the existing y part of the current velocity.
        //                 v.y = m_Rigidbody.velocity.y;
        //                 m_Rigidbody.velocity = v;
        //             }
        //         }


        //         void CheckGroundStatus()
        //         {
        //             RaycastHit hitInfo;
        // #if UNITY_EDITOR
        //             // helper to visualise the ground check ray in the scene view
        //             Debug.DrawLine(transform.position + (Vector3.up * 0.1f), transform.position + (Vector3.up * 0.1f) + (Vector3.down * m_GroundCheckDistance));
        // #endif
        //             // 0.1f is a small offset to start the ray from inside the character
        //             // it is also good to note that the transform position in the sample assets is at the base of the character
        //             if (Physics.Raycast(transform.position + (Vector3.up * 0.1f), Vector3.down, out hitInfo, m_GroundCheckDistance))
        //             {
        //                 m_GroundNormal = hitInfo.normal;
        //                 m_IsGrounded = true;
        //                 m_Animator.applyRootMotion = true;
        //             }
        //             else
        //             {
        //                 m_IsGrounded = false;
        //                 m_GroundNormal = Vector3.up;
        //                 m_Animator.applyRootMotion = false;
        //             }
        //         }
    }
}
