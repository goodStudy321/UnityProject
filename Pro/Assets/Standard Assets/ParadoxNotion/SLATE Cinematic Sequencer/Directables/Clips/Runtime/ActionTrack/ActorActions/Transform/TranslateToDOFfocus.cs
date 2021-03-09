using UnityEngine;
using System.Collections;

namespace Slate.ActionClips{

	[Category("Transform")]
	public class TranslateToDOFfocus : ActorActionClip {

		[SerializeField] [HideInInspector]
		private float _length = 1;

		public Vector3 targetPosition;
		public MiniTransformSpace space;
		public EaseType interpolation = EaseType.QuadraticInOut;

		private Vector3 originalPos;

		public override string info{
			get {return string.Format("Translate To (DOF)\n{0}", targetPosition);}
		}

		public override float length{
			get {return _length;}
			set {_length = value;}
		}

		public override float blendIn{
			get {return length;}
		}

		protected override void OnEnter(){
			originalPos = actor.transform.position;
            
            //if(Application.isPlaying == true)
            //{
            //    CutscenePlayMgr.instance.SetFxProFocusPoint(actor.transform);
            //}
		}

		protected override void OnUpdate(float deltaTime){
            

			var pos = TransformPoint(targetPosition, (TransformSpace)space);
			if (length == 0){
				actor.transform.position = pos;
				return;
			}
			actor.transform.position = Easing.Ease(interpolation, originalPos, pos, deltaTime/length );
		}

		protected override void OnReverse(){
			actor.transform.position = originalPos;

            //if (Application.isPlaying == true)
            //{
            //    CutscenePlayMgr.instance.SetFxProFocusPoint(actor.transform);
            //}
        }


		#if UNITY_EDITOR
		protected override void OnSceneGUI(){
			DoVectorPositionHandle( (TransformSpace)space, ref targetPosition);
		}
		#endif
	}
}