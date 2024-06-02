// TODO: 
// - Create V2F buffer
// - Populate V2F buffer from vertex shader
// - In rasterize_triangle: 
//      - Stencil test
//      - Depth test
//      - Barycentric interpolation on V2F tris
//      - Pass interpolated V2F into fragment shader
//      - Check "discard" on fragment output
//      - Write to render target

package adrastea_graphics

import "core:math"
import "core:math/linalg"
import "../playdate/graphics"
import "core:log"
import "core:mem"


// Allocates using temp allocator
draw_mesh :: proc(render_pass: ^Render_Pass, mesh: ^Mesh, material: ^Material($Mat_Props)) {
    if material.depth_test == .Never do return

    // Vertex shader output buffer
    context.allocator = context.temp_allocator
    v2f_buffer := make([]Vertex_To_Fragment, len(mesh.vertices))
    defer delete(v2f_buffer)

    // Apply vertex shader
    for vert_in, i in mesh.vertices {
        v2f := material.shader.vertex_program(vert_in, &render_pass.properties, &material.properties)
        v2f_buffer[i] = v2f
    }

    // Rasterize triangles
    for indices in mesh.index_buffer {
        a_v2f := v2f_buffer[indices[0]]
        b_v2f := v2f_buffer[indices[1]]
        c_v2f := v2f_buffer[indices[2]]

        rasterize_triangle(a_v2f, b_v2f, c_v2f, render_pass, material)
    }

}


@(private)
_ndc_to_screen :: #force_inline proc "contextless" (ndc: [3]f32, width, height: f32) -> [2]i32 {
    return {
        i32((ndc.x + 1) * 0.5 * width),
        i32((ndc.y + 1) * 0.5 * height)
    }
}

@(private)
_barycentric :: #force_inline proc "contextless" (screen_point, a, b, c: [2]i32) -> [3]f32 {
    u := linalg.cross([3]f32{f32(c.x - a.x), f32(b.x - a.x), f32(a.x - screen_point.x)}, 
                           [3]f32{f32(c.y - a.y), f32(b.y - a.y), f32(a.y - screen_point.y)})
    
    if math.abs(u.z) < 1 do return {-1, 1, 1} // degenerate triangle
    return [3]f32 { 1 - (u.x + u.y) / u.z, u.y / u.z, u.x / u.z }
}


@(private)
_idx_from_2d :: #force_inline proc "contextless" (x, y: i32, width: u32) -> i32 {
    return (i32)(width) * y + x
}

@(private)
_test_depth :: #force_inline proc "contextless" (depth_test_flag: Shader_Depth_Test_Flag, target: ^Render_Target, x, y: i32, frag_depth: f32) -> bool {
    depth := target.buffer_depth[_idx_from_2d(x, y, target.width)]

    switch depth_test_flag {
        case .GEqual   : return frag_depth >= depth
        case .LEqual   : return frag_depth <= depth
        case .Greater  : return frag_depth >  depth
        case .Less     : return frag_depth <  depth
        case .Equal    : return frag_depth == depth
        case .NotEqual : return frag_depth != depth
        case .Always   : return true
        case .Never    : return false
    }

    return false
}


