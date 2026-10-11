shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // The color you want to glow
uniform float glow_intensity : hint_range(1.0, 20.0) = 5.0;       // How bright it glows
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;             // Sensitivity of color matching 

void fragment() {
vec4 tex_color = texture(TEXTURE, UV);

// Calculate how close the pixel color is to our target glow color
float color_distance = distance(tex_color.rgb, glow_color.rgb);

if (color_distance < tolerance && tex_color.a > 0.0) {
// Multiply RGB values to blow past the HDR threshold and trigger bloom
COLOR = vec4(tex_color.rgb * glow_intensity, tex_color.a);
} else {
COLOR = tex_color;
}

}