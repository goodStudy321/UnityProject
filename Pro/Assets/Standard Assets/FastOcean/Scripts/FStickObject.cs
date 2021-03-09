using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace FastOcean
{

    [ExecuteInEditMode]
    [DisallowMultipleComponent]
    public class FStickObject : FObject
    {
        [Range(0, 1)]
        public float offsetY = 0.1f;
        [Range(0, 1)]
        public float normalY = 0.9f;

        public override void Start()
        {
            base.Start();
        }

        void LateUpdate()
        {
            if (!Application.isPlaying)
                return;

            if (FOcean.instance == null)
                return;

            FOceanGrid grid = FOcean.instance.ClosestGrid(transform);

            if (grid == null)
                return;

            if (!grid.bSimulateReady)
                return;

            Vector3 pos = transform.position;
            Vector3 outpos, normal;

            FOcean.instance.GetSurPointNormal(pos, out outpos, out normal, grid);

            transform.position = new Vector3(pos.x, outpos.y - offsetY, pos.z);
            Vector3 up = Vector3.Lerp(normal, Vector3.up, normalY);
            Vector3 Tb = Vector3.Cross(transform.forward, up);
            Vector3 Tt = Vector3.Cross(up, Tb);
            transform.rotation = Quaternion.LookRotation(Tt, up);
        }

    }
}