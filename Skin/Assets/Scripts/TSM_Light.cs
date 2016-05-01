using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class TSM_Light : MonoBehaviour
{
	public Material tsmMaterial;
	public Material skinMaterial;

	private RenderTexture tsmTexture;

	// TODO: Create camera during runtime
	private Camera lightCamera;

	void Start ()
	{
		lightCamera = GetComponentInChildren<Camera>();
		if (!lightCamera)
		{
			Debug.LogError("TSM light must have a camera attached.");
		}
		lightCamera.enabled = false;
	}
	
	public void RenderTSM ()
	{
		lightCamera.targetTexture = tsmTexture;
		lightCamera.RenderWithShader(tsmMaterial.shader, "");
	}

	public Matrix4x4 GetLightViewProjMatrix()
	{
		Matrix4x4 view = lightCamera.worldToCameraMatrix;
		Matrix4x4 projection = GetLightProjectionMatrix();
		Matrix4x4 light_VP = projection * view;
		return light_VP;
	}

	Matrix4x4 GetLightProjectionMatrix()
	{
		Matrix4x4 projection = lightCamera.projectionMatrix;
		projection = GL.GetGPUProjectionMatrix(projection, true);

		return projection;
	}

	public void SetTSMTexture(RenderTexture tsmTex)
	{
		tsmTexture = tsmTex;
	}
}
