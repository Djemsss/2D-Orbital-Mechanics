shader_type canvas_item;

render_mode unshaded;

uniform float speed : hint_range(0.0, 2.0) = 0.08;
uniform float intensity : hint_range(0.0, 0.05) = 0.008;
uniform float haze_strength : hint_range(0.0, 1.0) = 0.5;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

//////////////////////////////////////////
//  Smooth fractal noise (fbm)
//////////////////////////////////////////
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453123);
}

float smooth_noise(vec2 uv) {
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    float bl = noise(id);
    float br = noise(id + vec2(1.0, 0.0));
    float tl = noise(id + vec2(0.0, 1.0));
    float tr = noise(id + vec2(1.0, 1.0));
    vec2 u = lv * lv * (3.0 - 2.0 * lv);
    return mix(mix(bl, br, u.x), mix(tl, tr, u.x), u.y);
}

// Fractal Brownian Motion — smooth, layered noise
float fbm(vec2 uv) {
    float total = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        total += smooth_noise(uv) * amp;
        uv *= 2.0;
        amp *= 0.5;
    }
    return total;
}

//////////////////////////////////////////
//  Main
//////////////////////////////////////////
void fragment() {
    vec2 uv = UV;
    float t = TIME * speed;

    // Use fbm for smooth, natural distortion
    float n1 = fbm(uv * 8.0 + vec2(t * 0.3, t * 0.2));
    float n2 = fbm(uv * 8.0 - vec2(t * 0.25, t * 0.35));

    // Centered offset — no drift, no grid pattern
    vec2 offset = vec2(n1 - 0.5, n2 - 0.5) * intensity * 2.0;

    // Apply distortion
    vec4 tex = texture(TEXTURE, uv + offset);

    // Add soft edge haze glow
    float haze = smoothstep(0.5, 1.0, length(UV - vec2(0.5)));
    tex.rgb += haze * haze_strength * tex.rgb;

    COLOR = tex * tint_color;
}
