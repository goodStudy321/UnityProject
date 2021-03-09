using UnityEngine;
using System.Reflection;
using System.Linq;

namespace Slate.ActionClips{

	[Description("Animate any number of properties on any component of the actor, or within it's hierarchy.\nThis is identical to using a Properties Track, but instead the animated properties are stored within the clip and thus can be moved around as a group easier.")]
	[Attachable(typeof(ActorActionTrack), typeof(DirectorActionTrack))]
	public class AnimateProperties : ActionClip {

		[SerializeField] [HideInInspector]
		private float _length = 5f;

		[SerializeField]
		protected string _name;

		public override float length{
			get {return _length;}
			set {_length = value;}
		}


		public override bool isValid{ //valid when there is at least 1 parameter added.
			get {return base.animationData != null && base.animationData.isValid;}
		}

		public override string info{
			get { return isValid? ( string.IsNullOrEmpty(_name)? base.animationData.ToString() : _name ): "No Properties Added"; }
		}

		//By default the target is the actionclip instance. In this case, the target is the actor.
		//This also makes the clip eligable for manual parameters registration which is done here.
		public override object animatedParametersTarget{
			get {return actor;}
		}


		////////////////////////////////////////
		///////////GUI AND EDITOR STUFF/////////
		////////////////////////////////////////
		#if UNITY_EDITOR
			
		protected override void OnSceneGUI(){
			
			if (!isValid){
				return;
			}

			for (var i = 0; i < animationData.animatedParameters.Count; i++){
				var animParam = animationData.animatedParameters[i];
				if (animParam.parameterName == "localPosition"){
					var transform = animParam.ResolvedObject() as Transform;
					if (transform != null){
						var context = transform.parent != null? transform.parent : GetSpaceTransform(TransformSpace.CutsceneSpace);
						CurveEditor3D.Draw3DCurve(animParam, this, context, length/2, length);
					}
				}
			}
		}

		#endif
				
	}
}