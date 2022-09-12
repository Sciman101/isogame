#ifdef PIXEL
	vec4 effect(vec4 color, Image tex, vec2 tex_pos, vec2 pixel_pos){
		vec4 c = Texel(tex, tex_pos);
		return vec4(c.r,c.r,c.r,c.a) * color;
	}
#endif