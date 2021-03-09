#if UNITY_5_4_OR_NEWER

using UnityEngine;
//using UnityEngine.Experimental.Director;
using UnityEngine.Playables;
using UnityEngine.Animations;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Slate.ActionClips;

namespace Slate{

	[UniqueElement] //one per group until Unity releases layer mixer playable
	[Description("The Animator Track works with an 'Animator' Component attached on the actor, but does not require or use the Controller assigned. Instead animation clips can be played directly. The 'Base Animation Clip' will be played along the whole track length when no other animation clip is playing. This can usualy be something like an Idle.")]
	[Icon("Animator Icon")]
	[Attachable(typeof(ActorGroup))]
    [Category("Legacy")]
    public class AnimatorTrack : CutsceneTrack {

		const int ROOTMOTION_FRAMERATE = 30;

		public AnimationClip baseAnimationClip;
		[Range(0.1f, 2)]
		public float basePlaybackSpeed = 1f;
		public bool useRootMotion = false;

		public Animator animator{get; private set;}
		private Dictionary<PlayAnimatorClip, int> ports;
		private int activeClips;

#if UNITY_5_6_OR_NEWER
		private PlayableGraph graph;
		private AnimationPlayableOutput animationOutput;
		private AnimationMixerPlayable mixerPlayableHandle;
		private AnimationClipPlayable baseClipPlayableHandle;
#else
		private AnimationMixerPlayable mixerPlayable;
#endif

		private bool useBakedRootMotion;
		private List<Vector3> rmPositions;
		private List<Quaternion> rmRotations;

		private Dictionary<AnimatorControllerParameter, object> wasAnimatorParameters;
		private RuntimeAnimatorController wasController;
		private AnimatorCullingMode wasCullingMode;
		private bool wasRootMotion;
		private bool wasEnabled;

		public override string info{
			get {return string.Format("Base Clip: {0}", baseAnimationClip? baseAnimationClip.name : "NONE");}
		}


		//...
		protected override bool OnInitialize(){
			animator = actor.GetComponentInChildren<Animator>();
			if (animator == null){
				Debug.LogError("Animator Track requires that the actor has the Animator Component attached.", actor);
				return false;
			}

			return true;
		}

		protected override void OnEnter(){

			animator = actor.GetComponentInChildren<Animator>(); //re-get to fetch from virtual actor ref instance if any
			if (animator == null){
				return;
			}

			StoreSet();
			CreateAndPlayTree();
			if (useRootMotion){
				BakeRootMotion();
			}
		}

		protected override void OnUpdate(float time, float previousTime){

			if (animator == null || !animator.gameObject.activeInHierarchy){
				return;
			}

#if UNITY_5_6_OR_NEWER

			if (!graph.IsValid()){
				return;
			}

			baseClipPlayableHandle.SetTime(time * basePlaybackSpeed);
			graph.Evaluate(0);
#else

			if (!mixerPlayable.IsValid()){
				return;
			}

			if (!animator.isInitialized){
				animator.Play(mixerPlayable);
			}

			if (baseAnimationClip != null){
				var basePlayable = mixerPlayable.GetInput(0);
				basePlayable.time = time * basePlaybackSpeed;
				mixerPlayable.SetInput(basePlayable, 0);
			}

			animator.Update(0);
#endif			

			if (useRootMotion && useBakedRootMotion){
				ApplyBakedRootMotion(time);
			}
		}

		protected override void OnReverseEnter(){

			animator = actor.GetComponentInChildren<Animator>(); //re-get to fetch from virtual actor ref instance if any
			if (animator == null){
				return;
			}

			StoreSet();
			CreateAndPlayTree();
			//DO NOT Re-Bake root motion
		}

		protected override void OnExit(){
			Restore();
			if (useRootMotion){
				ApplyBakedRootMotion(endTime - startTime);
			}
		}
		protected override void OnReverse(){
			Restore();
			if (useRootMotion){
				ApplyBakedRootMotion(0);
			}
		}


		public void EnableClip(PlayAnimatorClip playAnimClip){

			if (animator == null){
				return;
			}

#if UNITY_5_6_OR_NEWER

			if (!graph.IsValid()){
				return;
			}
#else

			if (!mixerPlayable.IsValid()){
				return;
			}
#endif

			activeClips++;
			var index = ports[playAnimClip];
			var weight = playAnimClip.GetClipWeight();

#if UNITY_5_6_OR_NEWER
			mixerPlayableHandle.SetInputWeight(0, activeClips == 2? 0 : 1 - weight);
			mixerPlayableHandle.SetInputWeight(index, weight);
#else
			mixerPlayable.SetInputWeight(0, activeClips == 2? 0 : 1 - weight);
			mixerPlayable.SetInputWeight(index, weight);
#endif			
		}

