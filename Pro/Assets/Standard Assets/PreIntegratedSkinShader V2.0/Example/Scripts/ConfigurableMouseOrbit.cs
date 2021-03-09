using UnityEngine;
using System.Collections;

namespace JBrothers.PreIntegratedSkinShader2.Demo {
	[AddComponentMenu("Camera-Control/Configurable Mouse Orbit")]
	public class ConfigurableMouseOrbit : MonoBehaviour {
		public Transform target;
		public float distance = 3.0f;
		public float zoomSpeed = 1.0f;
		public float distanceMin = 0.2f;
		public float distanceMax = 10f;

		public float xSpeed = 250.0f;
		public float ySpeed = 120.0f;

		public float yMinLimit = 0f;
		public float yMaxLimit = 90f;
		
		private float x = 0.0f;
		private float y = 0.0f;
		
		public bool centerToAABB = true;
		public bool ScrollZoom = true;
		
		public MouseButton mouseButton = MouseButton.Left;
		
		public bool lockCursor = true;
		
		public enum MouseButton : int {
			None = -1,
			Left = 0,
			Middle = 2,
			Right = 1
		}
		
		void Start () {
		    if (!target)
				return;
			
		    var angles = transform.eulerAngles;
		    x = angles.y;
		    y = angles.x;
		
			// Make the rigid body not change rotation
		   	if (GetComponent<Rigidbody>())
				GetComponent<Rigidbody>().freezeRotation = true;
		}

		#if UNITY_5_0 || UNITY_5_1 || UNITY_5_2 || UNITY_5_3 || UNITY_5_4 || UNITY_5_5 || UNITY_5_6_OR_NEWER
		private bool CursorLocked {
			get {
				return Cursor.lockState == CursorLockMode.Locked;
			}
			set {
				Cursor.lockState = value ? CursorLockMode.Locked : CursorLockMode.None;
			}
		}
		#else // Unity 3/4
		private bool CursorLocked {
			get {
				return Screen.lockCursor;
			}
			set {
				Screen.lockCursor = value;
			}
		}
		#endif

		private bool isMouseOverGUI() {
			return GUIUtility.hotControl != 0;
		}

		void Update() {
		    if (!target)
				return;
			
			if (mouseButton == MouseButton.None || (Input.GetMouseButton((int)mouseButton) && !isMouseOverGUI())) {
				if (!CursorLocked && lockCursor)
					CursorLocked = true;
		        x += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
		        y -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f;
			} else {
				if (CursorLocked && lockCursor)
					CursorLocked = false;
			}
			
			if (ScrollZoom) {
				float wheelDelta = Input.GetAxis("Mouse ScrollWheel");
				if (wheelDelta != 0f)
					distance = Mathf.Clamp(distance * (1.0f - wheelDelta * zoomSpeed), distanceMin, distanceMax);

				if (Input.touchCount == 2) {
					// Store both touches.
					Touch touchZero = Input.GetTouch(0);
					Touch touchOne = Input.GetTouch(1);
					
					// Find the position in the previous frame of each touch.
					Vector2 touchZeroPrevPos = touchZero.position - touchZero.deltaPosition;
					Vector2 touchOnePrevPos = touchOne.position - touchOne.deltaPosition;
					
					// Find the magnitude of the vector (the distance) between the touches in each frame.
					float prevTouchDeltaMag = (touchZeroPrevPos - touchOnePrevPos).magnitude;
					float touchDeltaMag = (touchZero.position - touchOne.position).magnitude;
					
					// Find the difference in the distances between each frame.
					float deltaMagnitudeDiff = prevTouchDeltaMag - touchDeltaMag;

					distance = Mathf.Clamp(distance * (1.0f + deltaMagnitudeDiff * zoomSpeed*0.1f), distanceMin, distanceMax);
				}
			}
	 		y = ClampAngle(y, yMinLimit, yMaxLimit);
			
	        Quaternion rotation = Quaternion.Euler(y, x, 0f);
	        Vector3 position = rotation * new Vector3(0.0f, 0.0f, -distance) + target.position;
			if (centerToAABB && target.GetComponent<Renderer>())
				position += target.transform.InverseTransformPoint(target.GetComponent<Renderer>().bounds.center);
	        
	        transform.localRotation = rotation;
	        transform.localPosition = position;
		}

		static float ClampAngle(float angle, float min, float max) {
			if (angle < -360f)
				angle += 360f;
			if (angle > 360f)
				angle -= 360f;
			return Mathf.Clamp(angle, min, max);
		}

	}
}