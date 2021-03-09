using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;

namespace FastOcean
{
	public class MouseOrbit : MonoBehaviour
	{
	    public Transform target = null;
	    public float distance = 10.0f;
        
	    public float xSpeed = 250.0f;
	    public float ySpeed = 200.0f;
	    public float zSpeed = 1000.0f;
	    public float maxDis = 20.0f;

        public bool checkTerrain = false;
	    public bool checkWater = false;
	    public float checkHeight = 1.0f;

        private Quaternion rot = Quaternion.identity;
	    void Start () {
            UparamAngles();
	    }


        void UparamAngles()
        {
            if (target != null && target.transform.position != transform.position)
                transform.rotation = Quaternion.LookRotation(target.transform.position - transform.position);

            rot = transform.rotation;

            Uparams(rot);
        }

        void Uparams(Quaternion rotation)
	    {
	        Vector3 position = rotation * new Vector3(0, 0, -distance) + target.position;

	        transform.rotation = rotation;
	        transform.position = position;
	    }
        
	    void Update()
	    {
			if (FOcean.instance == null)
				return;

            FOceanGrid grid = FOcean.instance.mainFG;
	        if (grid == null)
	            return;

            float dx, dy = 0.0f;

			Vector3 h;

            if (!FOcean.instance.GetSurPoint(transform.position, out h, grid))
			{
				//keep to checkheight
				h.y = transform.position.y - checkHeight;
			}
            
	        if (target && Input.GetMouseButton(1)) 
            {
                dx = Input.GetAxis("Mouse X") * xSpeed * Time.deltaTime;
                dy = -Input.GetAxis("Mouse Y") * ySpeed * Time.deltaTime;

                transform.RotateAround(target.position, Vector3.up, dx);
                transform.RotateAround(target.position, transform.right, dy);

                if (target != null && target.transform.position != transform.position)
                    transform.rotation = Quaternion.LookRotation(target.transform.position - transform.position);

                if (checkTerrain)
                {
                    if (Physics.CheckSphere(transform.position, checkHeight, 1 << FOcean.instance.layerDef.terrainlayer))
                    {
                        dx = 0f;
                        dy = 0f;
                    }
                }

                if ((!Mathf.Approximately(dx, 0f) || !Mathf.Approximately(dy, 0f)) &&
                    (transform.forward.y > -0.9f) && (transform.forward.y < 0.9f))
                   rot = transform.rotation;
	        }
	        else if (!Mathf.Approximately(Input.GetAxisRaw("Mouse ScrollWheel"), 0))
	        {
	            distance -= Input.GetAxisRaw("Mouse ScrollWheel") * zSpeed * Time.deltaTime;
	            distance = Mathf.Clamp(distance, 2, maxDis);
	        }

            Uparams(rot);


	        if (checkWater)
	        {
                if (transform.position.y < checkHeight + h.y)
                {
                    Vector3 contactP = transform.position;
                    contactP.y = checkHeight + h.y;
                    transform.position = contactP;

                    UparamAngles();
                }
            }

            if (checkTerrain)
            {
                Ray ray = new Ray(transform.position, Vector3.up);
                RaycastHit hit;
                if (Physics.Raycast(ray, out hit, Camera.main.farClipPlane, 1 << FOcean.instance.layerDef.terrainlayer))
                {
                    if (hit.distance > 0f)
                        transform.position = ray.GetPoint(hit.distance) + Vector3.up * checkHeight * 2f;

                    UparamAngles();
                }
            }
	    }

	}
}