		public void UpdateClip(PlayAnimatorClip playAnimClip, float clipTime, float clipPrevious, float weight){

			if (animator == null){
				return;
			}

#if UNITY_5_6_OR_NEWER
			if (!graph.IsValid()){
				return;
			}
#else
			if (!mixerPlayable.IsValid()){
				return;
			}
#endif

			var index = ports[playAnimClip];

#if UNITY_5_6_OR_NEWER
			Playable clipPlayable = mixerPlayableHandle.GetInput(index);
			clipPlayable.SetTime(clipTime);
			mixerPlayableHandle.SetInputWeight(index, weight);
			mixerPlayableHandle.SetInputWeight(0, activeClips == 2? 0 : 1 - weight);
#else
			var clipPlayable = mixerPlayable.GetInput(index);
			clipPlayable.time = clipTime;
			mixerPlayable.SetInput(clipPlayable, index);
			mixerPlayable.SetInputWeight(index, weight);
			mixerPlayable.SetInputWeight(0, activeClips == 2? 0 : 1 - weight );
#endif
		}

		public void DisableClip(PlayAnimatorClip playAnimClip){

			if (animator == null){
				return;
			}

#if UNITY_5_6_OR_NEWER
			if (!graph.IsValid()){
				return;
			}
#else
			if (!mixerPlayable.IsValid()){
				return;
			}
#endif


			activeClips--;
			var index = ports[playAnimClip];

#if UNITY_5_6_OR_NEWER
			mixerPlayableHandle.SetInputWeight(0, activeClips == 0? 1 : 0);
			mixerPlayableHandle.SetInputWeight(index, 0);			
#else
			mixerPlayable.SetInputWeight(0, activeClips == 0? 1 : 0);
			mixerPlayable.SetInputWeight(index, 0);
#endif
		}
		

		void StoreSet(){

			wasController  = animator.runtimeAnimatorController;
			wasRootMotion  = animator.applyRootMotion;
			wasCullingMode = animator.cullingMode;
			wasEnabled     = animator.enabled;

#if UNITY_5_6_OR_NEWER
			animator.applyRootMotion = false;
			animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;			
#else
			if (Application.isPlaying && animator.runtimeAnimatorController != null){
				StoreAnimatorInfo();
			}

			//if we dont set controller null, unity does not initialize deactivated animators when they enable and also cause animator crashes.
			//if we do set controller null, unity crashes for already activated animators.
			//checking isInitialized does not work, thus checking gameobject active seems only solution until animator fixed.
			if (!animator.gameObject.activeInHierarchy){
				animator.runtimeAnimatorController = null;
			}
			animator.applyRootMotion = false;
			animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
			animator.enabled = false;
#endif
		}


		void Restore(){

			if (animator != null){
				animator.runtimeAnimatorController = wasController;
				animator.applyRootMotion = wasRootMotion;
				animator.cullingMode = wasCullingMode;
				animator.enabled = wasEnabled;		
			}

#if UNITY_5_6_OR_NEWER
			graph.Destroy();
#else
			mixerPlayable.Destroy();
			if (Application.isPlaying && animator.runtimeAnimatorController != null){
				RestoreAnimatorInfo();
			}
#endif
		}



		//Create playable tree
		void CreateAndPlayTree(){

#if UNITY_5_6_OR_NEWER
			List<PlayAnimatorClip> clipActions = actions.OfType<PlayAnimatorClip>().ToList();
			int inputCount = 1 + clipActions.Count;
			ports = new Dictionary<PlayAnimatorClip, int>();
			graph = PlayableGraph.Create();
			mixerPlayableHandle = AnimationMixerPlayable.Create(graph, inputCount, true);
			mixerPlayableHandle.SetInputWeight(0, 1f);
			baseClipPlayableHandle = AnimationClipPlayable.Create(graph, baseAnimationClip);
            //baseClipPlayableHandle.playState = PlayState.Paused;
            baseClipPlayableHandle.Pause();
			graph.Connect(baseClipPlayableHandle, 0, mixerPlayableHandle, 0);

			var index = 1; //0 is baseclip
			foreach(var playAnimClip in clipActions){
				var clipPlayableHandle = AnimationClipPlayable.Create(graph, playAnimClip.animationClip);
				graph.Connect(clipPlayableHandle, 0, mixerPlayableHandle, index);
				mixerPlayableHandle.SetInputWeight(index, 0f);
				ports[playAnimClip] = index;
                //clipPlayableHandle.playState = PlayState.Paused;
                clipPlayableHandle.Pause();
                index++;
			}

			animationOutput = AnimationPlayableOutput.Create(graph, "Animation", animator);
            animationOutput.SetSourcePlayable(mixerPlayableHandle);
			mixerPlayableHandle.Pause();
			graph.Play();

#else
			ports = new Dictionary<PlayAnimatorClip, int>();
			mixerPlayable = AnimationMixerPlayable.Create();

			var basePlayableClip = AnimationClipPlayable.Create(baseAnimationClip);
			basePlayableClip.state = PlayState.Paused;
			mixerPlayable.AddInput(basePlayableClip);

			foreach(var playAnimClip in actions.OfType<PlayAnimatorClip>()){
				var playableClip = AnimationClipPlayable.Create(playAnimClip.animationClip);
				playableClip.state = PlayState.Paused;
				var index = mixerPlayable.AddInput(playableClip);
				mixerPlayable.SetInputWeight(index, 0f);
				ports[playAnimClip] = index;
			}

			animator.SetTimeUpdateMode(DirectorUpdateMode.Manual);
			animator.Play(mixerPlayable);
			mixerPlayable.state = PlayState.Paused;
#endif

			// GraphVisualizerClient.Show(graph, animator.name);
		}


