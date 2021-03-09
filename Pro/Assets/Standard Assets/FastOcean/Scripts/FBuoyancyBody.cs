using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace FastOcean
{

	[ExecuteInEditMode]
	[DisallowMultipleComponent]
	[RequireComponent(typeof(Rigidbody))]
    public class FBuoyancyBody : FObject
    {
        public float maxAngularVelocity = 0.05f;

        public FBuoyancyPart[] m_buoyancy;
        
        private Rigidbody body = null;

        public override void Start()
        {
            m_buoyancy = GetComponentsInChildren<FBuoyancyPart>();
            body = GetComponent<Rigidbody>();

            base.Start();
        }

        void FixedUpdate()
        {
            if (FOcean.instance == null)
                return;

            if (body == null)
                body = gameObject.AddComponent<Rigidbody>();
            
            FOceanGrid grid = FOcean.instance.ClosestGrid(transform);

            if (grid == null)
                return;

            if (!grid.bSimulateReady)
                return;
            
            Vector3 force = Vector3.zero;
            Vector3 torque = Vector3.zero;

            int count = m_buoyancy.Length;

            if (count == 0)
            {
                body.Sleep();
                return;
            }
            
            for (int i = 0; i < count; i++)
            {
                FBuoyancyPart buoyancy = m_buoyancy[i];
                if (buoyancy == null) continue;
                if (!buoyancy.enabled) continue;

                buoyancy.usingGravity = body.useGravity;
                buoyancy.UpdateForces(grid, body);

                force += buoyancy.force;
                torque += buoyancy.torque;
            }
            
            body.maxAngularVelocity = maxAngularVelocity;
            body.AddForce(force);
            body.AddTorque(torque);

        }

    }
}