shader_type canvas_item;

uniform float base_y = 0.5;

uniform sampler2D waterNoise;
uniform sampler2D waterDistortionNoise;
uniform vec4 waterColor = vec4(0.368, 0.604, 0.553, 1.0);
uniform float colorCorection = 0.0;

uniform float distortionForce = 0.026;
uniform float WDBrightness = 0.386;
uniform float WDFreq = 0.39;
uniform float WDSize = 2.0;
uniform float WDSpeed = 3.658;
uniform vec2 tiling = vec2(1.164, 1.0);
uniform vec2 offSetSpeed = vec2(0.035, 0.01);

uniform float wave_frequency = 15.0;
uniform float wave_amplitude = 0.035;
uniform float wave_speed = 3.0;

void fragment() {
    vec2 uv = UV;

    float wave1 = sin(uv.x * wave_frequency - TIME * wave_speed);
    float wave2 = sin(uv.x * wave_frequency * 0.5 - TIME * wave_speed * 0.8);
    float combined_wave = (wave1 + wave2) * 0.5;
    float dynamic_water_level = base_y - (combined_wave * wave_amplitude);

    vec2 noiseUV = uv * tiling + offSetSpeed * TIME * 0.5;
    float noiseValue = texture(waterDistortionNoise, noiseUV).r;

    vec2 waterUV = uv * tiling;
    waterUV += offSetSpeed * TIME * vec2(1.0, 1.0);
    waterUV += noiseValue * distortionForce * WDSpeed;
    vec4 noiseColor = texture(waterNoise, waterUV);
    float intensity = smoothstep(WDFreq, WDSize, noiseColor.r);
    vec3 addLight = intensity * vec3(WDBrightness);

    vec4 water_surface_color = vec4(waterColor.rgb + addLight, 1.0);
    water_surface_color = mix(water_surface_color, waterColor, colorCorection);

    float water_mask = smoothstep(dynamic_water_level - 0.002, dynamic_water_level + 0.002, uv.y);

    vec4 sky_color = vec4(0.0, 0.0, 0.0, 0.0);
    COLOR = mix(sky_color, water_surface_color, water_mask);
}
