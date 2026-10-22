void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    int x = int(uv.x * 320.) - 160;
    int y = int(uv.y * 240.);
    int idx;
    const vec3 palette[] = vec3[](
     vec3(0., 0., 0.),
     vec3( 0./63., 28./63., 28./63.), // l0
     vec3( 0./63., 42./63., 42./63.), // l1
     vec3( 0./63., 63./63., 63./63.), // l0+l1
     
     vec3(42./63., 0./63.,   0./63.), // l2
     vec3(32./63., 32./63., 32./63.), // l0+l2
     vec3(40./63., 40./63., 40./63.), // l1+l2
     vec3(45./63., 63./63., 63./63.), // l0+l1+l2  
     
     vec3(28./63., 0./63.,  63./63.), // l3  
     vec3(31./63., 31./63., 63./63.), // l0+l3
     vec3(31./63., 39./63., 63./63.), // l1+l3
     vec3(31./63., 63./63., 63./63.), // l0+l1+l3
     
     vec3(63./63.,  0./63., 31./63.), // l2+l3
     vec3(63./63., 31./63., 63./63.), // l0+l2+l3
     vec3(63./63., 45./63., 63./63.), // l1+l2+l3
     vec3(63./63., 63./63., 63./63.) // l1+l2+l3+l4
    );
    
    vec3 col;
    int d = 16;
    int bitmap[] = int[](        
        0x8e, 0xa6, 0xa0, 0x8a, 0xa4, 0x40, 
        0xc8, 0xee, 0xe0, 0xee, 0xc4, 0xe0,
        0xe8, 0xec, 0xa0, 0xee, 0xee, 0xa0
    );

    int x1 = (-2*iFrame % 4096) - 3000;
    int x2 = x;
    int size = 32;
    idx = 0;
    int row = y / size;
    if (row >= 2 && row < 5) {
        for (int i = 0; i < 4; i++) {
            int ofx = x2 - x1;
            if (ofx > 0) {
              ofx /= size;
              int pos = ofx / 8;
              int bit = ofx % 8;
              if (pos < 6 && ((0x80>>bit) & bitmap[6*(row-2)+pos]) != 0) {
                idx += (1 << i);
              }
            }
            x2 += x/8;
        }      
    }

    // Output to screen
    fragColor = vec4(palette[idx],1.0);
}
