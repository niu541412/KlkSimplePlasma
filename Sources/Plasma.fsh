void main()
{
    // Original shader by klk: https://www.shadertoy.com/view/XsVSzW
    vec2 uv = (vec2(v_tex_coord.x, (1.0 - v_tex_coord.y) * u_aspect) - 0.5) * 8.0;
    float i0 = 1.0;
    float i1 = 1.0;
    float i2 = 1.0;
    float i4 = 0.0;

    for (int iteration = 0; iteration < 7; ++iteration) {
        vec2 r = vec2(cos(uv.y * i0 - i4 + u_time / i1),
                      sin(uv.x * i0 - i4 + u_time / i1)) / i2;
        r += vec2(-r.y, r.x) * 0.3;
        uv += r;
        i0 *= 1.93;
        i1 *= 1.15;
        i2 *= 1.7;
        i4 += 0.05 + 0.1 * u_time * i1;
    }

    float red = sin(uv.x - u_time) * 0.5 + 0.5;
    float blue = sin(uv.y + u_time) * 0.5 + 0.5;
    float green = sin((uv.x + uv.y + sin(u_time * 0.5)) * 0.5) * 0.5 + 0.5;
    gl_FragColor = vec4(red, green, blue, 1.0);
}