		//The root motion must be baked if required.
		void BakeRootMotion(){
			useBakedRootMotion = false;
			animator.applyRootMotion = true;
			rmPositions = new List<Vector3>();
			rmRotations = new List<Quaternion>();
			var lastTime = -1f;
			var updateInterval = (1f/ROOTMOTION_FRAMERATE);
			var tempActiveClips = 0;
			for (var i = startTime; i <= endTime + updateInterval; i += updateInterval){
				foreach(var clip in (this as IDirectable).children){

					if (i >= clip.startTime && lastTime < clip.startTime){
						tempActiveClips++;
						clip.Enter();
					}

					if (i >= clip.startTime && i <= clip.endTime){
						clip.Update(i - clip.startTime, i - clip.startTime - updateInterval);
					}

					if ( (i > clip.endTime || i >= this.endTime) && lastTime <= clip.endTime){
						tempActiveClips--;
						clip.Exit();
					}
				}

				if (tempActiveClips > 0){
					#if UNITY_5_6_OR_NEWER
					graph.Evaluate(updateInterval);
					#else
					animator.Update(updateInterval);
					#endif
				}

				rmPositions.Add(animator.transform.localPosition);
				rmRotations.Add(animator.transform.localRotation);
				lastTime = i;
			}
			animator.applyRootMotion = false;
			useBakedRootMotion = true;
		}

		//Apply baked root motion by lerping between stored frames.
		void ApplyBakedRootMotion(float time){
			var frame = Mathf.FloorToInt( time * ROOTMOTION_FRAMERATE );
			var nextFrame = frame + 1;
			nextFrame = nextFrame < rmPositions.Count? nextFrame : rmPositions.Count - 1;

			var tNow = frame * (1f/ROOTMOTION_FRAMERATE);
			var tNext = nextFrame * (1f/ROOTMOTION_FRAMERATE);
		
			var posNow = rmPositions[frame];
			var posNext = rmPositions[nextFrame];
			var pos = Vector3.Lerp(posNow, posNext, Mathf.InverseLerp(tNow, tNext, time) );
			animator.transform.localPosition = pos;

			var rotNow = rmRotations[frame];
			var rotNext = rmRotations[nextFrame];
			var rot = Quaternion.Lerp(rotNow, rotNext, Mathf.InverseLerp(tNow, tNext, time) );
			animator.transform.localRotation = rot;
		}

		//store animator parameters info
		void StoreAnimatorInfo(){
			wasAnimatorParameters = new Dictionary<AnimatorControllerParameter, object>();
			foreach (var param in animator.parameters){
				if (param.type == AnimatorControllerParameterType.Float){
					wasAnimatorParameters[param] = animator.GetFloat(param.name);
				}
				if (param.type == AnimatorControllerParameterType.Int){
					wasAnimatorParameters[param] = animator.GetInteger(param.name);
				}
				if (param.type == AnimatorControllerParameterType.Bool){
					wasAnimatorParameters[param] = animator.GetBool(param.name);
				}
			}
		}

		//restore animator parameters info
		void RestoreAnimatorInfo(){
			foreach(var pair in wasAnimatorParameters){
				var param = pair.Key;
				if (param.type == AnimatorControllerParameterType.Float){
					animator.SetFloat( param.name, (float)pair.Value );
				}
				if (param.type == AnimatorControllerParameterType.Int){
					animator.SetInteger( param.name, (int)pair.Value );
				}
				if (param.type == AnimatorControllerParameterType.Bool){
					animator.SetBool( param.name, (bool)pair.Value );
				}				
			}
			wasAnimatorParameters = null;
		}

        /// LY add begin ///
        private void DestoryResWhenQuitInAnim()
        {
#if UNITY_5_6_OR_NEWER
            if (graph.IsValid() == true)
            {
                graph.Destroy();
            }
#endif
        }
        /// LY add end ///
    }
}

#endif