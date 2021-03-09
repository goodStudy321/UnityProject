using UnityEngine;
using System.Collections.Generic;
using System.Reflection;
using System.Linq;

namespace Slate{

	[System.Serializable]
	///A wrapped collection of Animated Parameters. Basically what AnimationClip is to Unity, but for Slate.
	public class AnimationDataCollection : IAnimatableData{

		[SerializeField]
		private List<AnimatedParameter> _animatedParameters;
		public List<AnimatedParameter> animatedParameters{
			get {return _animatedParameters;}
			private set {_animatedParameters = value;}
		}

		///are there any parameters?
		public bool isValid{
			get {return animatedParameters != null && animatedParameters.Count > 0;}
		}

		///indexer by index in list
		public AnimatedParameter this[int i]{
			get { return animatedParameters != null && i < animatedParameters.Count? animatedParameters[i] : null; }
		}

		///indexer by name of parameter
		public AnimatedParameter this[string name]{
			get { return GetParameterOfName(name); }
		}

		public AnimationDataCollection(){}
		public AnimationDataCollection(MemberInfo[] memberInfoParameters, IKeyable keyable, Transform child, Transform root){
			foreach(var member in memberInfoParameters){
				TryAddParameter(member, keyable, child, root);
			}
		}

		///Creates a new animated parameter out of a member info that optionaly exists on a component in child transform of root transform.
		public bool TryAddParameter(MemberInfo member, IKeyable keyable, Transform child, Transform root){
			
			if (animatedParameters == null){
				animatedParameters = new List<AnimatedParameter>();
			}

			var newParam = new AnimatedParameter(member, keyable, child, root);
			if (!newParam.isValid){
				return false;
			}

			var found = animatedParameters.Find(p => p.CompareTo(newParam));
			if (found != null){
				//handle possible changes from property to field and vice-verse
				if (found.parameterType != newParam.parameterType){
					found.ChangeMemberType(newParam.parameterType);
				}
				return false;
			}

			animatedParameters.Add(newParam);
			return true;
		}

		///Fetch a parameter with specified name
		public AnimatedParameter GetParameterOfName(string name){
			if (animatedParameters == null){
				return null;
			}
			return animatedParameters.Find(d => d.parameterName.ToLower() == name.ToLower());
		}

		///Get all parameter animation curves
		public AnimationCurve[] GetCurves(){return Internal_GetCurves(true);}
		public AnimationCurve[] GetCurvesAll(){return Internal_GetCurves(false);}
		AnimationCurve[] Internal_GetCurves(bool enabledParamsOnly){

			if (animatedParameters == null){
				return new AnimationCurve[0];
			}

			var result = new List<AnimationCurve>();
			for (var i = 0; i < animatedParameters.Count; i++){
				if (!enabledParamsOnly || animatedParameters[i].enabled){
					var curves = animatedParameters[i].GetCurves();
					if (curves != null){
						result.AddRange(curves);
					}
				}
			}
			return result.ToArray();
		}


		///0. Validate the parameters within the context of a keyable reference
		public void Validate(IKeyable keyable){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].Validate(keyable);
				}
			}			
		}

		///1. If a virtualTransformParent is set, transforms will be virtually parented to that tranform
		public void SetVirtualTransformParent(Transform virtualTransformParent){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].SetVirtualTransformParent(virtualTransformParent);
				}
			}			
		}

		///2. Set snapshot of current value
		public void SetSnapshot(){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].SetSnapshot();
				}
			}
		}

		///3. Will key all parameters that have their value changed
		public bool TryAutoKey(float time){
			if (animatedParameters != null){
				var anyKeyAdded = false;
				for (var i = 0; i < animatedParameters.Count; i++){
					if (animatedParameters[i].TryAutoKey(time)){
						anyKeyAdded = true;
					}
				}
				
				return anyKeyAdded;
			}

			return false;
		}

		///4. Evaluate parameters
		public void Evaluate(float time, float previousTime){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].Evaluate(time, previousTime);
				}
			}
		}

		///5. Restore stored snapshot
		public void RestoreSnapshot(){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].RestoreSnapshot();
				}
			}
		}


		///Try add key at time, with identity value either from existing curves at that time, or in case of no curves from current property value.
		public bool TryKeyIdentity(float time){
			if (animatedParameters != null){
				var anyKeyAdded = false;
				for (var i = 0; i < animatedParameters.Count; i++){
					if (animatedParameters[i].TryKeyIdentity(time)){
						anyKeyAdded = true;
					}
				}

				return anyKeyAdded;
			}

			return false;	
		}

		///Remove keys at time
		public void RemoveKey(float time){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].RemoveKey(time);
				}
			}
		}

		///Is any parameter in this collection changed?
		public bool HasChanged(){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					if (animatedParameters[i].HasChanged()){
						return true;
					}
				}
			}

			return false;			
		}

		///Is there any key at time?
		public bool HasKey(float time){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					if (animatedParameters[i].HasKey(time)){
						return true;
					}
				}
			}

			return false;
		}

		///Are there any keys at all?
		public bool HasAnyKey(){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					if (animatedParameters[i].HasAnyKey()){
						return true;
					}
				}
			}

			return false;			
		}

		///Set key in all parameters at current value
		public void SetKeyCurrent(float time){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].SetKeyCurrent(time);
				}
			}			
		}


		///The next key time after time
		public float GetKeyNext(float time){
			if (animatedParameters != null){
				return animatedParameters.Select(p => p.GetKeyNext(time)).OrderBy(t => t).FirstOrDefault(t => t > time);
			}
			return 0;
		}

		///The previous key time before time
		public float GetKeyPrevious(float time){
			if (animatedParameters != null){
				return animatedParameters.Select(p => p.GetKeyPrevious(time)).OrderBy(t => t).LastOrDefault(t => t < time);
			}
			return 0;
		}

		///A value label at time
		public string GetKeyLabel(float time){
			if (animatedParameters != null){
				if (animatedParameters.Count == 1){
					return animatedParameters[0].GetKeyLabel(time);
				}
			}
			return string.Empty;
		}

		///...
		public void SetPreWrapMode(WrapMode mode){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].SetPreWrapMode(mode);
				}
			}			
		}

		///...
		public void SetPostWrapMode(WrapMode mode){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].SetPostWrapMode(mode);
				}
			}			
		}

		///Reset all animated parameters
		public void Reset(){
			if (animatedParameters != null){
				for (var i = 0; i < animatedParameters.Count; i++){
					animatedParameters[i].Reset();
				}
			}
		}


		public override string ToString(){
			if (animatedParameters == null || animatedParameters.Count == 0){
				return "No Parameters";
			}

			return animatedParameters.Count == 1? animatedParameters[0].ToString() : "Multiple Parameters";
		}
	}
}