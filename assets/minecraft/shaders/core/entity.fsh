#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
in vec4 vertexPerFaceColorBack;
in vec4 vertexPerFaceColorFront;
#else
in vec4 vertexColor;
#endif

#ifndef EMISSIVE
in vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
in vec4 overlayColor;
#endif

in vec2 texCoord0;


///////////////////////////////////////////////
////// DEEP CREEPERS MODIFICATIONS START //////

const vec4 DC_MarkerPixelTop = vec4(255.0, 152.0, 243.0, 161.0);
const vec4 DC_MarkerPixelBottom = vec4(247.0, 66.0, 254.0, 43.0);

vec4 DC_SampleMarkerPixel(vec2 uv) {
    return round(texture(Sampler0, uv) * 255);
}

in float DC_blockYPosition;

//////  DEEP CREEPERS MODIFICATIONS END  //////
///////////////////////////////////////////////


out vec4 fragColor;

void main() {

    ///////////////////////////////////////////////
    ////// DEEP CREEPERS MODIFICATIONS START //////

    vec2 offsetTexCoord = texCoord0;

    if (
        DC_SampleMarkerPixel(vec2(0.999, 0.0)) == DC_MarkerPixelTop &&
        DC_SampleMarkerPixel(vec2(0.999, 0.999)) == DC_MarkerPixelBottom
    ) {
        // We are rendering a creeper, so scale the UVs down
        offsetTexCoord /= 2.0;

        if (DC_blockYPosition < 0.0) {
            // Use deepslate texture
            offsetTexCoord += vec2(0.5, 0.0);
        }
        else if (DC_blockYPosition < 60.0) {
            // Use stone texture
            offsetTexCoord += vec2(0.0, 0.5);
        }
        // Otherwise, use vanilla texture
    }

    // vanilla line: vec4 color = texture(Sampler0, texCoord0);
    vec4 color = texture(Sampler0, offsetTexCoord);

    //////  DEEP CREEPERS MODIFICATIONS END  //////
    ///////////////////////////////////////////////


#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif

#ifdef PER_FACE_LIGHTING
    vec4 faceVertexColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
#else
    vec4 faceVertexColor = vertexColor;
#endif

#ifdef DISSOLVE
    if (faceVertexColor.a < texture(DissolveMaskSampler, texCoord0).a) {
        discard;
    }
    // The dissolve effect entirely replaces translucency
    faceVertexColor.a = 1.0;
#endif

    color *= faceVertexColor * ColorModulator;
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
#ifndef EMISSIVE
    color *= lightMapColor;
#endif

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
