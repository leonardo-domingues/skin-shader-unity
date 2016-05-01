using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class SkinHelper : MonoBehaviour
{
	public Material skinMaterial;
	public Material beckmannMaterial;
	public Material attenuationMaterial;
	public Material stretchMaterial;
	public Material irradianceMaterial;
	public Material gaussianUMaterial;
	public Material gaussianVMaterial;
	public Material alphaMaskMaterial;
	public Material shadowMaterial;
	public Material applyShadowsMaterial;

	public Light tsmLight;
	private TSM_Light lightCameraScript;

	private Camera dummyCamera;
	private int textureSize;

	private RenderTexture beckmannTexture;
	private RenderTexture attenuationTexture;
	private RenderTexture tsmTexture;
	private RenderTexture alphaTexture;
	private RenderTexture tempGaussianTexture;

	private RenderTexture irradianceTexture;
	private RenderTexture blur2Texture;
	private RenderTexture blur3Texture;
	private RenderTexture blur4Texture;
	private RenderTexture blur5Texture;
	private RenderTexture blur6Texture;

	private RenderTexture stretchTexture;
	private RenderTexture blur2StretchTexture;
	private RenderTexture blur3StretchTexture;
	private RenderTexture blur4StretchTexture;
	private RenderTexture blur5StretchTexture;
	private RenderTexture blur6StretchTexture;

	private RenderTexture shadowTexture;
	private RenderTexture irradiance2Texture;

	public bool applyShadows = true;

	void Start()
	{
		InitializeTextures();

		if (!tsmLight)
		{
			Debug.LogError("No light set for translucent shadow map.");
		}

		lightCameraScript = tsmLight.GetComponent<TSM_Light>();
		if (!lightCameraScript)
		{
			Debug.LogError("No TSM_Light script attached to TSM light.");
		}
		lightCameraScript.SetTSMTexture(tsmTexture);

		// Create a dummy camera. This will be used for calling RenderWithShader with a 
		// specific clear color, without having to change the main camera
		dummyCamera = GetComponent<Camera>();
		if (!dummyCamera)
		{
			dummyCamera = gameObject.AddComponent<Camera>();
		}

		Graphics.Blit(beckmannTexture, beckmannTexture, beckmannMaterial);
		Graphics.Blit(attenuationTexture, attenuationTexture, attenuationMaterial);

		SetUniforms();
	}

	void InitializeTextures()
	{
		textureSize = skinMaterial.GetTexture("_MainTex").width;

		beckmannTexture = new RenderTexture(512, 512, 24, RenderTextureFormat.R8);
		attenuationTexture = new RenderTexture(512, 512, 24, RenderTextureFormat.R8);
		tsmTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
		alphaTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.R8);
		tempGaussianTexture = new RenderTexture(textureSize, textureSize, 24);

		irradianceTexture = new RenderTexture(textureSize, textureSize, 24);
		blur2Texture = new RenderTexture(textureSize, textureSize, 24);
		blur3Texture = new RenderTexture(textureSize, textureSize, 24);
		blur4Texture = new RenderTexture(textureSize, textureSize, 24);
		blur5Texture = new RenderTexture(textureSize, textureSize, 24);
		blur6Texture = new RenderTexture(textureSize, textureSize, 24);

		stretchTexture = new RenderTexture(textureSize, textureSize, 24);
		blur2StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		blur3StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		blur4StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		blur5StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		blur6StretchTexture = new RenderTexture(textureSize, textureSize, 24);

		if (applyShadows)
		{
			shadowTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.R8);
			irradiance2Texture = new RenderTexture(textureSize, textureSize, 24);
		}
	}

	void SetUniforms()
	{
		skinMaterial.SetTexture("_BeckmannTex", beckmannTexture);
		skinMaterial.SetTexture("_IrradianceTex", applyShadows ? irradiance2Texture : irradianceTexture);
		skinMaterial.SetTexture("_AttenuationTex", attenuationTexture);
		skinMaterial.SetTexture("_Blur2Tex", blur2Texture);
		skinMaterial.SetTexture("_Blur3Tex", blur3Texture);
		skinMaterial.SetTexture("_Blur4Tex", blur4Texture);
		skinMaterial.SetTexture("_Blur5Tex", blur5Texture);
		skinMaterial.SetTexture("_Blur6Tex", blur6Texture);
		skinMaterial.SetTexture("_StretchTex", stretchTexture);
		skinMaterial.SetTexture("_Blur6StretchTex", blur6StretchTexture);
		skinMaterial.SetTexture("_AlphaMaskTex", alphaTexture);
		skinMaterial.SetFloat("_TextureSize", textureSize);
		skinMaterial.SetFloat("_StretchScale", 0.001f);
		skinMaterial.SetMatrix("_LightViewProj", lightCameraScript.GetLightViewProjMatrix());

		gaussianUMaterial.SetFloat("_TextureSize", textureSize);
		gaussianVMaterial.SetFloat("_TextureSize", textureSize);

		alphaMaskMaterial.SetTexture("_StretchTex", stretchTexture);
		alphaMaskMaterial.SetTexture("_Blur2StretchTex", blur2StretchTexture);
		alphaMaskMaterial.SetTexture("_Blur3StretchTex", blur3StretchTexture);
		alphaMaskMaterial.SetTexture("_Blur4StretchTex", blur4StretchTexture);
		alphaMaskMaterial.SetTexture("_Blur5StretchTex", blur5StretchTexture);
		alphaMaskMaterial.SetTexture("_Blur6StretchTex", blur6StretchTexture);
	}

	RenderTexture ComputeShadows()
	{		
		if (applyShadows)
		{
			// Compute texture space shadow map from the TSM to apply shadows to the irradiance texture
			dummyCamera.targetTexture = shadowTexture;
			dummyCamera.RenderWithShader(shadowMaterial.shader, "");
			gaussianUMaterial.SetFloat("_GaussianWidth", 1.0f);
			gaussianVMaterial.SetFloat("_GaussianWidth", 1.0f);
			gaussianUMaterial.SetTexture("_StretchTex", null);
			Graphics.Blit(shadowTexture, tempGaussianTexture, gaussianUMaterial);
			gaussianVMaterial.SetTexture("_StretchTex", null);
			Graphics.Blit(tempGaussianTexture, shadowTexture, gaussianVMaterial);

			// Apply shadows to irradiance texture
			applyShadowsMaterial.SetTexture("_ShadowTex", shadowTexture);
			applyShadowsMaterial.SetTexture("_DiffuseTex", skinMaterial.GetTexture("_MainTex"));
			applyShadowsMaterial.SetFloat("_Mix", skinMaterial.GetFloat("_Mix"));
			Graphics.Blit(irradianceTexture, irradiance2Texture, applyShadowsMaterial);

			return irradiance2Texture;
		}

		return irradianceTexture;
	}

	void Update()
	{
		// Setup dummy camera
		dummyCamera.CopyFrom(Camera.main);
		dummyCamera.enabled = false;
		dummyCamera.backgroundColor = new Color(0.0f, 0.0f, 0.0f, 0.0f); 

		// Compute TSM
		lightCameraScript.RenderTSM();
		skinMaterial.SetTexture("_TSMTex", tsmTexture);

		// Compute diffuse irradiance
		Vector3 lightPos = tsmLight.transform.position;
		Vector4 tsmLightWorldPos = new Vector4(lightPos.x, lightPos.y, lightPos.z, 1.0f);
		skinMaterial.SetVector("_TsmLightPosWorld", tsmLightWorldPos);
		dummyCamera.targetTexture = irradianceTexture;
		dummyCamera.RenderWithShader(irradianceMaterial.shader, "");

		//  Set uniforms for the gaussian convolution materials
		float blurStepScale = skinMaterial.GetFloat("_BlurStepScale");
		gaussianUMaterial.SetFloat("_BlurStepScale", blurStepScale);
		gaussianVMaterial.SetFloat("_BlurStepScale", blurStepScale);

		// Apply shadows, if enabled
		RenderTexture finalIrradianceTexture = ComputeShadows();

		// Compute stretch textures
		dummyCamera.targetTexture = stretchTexture;
		dummyCamera.RenderWithShader(stretchMaterial.shader, "");

		// Compute convolutions. Since the first convolution kernel is very narrow, 
		// we can use the irradiance texture as the first convolution
		float variance1 = skinMaterial.GetVector("_Blur1WV").w;
		float variance2 = skinMaterial.GetVector("_Blur2WV").w;
		GaussianBlur(variance2 - variance1, finalIrradianceTexture, blur2Texture, stretchTexture, blur2StretchTexture);
		float variance3 = skinMaterial.GetVector("_Blur3WV").w;
		GaussianBlur(variance3 - variance2, blur2Texture, blur3Texture, blur2StretchTexture, blur3StretchTexture);
		float variance4 = skinMaterial.GetVector("_Blur4WV").w;
		GaussianBlur(variance4 - variance3, blur3Texture, blur4Texture, blur3StretchTexture, blur4StretchTexture);
		float variance5 = skinMaterial.GetVector("_Blur5WV").w;
		GaussianBlur(variance5 - variance4, blur4Texture, blur5Texture, blur4StretchTexture, blur5StretchTexture);
		float variance6 = skinMaterial.GetVector("_Blur6WV").w;
		GaussianBlur(variance6 - variance5, blur5Texture, blur6Texture, blur5StretchTexture, blur6StretchTexture);

		// Compute alpha mask used to remove seams caused by connected areas being disconnected in texture space
		Graphics.Blit(alphaTexture, alphaTexture, alphaMaskMaterial);
	}

	void GaussianBlur(float variance, RenderTexture source, RenderTexture destination, 
		RenderTexture sourceStretch, RenderTexture destinationStretch)
	{
		// The gaussian width is the standard deviation (square root of the variance)
		float width = Mathf.Sqrt(variance);
		gaussianUMaterial.SetFloat("_GaussianWidth", width);
		gaussianVMaterial.SetFloat("_GaussianWidth", width);

		// Blur stretch texture
		gaussianUMaterial.SetTexture("_StretchTex", null); // No stretch, default = white texture
		Graphics.Blit(sourceStretch, tempGaussianTexture, gaussianUMaterial);
		gaussianVMaterial.SetTexture("_StretchTex", null); // No stretch, default = white texture
		Graphics.Blit(tempGaussianTexture, destinationStretch, gaussianVMaterial);

		// Blur source texture
		gaussianUMaterial.SetTexture("_StretchTex", destinationStretch);
		Graphics.Blit(source, tempGaussianTexture, gaussianUMaterial);
		gaussianVMaterial.SetTexture("_StretchTex", destinationStretch);
		Graphics.Blit(tempGaussianTexture, destination, gaussianVMaterial);
	}
}
