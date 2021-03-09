using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Slate{

	///Handles dynamic camera animation
	[System.Serializable]
	public class DynamicCameraController{

		[System.Serializable]
		public class Transposer{

			public enum TrackingMode{
				None,
				OffsetTracking,
				// RailTracking,
			}

			public enum OffsetMode{
				LocalSpace,
				WorldSpace
			}

			public TrackingMode trackingMode;
			[Tooltip("The Target from which an offset will be applied.")]
			public Transform target;
			[Tooltip("The offset from the target to mount the camera to.")]
			public Vector3 targetOffset = new Vector3(0,0,-5);
			[Tooltip("Is the offset relative to the target's Local or World Space?")]
			public OffsetMode offsetMode;
/*			
			public Vector3 railStart = new Vector3(-5,1,0);
			public Vector3 railEnd = new Vector3(5,1,0);
			public float railOffset;
*/			
			[Range(0.01f, MAX_DAMP)] [Tooltip("The smoothness to be applied.")]
			public float smoothDamping = 1f;
		}


		[System.Serializable]
		public class Composer{

			public enum TrackingMode{
				None,
				Composition
			}

			public TrackingMode trackingMode;
			[Tooltip("The target subject we want to stay within the composition frame.")]
			public Transform target;
			[Tooltip("The point of interest offset from the target in it's local space we actually care about to stay within the composition frame.")]
			public Vector3 targetOffset;
			[Min(0f)] [Tooltip("The point of interest area size to stay within the composition frame.")]
			public float targetSize = 0.25f;
			[Range(0,1)] [Tooltip("The left margin of the composition frame")]
			public float frameLeft = 0.3f;
			[Range(0,1)] [Tooltip("The right margin of the composition frame")]
			public float frameRight = 0.7f;
			[Range(0,1)] [Tooltip("The top margin of the composition frame")]
			public float frameTop = 0.3f;
			[Range(0,1)] [Tooltip("The bottom margin of the composition frame")]
			public float frameBottom = 0.7f;

			[Tooltip("The smoothness to be applied.")]
			[Range(0.01f, MAX_DAMP)]
			public float smoothDamping = 1f;
		}


		private const float MAX_DAMP = 10f;
		[SerializeField]
		private Transposer _transposer = new Transposer();
		[SerializeField]
		private Composer _composer = new Composer();

		private int lastUpdateFrame = -1;

		///The Transposer
		public Transposer transposer{
			get {return _transposer;}
		}

		///The Composer
		public Composer composer{
			get {return _composer;}
		}

		///Does controller controls position
		public bool controlsPosition{
			get {return _transposer != null && _transposer.trackingMode != Transposer.TrackingMode.None;}
		}

		///Does controller controls rotation
		public bool controlsRotation{
			get {return _composer != null && _composer.trackingMode != Composer.TrackingMode.None;}
		}

		//Update controller for target directable camera from target directable element (eg clip).
		public void UpdateControllerHard(IDirectableCamera directableCamera, IDirectable directable){ UpdateController(directableCamera, directable, true); }
		public void UpdateControllerSoft(IDirectableCamera directableCamera, IDirectable directable){ UpdateController(directableCamera, directable, false); }
		void UpdateController(IDirectableCamera directableCamera, IDirectable directable, bool isHard){

			//UpdateController is called more than once per frame if same shot is used from multiple clips in a cutscene.
			//Ensure that this is updated only once per frame.
			if (!isHard && lastUpdateFrame == Time.frameCount){ return; }
			lastUpdateFrame = Time.frameCount;

			//At least for now, Time.deltaTime is used, although the deltaTime of cutscene could.
			var deltaTime = Time.deltaTime;
			var cam = directableCamera.cam;

			if (transposer.target != null && transposer.trackingMode != Transposer.TrackingMode.None){
				var targetPos = transposer.target.position;
				if (transposer.offsetMode == Transposer.OffsetMode.LocalSpace){
					targetPos = transposer.target.TransformPoint(transposer.targetOffset);
				}
				if (transposer.offsetMode == Transposer.OffsetMode.WorldSpace){
					targetPos = transposer.target.position + transposer.targetOffset;
				}

				//offset tracking
				if (transposer.trackingMode == Transposer.TrackingMode.OffsetTracking){
					//...
				}

				//rail tracking
/*
				if (transposer.trackingMode == Transposer.TrackingMode.RailTracking){
					var aT = targetPos - transposer.railStart;
					var bT = transposer.railEnd - transposer.railStart;
					var projectT = Vector3.Project(aT, bT) + transposer.railStart;
					var normDistance = Vector3.Distance(transposer.railStart, projectT) / Vector3.Distance(transposer.railStart, transposer.railEnd);
					targetPos = Vector3.Lerp(transposer.railStart, transposer.railEnd, normDistance + transposer.railOffset);
				}
*/

				if (isHard || transposer.smoothDamping <= 0){
					directableCamera.position = targetPos;
				}

				directableCamera.position = Vector3.Lerp(directableCamera.position, targetPos, deltaTime * (MAX_DAMP/transposer.smoothDamping) );
			}			

			if (composer.target != null && composer.trackingMode != Composer.TrackingMode.None){
				if (composer.trackingMode == Composer.TrackingMode.Composition){
					var wasRotation = directableCamera.rotation;
					var pointWorldPos = composer.target.TransformPoint(composer.targetOffset);
					var rotationToTarget = Quaternion.LookRotation( pointWorldPos - directableCamera.position );
					directableCamera.rotation = rotationToTarget;

					var viewFrame = Rect.MinMaxRect(composer.frameLeft, composer.frameTop, composer.frameRight, composer.frameBottom);
					var worldFrameCenter = cam.ViewportToWorldPoint( new Vector3(1-viewFrame.center.x, viewFrame.center.y, cam.nearClipPlane ) );
					var rotationToFrame = Quaternion.LookRotation( worldFrameCenter - directableCamera.position );
					directableCamera.rotation = wasRotation;

					var interestBounds = new Bounds(pointWorldPos, new Vector3(composer.targetSize, composer.targetSize, composer.targetSize) * 2 );
					var interestViewFrame = interestBounds.ToViewRect(cam);

					if (isHard || composer.smoothDamping <= 0){
						directableCamera.rotation = rotationToFrame;
						// initHeightAtDist = 2.0f * distToTarget * Mathf.Tan(fieldOfView * 0.5f * Mathf.Deg2Rad);
					}

					var normxMin = (viewFrame.xMin - interestViewFrame.xMin) / interestViewFrame.width;
					var normxMax = (interestViewFrame.xMax - viewFrame.xMax) / interestViewFrame.width;
					var normyMin = (viewFrame.yMin - interestViewFrame.yMin) / interestViewFrame.height;
					var normyMax = (interestViewFrame.yMax - viewFrame.yMax) / interestViewFrame.height;
					var norm = Mathf.Max(normxMin, normxMax, normyMin, normyMax);
					var normDamp = Mathf.Lerp(0, deltaTime * (MAX_DAMP/composer.smoothDamping), norm );
					directableCamera.rotation = Quaternion.Lerp(wasRotation, rotationToFrame, normDamp );

					// var targetFOV = 2.0f * Mathf.Atan(initHeightAtDist * 0.5f / distToTarget) * Mathf.Rad2Deg;
					// fieldOfView = targetFOV;
				}
			}
		}

#if UNITY_EDITOR

		public void DoGUI(IDirectableCamera directableCamera, Rect container){
			if (composer.trackingMode == Composer.TrackingMode.Composition){
				if (composer.target != null){
					var cam = directableCamera.cam;

					var viewFrame = Rect.MinMaxRect(composer.frameLeft, composer.frameTop, composer.frameRight, composer.frameBottom);
					var min = new Vector2(viewFrame.xMin * container.width, viewFrame.yMin * container.height );
					var max = new Vector2(viewFrame.xMax * container.width, viewFrame.yMax * container.height );
					GUI.Box(Rect.MinMaxRect(min.x, min.y, max.x, max.y), "", Styles.hollowFrameStyle);

					var left = Rect.MinMaxRect(0, 0, min.x, container.height);
					var right = Rect.MinMaxRect(max.x, 0, container.width, container.height);
					var top = Rect.MinMaxRect(min.x, 0, max.x, min.y);
					var bottom = Rect.MinMaxRect(min.x, max.y, max.x, container.height);
					GUI.color = new Color(0,0,0,0.2f);
					GUI.DrawTexture(left, Styles.whiteTexture);
					GUI.DrawTexture(right, Styles.whiteTexture);
					GUI.DrawTexture(top, Styles.whiteTexture);
					GUI.DrawTexture(bottom, Styles.whiteTexture);
					GUI.color = Color.white;

					var pointPos = composer.target.TransformPoint(composer.targetOffset);
					var pointRect = new Rect(0,0,10,10);
					var screenPoint = cam.WorldToScreenPoint(pointPos);
					screenPoint.y = container.height - screenPoint.y;
					pointRect.center = screenPoint;
					GUI.color = Color.green;
					GUI.DrawTexture(pointRect, Styles.plusIcon);
					GUI.color = Color.white;

					var bounds = new Bounds(pointPos, new Vector3(composer.targetSize, composer.targetSize, composer.targetSize) * 2 );
					var rect = bounds.ToViewRect(cam);
					rect = new Rect(rect.x * container.width, rect.y * container.height, rect.width * container.width, rect.height * container.height);
					GUI.color = Color.green;
					GUI.Box(rect, "", Styles.hollowFrameStyle);
					GUI.color = Color.white;

					var label = string.Format("'{0}' Composition", cam.name);
					var labelSize = GUI.skin.GetStyle("label").CalcSize( new GUIContent(label) );
					var labelRect = new Rect(4, 4, labelSize.x + 2 , labelSize.y);
					GUI.DrawTexture(labelRect, Styles.whiteTexture);
					GUI.color = Color.grey;
					GUI.Label(labelRect, label);
					GUI.color = Color.white;
				}
			}
		}

		public void DoGizmos(IDirectableCamera directableCamera){
			if (transposer.target != null){
				var targetPos = transposer.target.position;
				if (transposer.offsetMode == Transposer.OffsetMode.LocalSpace){
					targetPos = transposer.target.TransformPoint(transposer.targetOffset);
				}
				if (transposer.offsetMode == Transposer.OffsetMode.WorldSpace){
					targetPos = transposer.target.position + transposer.targetOffset;
				}

				if (transposer.trackingMode == Transposer.TrackingMode.OffsetTracking){
					Gizmos.DrawLine(transposer.target.position, targetPos);
					Gizmos.DrawSphere(targetPos, 0.1f);
				}
/*				
				if (transposer.trackingMode == Transposer.TrackingMode.RailTracking){
					Gizmos.DrawLine(transposer.target.position, targetPos);
					Gizmos.DrawSphere(targetPos, 0.1f);
					Gizmos.DrawLine(transposer.railStart, transposer.railEnd);
					Gizmos.DrawLine(directableCamera.position, targetPos);
				}
*/
			}

			if (composer.target != null){
				if (composer.trackingMode == Composer.TrackingMode.Composition){
					var targetPos = composer.target.TransformPoint(composer.targetOffset);
					Gizmos.DrawSphere(targetPos, 0.1f);
					Gizmos.DrawWireSphere(targetPos, composer.targetSize);
				}
			}
		}

#endif

	}
}