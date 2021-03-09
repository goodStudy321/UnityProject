//////////////////////////////////////////////////////////////
// FollowTransform.cs
//////////////////////////////////////////////////////////////
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;
using System.Text;

namespace FastOcean
{
    public class FPSController : Controller
	{
	    public Camera targetCamera = null;		// Transform to follow
	    public float speed = 100;		// Speed to follow
       
	    void Awake()
	    {
	        JoyStick.On_JoystickMove += JoystickMove;
	    }

        void OnDestroy()
        {
            JoyStick.On_JoystickMove -= JoystickMove;
        }

        public void JoystickMove(Vector2 move)
	    {
	        if (FOcean.instance == null)
	            return;

	        FOceanGrid grid = FOcean.instance.mainFG;
	        if (grid == null)
	            return;

	        float tmpSpeed = speed;
	        if (FOcean.instance != null && grid != null)
	        {
	            float ratio = grid.offsetToGridPlane / grid.baseParam.minBias.w;
	            if (ratio > 1)
	            {
	                tmpSpeed *= ratio;
	            }
	        }

	        if (move.y > 0)
	        {
	            transform.position += new Vector3(targetCamera.transform.forward.x, 0, targetCamera.transform.forward.z) * tmpSpeed * Time.deltaTime;
	        }
	        else if (move.y < 0)
	        {
	            transform.position -= new Vector3(targetCamera.transform.forward.x, 0, targetCamera.transform.forward.z) * tmpSpeed * Time.deltaTime;
	        }
	        if (move.x > 0)
	        {
	            transform.position += new Vector3(targetCamera.transform.right.x, 0, targetCamera.transform.right.z) * tmpSpeed * Time.deltaTime;
	        }
	        else if (move.x < 0)
	        {
	            transform.position -= new Vector3(targetCamera.transform.right.x, 0, targetCamera.transform.right.z) * tmpSpeed * Time.deltaTime;
	        }
	    }

	    void Update () 
	    {
	        if (FOcean.instance == null)
	            return;

	        FOceanGrid grid = FOcean.instance.mainFG;
	        if (grid == null)
	            return;

	        float tmpSpeed = speed;
	        if (FOcean.instance != null && grid != null)
	        {
	            float ratio = grid.offsetToGridPlane / grid.baseParam.minBias.w;
	            if (ratio > 1)
	            {
	                tmpSpeed *= ratio;
	            }
	        }

	        if (Input.GetKeyUp(KeyCode.R))
	        {
	            FOcean.instance.ForceReload(true);
	        }

	        if (Input.GetAxis("Vertical") > 0)
	        {
	            transform.position += new Vector3(targetCamera.transform.forward.x, 0, targetCamera.transform.forward.z) * tmpSpeed * Time.deltaTime;
	        }
	        else if (Input.GetAxis("Vertical") < 0)
	        {
	            transform.position -= new Vector3(targetCamera.transform.forward.x, 0, targetCamera.transform.forward.z) * tmpSpeed * Time.deltaTime;
	        }
	        if (Input.GetAxis("Horizontal") > 0)
	        {
	            transform.position += new Vector3(targetCamera.transform.right.x, 0, targetCamera.transform.right.z) * tmpSpeed * Time.deltaTime;
	        }
	        else if (Input.GetAxis("Horizontal") < 0)
	        {
	            transform.position -= new Vector3(targetCamera.transform.right.x, 0, targetCamera.transform.right.z) * tmpSpeed * Time.deltaTime;
	        }


	        UpdateGUI(grid);
	    }
	}
}