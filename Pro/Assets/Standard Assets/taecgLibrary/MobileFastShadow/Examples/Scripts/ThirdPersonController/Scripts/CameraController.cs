using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

namespace taecg.tools.thirdPersonController
{
    public class CameraController : MonoBehaviour
    {
        [Header("跟随的对象")]
        public Transform target;

        [Header("摄像机远近")]
        public float DistanceMin = 1f;
        public float DistanceMax = 10f;
        public float ZoomIntensity = 10f;
        private float distance = 13f;

        [Header("视角滑动速度")]
        public float xSpeed = 200;
        public float ySpeed = 100;

        [Header("角度限制")]
        public bool IsAutoLimit = true;
        public float yMinLimit = -10;
        public float yMaxLimit = 60;

        // 摄像头的位置  
        private float x = 0.0f;
        private float y = 0.0f;

#if UNITY_ANDROID || UNITY_IOS
        // 记录上一次手机触摸位置判断用户是在做放大还是缩小手势  
        private Vector2 oldPosition1 = new Vector2 (0, 0);
        private Vector2 oldPosition2 = new Vector2 (0, 0);
#endif

        //初始化游戏信息设置  
        void Start()
        {
            Vector3 angles = transform.eulerAngles;
            x = angles.y;
            y = angles.x;

            // GetComponent<Rigidbody>().freezeRotation = true;
        }

        void Update()
        {
#if UNITY_EDITOR || UNITY_STANDALONE
            if (Input.GetMouseButton(1))
            {
                x += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
                y -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f;
            }
            distance = Mathf.Clamp(distance - (Input.GetAxis("Mouse ScrollWheel") * ZoomIntensity), DistanceMin, DistanceMax);
            if (IsAutoLimit)
            {
                float _normalize = (distance - DistanceMin) / (DistanceMax - DistanceMin);
                yMinLimit = yMaxLimit = Mathf.Lerp(10, 40, _normalize);
            }
#endif
#if UNITY_ANDROID || UNITY_IOS
            List<Touch> _touchList = new List<Touch> ();
            _touchList.Clear ();
            foreach (Touch t in Input.touches)
            {
                if (!EventSystem.current.IsPointerOverGameObject (t.fingerId))
                    _touchList.Add (t);
            }
            // 判断触摸数量为单点触摸  
            if (_touchList.Count == 1 && _touchList[0].phase == TouchPhase.Moved)
            {
                //根据触摸点计算X与Y位置  
                x += Input.GetAxis ("Mouse X") * xSpeed * 0.02f;
                y -= Input.GetAxis ("Mouse Y") * ySpeed * 0.02f;
            }

            //缩放
            if (_touchList.Count >= 2)
            {
                if (_touchList[0].phase == TouchPhase.Moved || _touchList[1].phase == TouchPhase.Moved)
                {
                    // 计算出当前两点触摸点的位置  
                    var tempPosition1 = _touchList[0].position;
                    var tempPosition2 = _touchList[1].position;
                    // 函数返回真为放大，返回假为缩小  
                    if (isEnlarge (oldPosition1, oldPosition2, tempPosition1, tempPosition2))
                    {
                        if (distance > DistanceMin)
                        {
                            distance -= 0.5f;
                        }
                    }
                    else
                    {
                        if (distance < DistanceMax)
                        {
                            distance += 0.5f;
                        }
                    }
                    // 备份上一次触摸点的位置，用于对比  
                    oldPosition1 = tempPosition1;
                    oldPosition2 = tempPosition2;
                }
            }
#endif
        }

        // 函数返回真为放大，返回假为缩小  
        bool isEnlarge(Vector2 oP1, Vector2 oP2, Vector2 nP1, Vector2 nP2)
        {
            // 函数传入上一次触摸两点的位置与本次触摸两点的位置计算出用户的手势  
            float leng1 = Mathf.Sqrt((oP1.x - oP2.x) * (oP1.x - oP2.x) + (oP1.y - oP2.y) * (oP1.y - oP2.y));
            float leng2 = Mathf.Sqrt((nP1.x - nP2.x) * (nP1.x - nP2.x) + (nP1.y - nP2.y) * (nP1.y - nP2.y));

            if (leng1 < leng2)
            {
                // 放大手势  
                return true;
            }
            else
            {
                // 缩小手势  
                return false;
            }
        }

        // Update方法一旦调用结束以后进入这里算出重置摄像机的位置  
        void LateUpdate()
        {
            // target为主角，缩放旋转的参照物  
            if (target)
            {
                // 重置摄像机的位置  
                y = ClampAngle(y, yMinLimit, yMaxLimit);
                Quaternion rotation = Quaternion.Euler(y, x, 0);
                Vector3 position = rotation * new Vector3(0.0f, 0.0f, -distance) + target.position;

                transform.rotation = rotation;
                transform.position = position;
            }
        }

        static float ClampAngle(float angle, float min, float max)
        {
            if (angle < -360)
                angle += 360;
            if (angle > 360)
                angle -= 360;
            return Mathf.Clamp(angle, min, max);
        }
    }
}