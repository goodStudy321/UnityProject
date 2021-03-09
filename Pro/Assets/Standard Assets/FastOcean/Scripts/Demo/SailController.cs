using UnityEngine;
using System.Collections;

namespace FastOcean
{
	[DisallowMultipleComponent]
	[RequireComponent(typeof(Rigidbody))]
	public class SailController : Controller
	{
        public float engineForce = 2f;
        public float engineTorque = 2f;

        public float trailEmitRate = 1f;
	    public GameObject stem = null;
	    public GameObject trail = null;

	    private ParticleSystem[] parStem = null;
	    private ParticleSystem[] parTrail = null;

        private MeshRenderer[] meshTrail = null;

        protected Vector3 localStem;

        [HideInInspector]
        public Rigidbody rig = null;

        [HideInInspector]
        public WaypointProgressTracker traker = null;

		// Use this for initialization
	    public virtual void Start()
	    {
	        if (stem != null)
	        {
				parStem = stem.GetComponentsInChildren<ParticleSystem>();
	            localStem = stem.transform.localPosition;
	        }

	        if (trail != null)
	        {
                parTrail = trail.GetComponentsInChildren<ParticleSystem>();
                meshTrail = trail.GetComponentsInChildren<MeshRenderer>();
            }

            rig = GetComponent<Rigidbody>();

            traker = GetComponent<WaypointProgressTracker>();
		}

        public void Update()
        {
            if (FOcean.instance == null)
                return;

            FOceanGrid grid = FOcean.instance.ClosestGrid(transform);

            if (grid == null)
                return;

            UpdateGUI(grid);
        }

		// Update is called once per frame
        public void FixedUpdate()
	    {
			if (FOcean.instance == null)
				return;

            FOceanGrid grid = FOcean.instance.ClosestGrid(transform);

            if (grid == null)
                return;
            
            float trakerDamp = 1.0f;
            float trakerPlus = 0.0f;
            if (traker != null)
            {

                Vector2 thisV2 = new Vector2(transform.forward.x, transform.forward.z);
                Vector3 deltaV3 = (traker.target.position - transform.position).normalized;
                Vector2 deltaV2 = new Vector2(deltaV3.x, deltaV3.z);
                trakerPlus = Vector2.Angle(thisV2, deltaV2);
                trakerPlus /= 180f;

                trakerDamp = 1 - trakerPlus;
                trakerDamp *= trakerDamp;

                Vector3 cross = Vector3.Cross(thisV2, deltaV2);

                if (cross.z > 0)
                    trakerPlus = -trakerPlus;
                
            }

            if (rig != null)
            { 
                if (rig.mass > 0.01f)
                {
                    rig.AddForce(engineForce * new Vector3(transform.forward.x, 0, transform.forward.z) * trakerDamp);
                    rig.AddTorque(engineTorque * trakerPlus * transform.up);
                }

                if (parTrail != null)
                {
                    for (int i = 0; i < parTrail.Length; i++)
                    {
                        ParticleSystem par = parTrail[i];
                        par.gameObject.layer = FOcean.instance.layerDef.traillayer;
                        ParticleSystem.MainModule main = par.main;
                        main.startRotation = transform.rotation.eulerAngles.y * Mathf.Deg2Rad;

                        ParticleSystem.EmissionModule emission = par.emission;
                        emission.enabled = engineForce != 0 && FOcean.instance.envParam.trailer != null;
                        emission.rateOverTime = new ParticleSystem.MinMaxCurve(engineForce * trailEmitRate);
                    }
                }

                if (meshTrail != null)
                {
                    for (int i = 0; i < meshTrail.Length; i++)
                    {
                        MeshRenderer mesh = meshTrail[i];
                        mesh.gameObject.layer = FOcean.instance.layerDef.traillayer;
                    }
                }

                if (parStem != null)
	            {
                    for (int i = 0; i < parStem.Length; i++)
                    {
                        ParticleSystem par = parStem[i];
                        ParticleSystem.EmissionModule emission = par.emission;
                        emission.enabled = engineForce != 0;
                        if (emission.enabled)
                        {
                            Vector3 contactP = transform.TransformPoint(localStem);
                            Vector3 delta;
                            FOcean.instance.GetSurDisplace(contactP, out delta, grid);

                            if (delta.y > 0)
                                par.transform.position = new Vector3(contactP.x, delta.y + contactP.y, contactP.z);
                            else
                                emission.enabled = false;
                        }
                    }
	            }
	        }
        }
	}
}
