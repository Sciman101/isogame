uniform float z_offset_a;
uniform float z_offset_b;

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position){
		vertex_position.z += z_offset_a + z_offset_b;
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 color, Image tex, vec2 tex_pos, vec2 pixel_pos){
		vec4 this_col = Texel(tex, tex_pos);
		if (this_col.a <= 0){
			discard;
		}
		return vec4(this_col) * color;
	}
#endif