rasterize_triangle :: proc (a, b, c: Vertex_To_Fragment, render_pass: ^Render_Pass, material: ^Material($Mat_Props)) {
    swap :: #force_inline proc "contextless" (a, b: $T) -> (b_out, a_out: T) {
        return b, a
    }
    

    // Calculate triangle normal
    face_normal := linalg.cross(b.position.xyz - a.position.xyz, c.position.xyz - a.position.xyz)

    rt_width          := (f32)(render_pass.render_target.width)
    rt_height         := (f32)(render_pass.render_target.height)
    rt_width_inverse  := 1 / rt_width
    rt_height_inverse := 1 / rt_height
    i_rt_width        := (i32)(render_pass.render_target.width)
    i_rt_height       := (i32)(render_pass.render_target.height)
    

    // Perspective division
    ndcs := [3][3]f32 {
        a.position.xyz / a.position.w,
        b.position.xyz / b.position.w,
        c.position.xyz / c.position.w,
    }

    v2fs := [3]Vertex_To_Fragment {a, b, c}

    screens := [3][2]i32 {
        _ndc_to_screen(ndcs[0], rt_width, rt_height),
        _ndc_to_screen(ndcs[1], rt_width, rt_height),
        _ndc_to_screen(ndcs[2], rt_width, rt_height),
    }

    // Generate fragments
    
    // Sort low y to high y
    if ndcs[0].y > ndcs[1].y {
        ndcs[0], ndcs[1]       = swap(ndcs[0], ndcs[1])
        v2fs[0], v2fs[1]       = swap(v2fs[0], v2fs[1])
        screens[0], screens[1] = swap(screens[0], screens[1])
    }
    if ndcs[0].y > ndcs[2].y {
        ndcs[0], ndcs[2] = swap(ndcs[0], ndcs[2])
        v2fs[0], v2fs[2] = swap(v2fs[0], v2fs[2])
        screens[0], screens[2] = swap(screens[0], screens[2])
    }
    if ndcs[1].y > ndcs[2].y {
        ndcs[1], ndcs[2] = swap(ndcs[1], ndcs[2])
        v2fs[1], v2fs[2] = swap(v2fs[1], v2fs[2])
        screens[1], screens[2] = swap(screens[1], screens[2])
    }

    total_height          := f32(screens[2].y - screens[0].y)
    first_segment_height  := f32(screens[1].y - screens[0].y + 1)
    second_segment_height := f32(screens[2].y - screens[1].y + 1)


    // should be TIGHT LOOP
    // LOWER HALF
    for y in screens[0].y ..< screens[1].y {
        if y < 0 || y >= i_rt_height do continue
        height_progress  := f32(y - screens[0].y) / total_height
        segment_progress := f32(y - screens[0].y) / first_segment_height
        start_x          := i32(math.lerp(f32(screens[0].x), f32(screens[2].x), height_progress))
        end_x            := i32(math.lerp(f32(screens[0].x), f32(screens[1].x), segment_progress))

        per_fragment_lower:
        for x in start_x ..= end_x {
            if x < 0 || x >= i_rt_height do continue
          
            bary := _barycentric({x, y}, screens[0], screens[1], screens[2])
            interp_pos := v2fs[0].position * bary[0] + v2fs[1].position * bary[1] + v2fs[2].position * bary[2]

            // Early depth test - too expensive to do late depth test
            if render_pass.render_target.support_depth {
                if !_test_depth(material.depth_test, render_pass.render_target, x, y, interp_pos.z) {
                    continue per_fragment_lower
                }
            }
            
            // Interpolators
            interp_v2f := Vertex_To_Fragment {
                position    = interp_pos,
                tex_coord   = v2fs[0].tex_coord * bary[0] + v2fs[1].tex_coord * bary[1] + v2fs[2].tex_coord * bary[2],
                user_scalar = v2fs[0].user_scalar * bary[0] + v2fs[1].user_scalar * bary[1] + v2fs[2].user_scalar * bary[2],
            }

            frag_out := material.shader.fragment_program(interp_v2f, face_normal, &render_pass.properties, &material.properties)
            render_target_set_fragment(render_pass.render_target, u32(x), u32(y), interp_pos.z, frag_out)
        }
    }

    // UPPER HALF
    for y in screens[1].y ..= screens[2].y {
        if y < 0 || y >= i_rt_height do continue
        
        height_progress  := f32(y - screens[0].y) / total_height
        segment_progress := f32(y - screens[1].y) / second_segment_height
        start_x          := i32(math.lerp(f32(screens[0].x), f32(screens[2].x), height_progress))
        end_x            := i32(math.lerp(f32(screens[1].x), f32(screens[2].x), segment_progress))

        per_fragment_upper:
        for x in start_x ..= end_x {
            if x < 0 || x >= i_rt_height do continue
          
            bary := _barycentric({x, y}, screens[0], screens[1], screens[2])
            interp_pos := v2fs[0].position * bary[0] + v2fs[1].position * bary[1] + v2fs[2].position * bary[2]

            // Early depth test - too expensive to do late depth test
            if render_pass.render_target.support_depth {
                if !_test_depth(material.depth_test, render_pass.render_target, x, y, interp_pos.z) {
                    continue per_fragment_upper
                }
            }
            
            // Interpolators
            interp_v2f := Vertex_To_Fragment {
                position    = interp_pos,
                tex_coord   = v2fs[0].tex_coord * bary[0] + v2fs[1].tex_coord * bary[1] + v2fs[2].tex_coord * bary[2],
                user_scalar = v2fs[0].user_scalar * bary[0] + v2fs[1].user_scalar * bary[1] + v2fs[2].user_scalar * bary[2],
            }

            frag_out := material.shader.fragment_program(interp_v2f, face_normal, &render_pass.properties, &material.properties)
            render_target_set_fragment(render_pass.render_target, u32(x), u32(y), interp_pos.z, frag_out)
        }
    }

    
}


