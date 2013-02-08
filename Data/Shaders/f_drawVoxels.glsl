#version 420

uniform layout ( binding = 3, r32ui ) coherent volatile uimage3D voxelmap;
in vec4 worldPos;
out vec4 fragColor;

uint voxelGridSize = 16;
uint numVoxels = 128;

vec4 convRGBA8ToVec4(uint val) {
	return vec4 (float((val&0x000000FF)), float((val&0x0000FF00)>>8U), float((val&0x00FF0000)>>16U), float((val&0xFF000000)>>24U));
}

void main() {
	uint xPos = uint(((worldPos.x+0.01+voxelGridSize/2)/voxelGridSize)*(numVoxels));
	uint yPos = uint(((worldPos.y+0.01+voxelGridSize/2)/voxelGridSize)*(numVoxels));
	uint zPos = uint(((worldPos.z+0.01+voxelGridSize/2)/voxelGridSize)*(numVoxels));
	ivec3 voxelPos = ivec3(xPos, yPos, zPos);
	uvec4 voxelValues = imageLoad(voxelmap,voxelPos);
	vec4 voxelColor = convRGBA8ToVec4(voxelValues.r);
	
	if (voxelColor.a < 1.0) 
		discard;
	
	fragColor = vec4(voxelColor.rgb / vec3(255.0),1.0);
} 