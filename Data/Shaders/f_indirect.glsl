#version 420

uniform sampler3D voxelmap[4];
uniform int worldSize;
uniform int numVoxels;
uniform mat4 inverseMVPMatrix;
uniform sampler2D depthTex;
uniform sampler2D tanTex;
uniform sampler2D bitanTex;
uniform sampler2D normalTex;
uniform sampler2D diffuseTex;
uniform vec3 cameraPos;
in vec2 texCoord;
out vec4 glossyBuffer;

float voxelWidth[4] = float[](
	float(worldSize) / float(numVoxels),
	2.0 * float(worldSize) / float(numVoxels),
	4.0 * float(worldSize) / float(numVoxels),
	8.0 * float(worldSize) / float(numVoxels)
);

vec4 voxelConeTrace(vec3 startPos, vec3 direction, vec3 normal, float coneAngle)
{
	int curMipmap = 0;
	vec4 voxelColor = vec4(0.0);
	float sliceRadius = voxelWidth[curMipmap] * 2 * tan(coneAngle);
	while (curMipmap < 3 && sliceRadius > voxelWidth[curMipmap]){
		curMipmap++;
	}
	for (float i = voxelWidth[curMipmap]*2; i < worldSize; i += voxelWidth[curMipmap]/2)
	{
		if (curMipmap < 3 && sliceRadius > voxelWidth[curMipmap]){
			curMipmap++;
		}
		sliceRadius = i * tan(coneAngle);
		vec3 reflection = direction * i;
		if (dot(reflection, normal) > voxelWidth[curMipmap])
		{
			vec4 sampleColor = texture(voxelmap[curMipmap],(startPos+reflection+vec3(worldSize/2))/worldSize);
			float contribution = 1.0-voxelColor.a;
			voxelColor += sampleColor*contribution;
			if (voxelColor.a >= 0.99)
			{
				i = worldSize;
			}
		}
	}
	//if (voxelColor.a > 0)
	//	voxelColor.rgb /= voxelColor.a;
	return voxelColor;
}

float rand(vec2 n)
{
  return 0.5 + 0.5 * fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}

float numSamples = 5;
float coneAngle = 0.420534;
vec3 coneDirections[5] = vec3[](
    vec3(0.812218, 0.0147143, 0.583169),
    vec3(-0.576124, 0.662468, 0.478766),
    vec3(0.0543743, 0.943602, -0.326587),
    vec3(0.479263, 0.271153, -0.834735),
    vec3(-0.626188, 0.146382, -0.765807)
);

void main() {
	vec3 tangent = texture2D(tanTex,texCoord).xyz;
	if (length(tangent) < 0.01)
	{
		discard;
	}
	
	float hyperDepth = texture2D(depthTex,texCoord).r;
	vec4 screenPos = vec4(texCoord.s*2.0-1.0, texCoord.t*2.0-1.0, hyperDepth*2.0-1.0, 1.0);
	vec4 worldPos = inverseMVPMatrix * screenPos;
	worldPos /= worldPos.w;
	
	tangent = normalize(tangent*vec3(2.0)-vec3(1.0));
	vec3 bitangent = texture2D(bitanTex,texCoord).xyz;
	bitangent = normalize(bitangent*vec3(2.0)-vec3(1.0));
	vec3 normal = cross(bitangent, tangent);
	normal = normalize(normal);
	vec3 sampledNormal = texture2D(normalTex,texCoord).xyz;
	sampledNormal = normalize(sampledNormal*vec3(2.0)-vec3(1.0));
	if (dot(normal, sampledNormal) < 0)
	{
		normal *= -1.0;
	}
	
	float randAngle = 3.14 * 2 * rand(texCoord);
	mat3 randYRot = mat3(
	   cos(randAngle), 0, -sin(randAngle), // first column (not row!)
	   0,			   1, 0,			   // second column
	   sin(randAngle), 0, cos(randAngle)   // third column
	);

	mat3 tangmat;
	tangmat[0] = normalize(bitangent);
	tangmat[1] = normalize(normal);
	tangmat[2] = normalize(tangent);
	tangmat = tangmat * randYRot;
	
	vec4 voxelColor = vec4(0.0);
	float coneEndArea = 2*3.14*(1-cos(coneAngle));
	for (int i=0; i<numSamples; i++)
	{
		vec3 coneDir = tangmat * coneDirections[i];
		float contribution = coneDirections[i].y * coneEndArea;
		voxelColor += voxelConeTrace(worldPos.xyz, coneDir, normal, coneAngle) * contribution;
	}
	
	voxelColor *= 1.0;
	
	vec4 diffuse = texture2D(diffuseTex,texCoord);
	
	glossyBuffer = vec4(diffuse.rgb * voxelColor.rgb,1.0);
}