render_target_create :: proc(width, height: u32, support_depth: bool) -> Render_Target {
    rt := Render_Target {
        support_depth = support_depth,
        width         = width,
        height        = height,
    }

    rt.buffer_color = make([]Color, width * height)

    if (support_depth) {
        rt.buffer_depth = make([]f32, width * height)
    }

    return rt
}

render_target_presentable_create :: proc(support_depth: bool) -> Render_Target {
    return render_target_create(graphics.LCD_ROWSIZE * 8, graphics.LCD_ROWS, support_depth)
}


render_target_destroy :: proc(render_target: ^Render_Target) {
    delete(render_target.buffer_color)

    if (render_target.support_depth) {
        delete(render_target.buffer_depth)
    }
}

render_target_set_fragment :: #force_inline proc "contextless" (target: ^Render_Target, x, y: u32, depth: f32, fragment: Fragment) {
    if fragment.discard || 
        x < 0 || x >= target.width ||
        y < 0 || y >= target.height {
        return
    }

    idx := _idx_from_2d(i32(x), i32(y), target.width)
    target.buffer_color[idx] = fragment.color
    if target.support_depth {
        target.buffer_depth[idx] = depth
    }
    
}


render_target_clear :: proc(target: ^Render_Target, value: Color) {
    mem.set(raw_data(target.buffer_color), transmute(u8)(value), len(target.buffer_color))

    if (target.support_depth) {
        mem.set(raw_data(target.buffer_depth), 0, len(target.buffer_depth))
    }
}


// Copies the render target (8 bit) to the framebuffer (1 bit)
render_target_present :: proc(target: ^Render_Target) {
    framebuffer := graphics.get_frame()
    assert(len(target.buffer_color) == len(framebuffer) * 8)

    // Can I do this in 32 bit, then OR them together?
    // Not worth thinking about until I can profile on hardware
    pack_bits :: #force_inline proc "contextless" (bools: u64) -> u8 {
        MAGIC :: 0x8040201008040201 
        return u8((MAGIC * bools) >> 56)
    }

    in_idx := 0
    for _, out_idx in framebuffer {
        bools: u64 = (transmute(^u64) (&target.buffer_color[in_idx]))^
        framebuffer[out_idx] = pack_bits(bools)
        in_idx += 8
    }
}


render_pass_create :: proc(target: ^Render_Target) -> Render_Pass {
    return Render_Pass {
        render_target = target,
        // properties = default,
    }
}


render_pass_destroy :: proc(render_pass: ^Render_Pass) {
    // Nothing to clean up yet.
}



