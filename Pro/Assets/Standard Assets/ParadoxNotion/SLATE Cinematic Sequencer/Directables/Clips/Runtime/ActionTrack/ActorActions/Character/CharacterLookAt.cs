using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace Slate.ActionClips{

	[Name("Character Head Look At")]
	[Category("Character")]
	public class CharacterLookAt : ActorActionClip<Character> {

		[SerializeField] [HideInInspector]
		private float _length = 1f;
		[SerializeField] [HideInInspector]
		private float _blendIn = 0.25f;
		[SerializeField] [HideInInspector]
		private float _blendOut = 0.25f;

		public EaseType interpolation = EaseType.QuadraticInOut;
		[AnimatableParameter(0,1)]
		public float weight = 1;
		public PositionParameter targetPosition;

		private Quaternion originalRot1; 
		private Quaternion originalRot2;

		[AnimatableParameter(link="targetPosition")]
		[ShowTrajectory] [PositionHandle]
		public Vector3 targetPositionVector{
			get {return targetPosition.value;}
			set {targetPosition.value = value;}
		}

		public override string info{
			get {return string.Format("Head Look At {0}", targetPosition.useAnimation? "" : targetPosition.ToString());}
		}

		public override bool isValid{
			get {return actor != null && actor.head != null && actor.neck != null; }
		}

		public override float length{
			get {return _length;}
			set {_length = value;}
		}

		public override float blendIn{
			get {return _blendIn;}
			set {_blendIn = value;}
		}

		public override float blendOut{
			get {return _blendOut;}
			set {_blendOut = value;}
		}

		protected override void OnCreate(){
			if (isValid){
				targetPosition.value = InverseTransformPoint(actor.head.position, targetPosition.space);
			}
		}

		protected override void OnAfterValidate(){
			SetParameterEnabled("targetPositionVector", targetPosition.useAnimation);
		}

		protected override void OnEnter(){
			originalRot1 = actor.head.rotation;
			originalRot2 = actor.neck.rotation;
		}

		protected override void OnUpdate(float time){
			var pos = TransformPoint(targetPosition.value, targetPosition.space);
			var finalWeight = GetClipWeight(time) * weight;

			var lookRot2 = Quaternion.LookRotation(pos - actor.neck.position, actor.upVector);
			actor.neck.rotation = Easing.Ease(interpolation, originalRot2, lookRot2, finalWeight * 0.5f);
			
			var lookRot1 = Quaternion.LookRotation(pos - actor.head.position, actor.upVector);
			actor.head.rotation = Easing.Ease(interpolation, originalRot1, lookRot1, finalWeight);
		}

		protected override void OnReverse(){
			actor.head.rotation = originalRot1;
			actor.neck.rotation = originalRot2;
		}



		////////////////////////////////////////
		///////////GUI AND EDITOR STUFF/////////
		////////////////////////////////////////
		#if UNITY_EDITOR
			
		protected override void OnDrawGizmosSelected(){
			if (isValid && RootTimeWithinRange()){
				var pos = TransformPoint(targetPosition.value, targetPosition.space);
				Gizmos.color = new Color(1,1,1, GetClipWeight() * weight );
				Gizmos.DrawLine(actor.head.position, pos);
				Gizmos.color = Color.white;
			}
		}

		#endif

	}
}