using UnityEngine;
using System.Collections;

namespace Slate.ActionClips{

	[Category("Transform")]
	[Description("Translate the actor by specified value and optionaly per second")]
	public class TranslateBy : ActorActionClip {

		[SerializeField] [HideInInspector]
		private float _length = 1;

		public Vector3 translation = new Vector3(0, 0, 2);
		public bool perSecond;
		public EaseType interpolation = EaseType.QuadraticInOut;

		private Vector3 originalPos;

		public override string info{
			get {return string.Format("Translate{0} By\n{1}", perSecond? " Per Second" : "", translation);}
		}

		public override float length{
			get {return _length;}
			set {_length = value;}
		}

		public override float blendIn{
			get {return length;}
		}

		protected override void OnEnter(){
			originalPos = actor.transform.localPosition;
		}

        // LY edit begin //

        //protected override void OnUpdate(float deltaTime){
        //	var target = originalPos + (translation * (perSecond? length : 1) );
        //	actor.transform.localPosition = Easing.Ease(interpolation, originalPos, target, deltaTime/length );
        //}

        protected override void OnUpdate(float deltaTime)
        {
            var target = originalPos + (translation * (perSecond ? length : 1));
            float tW = 0f;
            if(length == 0)
            {
                tW = 0;
            }
            else
            {
                tW = deltaTime / length;
            }
            actor.transform.localPosition = Easing.Ease(interpolation, originalPos, target, tW);
        }

        // LY edit end //

        protected override void OnReverse(){
			actor.transform.localPosition = originalPos;
		}
	}
}