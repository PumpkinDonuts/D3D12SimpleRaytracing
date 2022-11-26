#ifndef NUM_DIR_LIGHTS
    #define NUM_DIR_LIGHTS 1
#endif

// Include structures and functions for lighting.
#include "Lighting.hlsl"

// Constant data that varies per frame.
cbuffer cbPerObject : register(b0) {
    float4x4 gWorld;
};

cbuffer cbMaterial : register(b1) {
	float4 gDiffuseAlbedo;
    float gReflectance;
    float  gShininess;
	float4x4 gMatTransform;
};

// Constant data that varies per material.
cbuffer cbPass : register(b2) {
    float4x4 gView;
    float4x4 gInvView;
    float4x4 gProj;
    float4x4 gInvProj;
    float4x4 gViewProj;
    float4x4 gInvViewProj;
    float3 gEyePosW;
    float cbPerObjectPad1;
    float2 gRenderTargetSize;
    float2 gInvRenderTargetSize;
    float gNearZ;
    float gFarZ;
    float gTotalTime;
    float gDeltaTime;
    float4 gAmbientLight;

    Light gLights[MaxLights];
};

cbuffer cbSphere : register(b3) {
    Sphere gSpheres[10];
};

cbuffer cbPlane : register(b4) {
    Plane gPlanes[1];
};

struct VertexIn {
	float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
};

struct VertexOut {
	float4 PosH    : SV_POSITION;
    float3 PosW    : POSITION;
    float3 NormalW : NORMAL;
};

VertexOut VS(VertexIn vin) {
	VertexOut vout = (VertexOut)0.0f;
	
    // Transform to world space.
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosW = posW.xyz;

    // Assumes nonuniform scaling; otherwise, need to use inverse-transpose of world matrix.
    vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);

    // Transform to homogeneous clip space.
    vout.PosH = mul(posW, gViewProj);

    return vout;
}

float4 PS(VertexOut pin) : SV_Target {
    // Interpolating normal can unnormalize it, so renormalize it.
    pin.NormalW = normalize(pin.NormalW);

    // Vector from point being lit to eye. 
    float3 toEyeW = normalize(gEyePosW - pin.PosW);

    // Indirect lighting.
    float4 ambient = gAmbientLight*gDiffuseAlbedo;

    Material mat = { gDiffuseAlbedo, gReflectance, gShininess };
    //float3 tracedLight = TraceRay(gEyePosW, -toEyeW, gLights[0], gSpheres, mat);
    //float3 tracedLight = ReflectTraceRay(gEyePosW, -toEyeW, gLights[0], gSpheres, mat, 2);
    float3 tracedLight = ReflectTraceRay(gEyePosW, -toEyeW, gLights[0], gSpheres, gPlanes[0], mat, 2);

    float4 litColor;
    litColor.rgb = tracedLight;

    // Common convention to take alpha from diffuse material.
    litColor.a = gDiffuseAlbedo.a;

    return litColor;
}


