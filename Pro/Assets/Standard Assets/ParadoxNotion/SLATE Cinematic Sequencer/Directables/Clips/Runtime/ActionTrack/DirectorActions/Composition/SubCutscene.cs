using UnityEngine;
using System.Collections;

namespace Slate.ActionClips{

	[Category("Composition")]
	[Description("SubCutscenes are used for organization. Notice that the CameraTrack of the SubCutscene is ignored if this Cutscene already has an active CameraTrack.")]
	public class SubCutscene : DirectorActionClip {

		[Required]
		public Cutscene cutscene;
		private bool wasCamTrackActive;

		public override string info{
			get
			{
				if (ReferenceEquals(cutscene, root)){ return "        SubCutscene can't be same as this cutscene"; }
				return cutscene != null? string.Format("        SubCutscene\n        '{0}'", cutscene.name) : "No Cutscene Selected";
			}
		}

		public override bool isValid{
			get {return cutscene != null && !ReferenceEquals(cutscene, root);}
		}

		public override float length{
			get {return isValid? cutscene.length : 0;}
		}

		new public GameObject actor{ //this is not really needed but makes double clicking the clip, select the target cutscene
			get {return isValid? cutscene.gameObject : base.actor;}
		}

		protected override void OnEnter(){
			if (cutscene.cameraTrack != null){
				wasCamTrackActive = cutscene.cameraTrack.isActive;
				cutscene.cameraTrack.isActive = false;
			}
		}

		protected override void OnReverseEnter(){
			if (cutscene.cameraTrack != null){
				wasCamTrackActive = cutscene.cameraTrack.isActive;
				cutscene.cameraTrack.isActive = false;
			}
		}

		protected override void OnExit(){
			if (cutscene.cameraTrack != null){
				cutscene.cameraTrack.isActive = wasCamTrackActive;
			}
			cutscene.SkipAll();
		}

		protected override void OnReverse(){
			if (cutscene.cameraTrack != null){
				cutscene.cameraTrack.isActive = wasCamTrackActive;
			}
			cutscene.Rewind();
		}

		protected override void OnUpdate(float time){
			cutscene.Sample(time);
		}


		////////////////////////////////////////
		///////////GUI AND EDITOR STUFF/////////
		////////////////////////////////////////
		#if UNITY_EDITOR
			
		protected override void OnClipGUI(Rect rect){
			if (cutscene != null){
				GUI.color = new Color(1,1,1,0.9f);
				GUI.DrawTexture(new Rect(0, 0, rect.height, rect.height), Slate.Styles.cutsceneIcon);
				GUI.color = Color.white;
			}
		}		

		#endif
	}
}