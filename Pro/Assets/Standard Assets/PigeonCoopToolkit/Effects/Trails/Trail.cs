using UnityEngine;

namespace PigeonCoopToolkit.Effects.Trails
{
    [AddComponentMenu("Pigeon Coop Toolkit/Effects/Trail")]
    public class Trail : TrailRenderer_Base
    {
        public float MinVertexDistance = 0.1f;
        private Vector3 _lastPosition;
        private float _distanceMoved;

        protected override void Start()
        {
            base.Start();
            _lastPosition = _t.position;
        }

        protected override void LateUpdate()
        {
            if(_emit)
            {
                _distanceMoved += Vector3.Distance(_t.position, _lastPosition);

                if(_distanceMoved >= MinVertexDistance)
                {
                    AddPoint(new PCTrailPoint(), _lastPosition);
                    _distanceMoved = 0;
                }
                _lastPosition = _t.position;
            }

            base.LateUpdate();
        }

        protected override void OnStartEmit()
        {
            _lastPosition = _t.position;
            _distanceMoved = 0;
        }

        protected override void Reset()
        {
            base.Reset();
            MinVertexDistance = 0.1f;
        }
    }
}
