#if USE_EXPRESSIONS

using System.Collections.Generic;
using UnityEngine;
using StagPoint.Eval;

namespace Slate.Expressions{

	///
	///Collection of wrappers for expressions
	///

	public struct ExpressionCutsceneWrapper{
		public static void Wrap(Cutscene cutscene, Environment env){
			env.AddVariable("cutscene", cutscene, cutscene.GetType());
			env.AddConstant("Math", typeof(Mathf));
			env.AddConstant("Mathf", typeof(Mathf));
			env.AddConstant("Random", typeof(Random));
			env.AddConstant("Time", typeof(Time));
			env.AddConstant("Vector2", typeof(Vector2));
			env.AddConstant("Vector3", typeof(Vector3));
			env.AddConstant("Quaternion", typeof(Quaternion));

			env.AddBoundProperty("time", cutscene, "currentTime");
		}
	}

	public struct ExpressionActionClipWrapper{
		public static void Wrap(ActionClip actionClip, Environment env){
			env.AddVariable("clip", actionClip, actionClip.GetType());
		}
	}


	public struct ExpressionParameterWrapper{
		public static void Wrap(AnimatedParameter animParam, Environment env){
			env.AddVariable("parameter", animParam, animParam.GetType());
			env.AddVariable(  new BoundVariable("value", animParam.ResolvedObject(), animParam.GetMemberInfo())  );
		}
	}
}

#endif