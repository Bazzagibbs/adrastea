package adrastea_renderer

import "core:math"
import "../playdate"
import "../playdate/graphics"
import "core:log"
import "core:mem"

bound_render_target: Render_Target

clear :: proc(bg_color: graphics.Color) {
    graphics.clear(bg_color)
}

draw_mesh :: proc(mesh: ^Mesh) {
    n_tris := len(mesh.index_buffer)
    for indices in mesh.index_buffer {
        point_0 := mesh.vert_buffer[indices[0]]
        point_1 := mesh.vert_buffer[indices[1]]
        point_2 := mesh.vert_buffer[indices[2]]
        
        // Transform from NDC to screen space // THIS SHOULD BE A SHADER STAGE
        // NDC is [-1, 1], x-right y-down z-forward
        ss_0 := _ndc_to_screen(point_0)
        ss_1 := _ndc_to_screen(point_1)
        ss_2 := _ndc_to_screen(point_2)
        draw_triangle(ss_0, ss_1, ss_2)
    }
}

draw_mesh_bounds :: proc(mesh: ^Mesh) {
    n_tris := len(mesh.index_buffer)
    for indices in mesh.index_buffer {
        point_0 := mesh.vert_buffer[indices[0]]
        point_1 := mesh.vert_buffer[indices[1]]
        point_2 := mesh.vert_buffer[indices[2]]
        
        // Transform from NDC to screen space // THIS SHOULD BE A SHADER STAGE
        // NDC is [-1, 1], x-right y-down z-forward
        ss_0 := _ndc_to_screen(point_0)
        ss_1 := _ndc_to_screen(point_1)
        ss_2 := _ndc_to_screen(point_2)
        draw_triangle_bounds(ss_0, ss_1, ss_2)
    }
}

draw_mesh_wireframe :: proc(mesh: ^Mesh) {
    n_tris := len(mesh.index_buffer)
    for indices in mesh.index_buffer {
        point_0 := mesh.vert_buffer[indices[0]]
        point_1 := mesh.vert_buffer[indices[1]]
        point_2 := mesh.vert_buffer[indices[2]]
        
        // Transform from NDC to screen space // THIS SHOULD BE A SHADER STAGE
        // NDC is [-1, 1], x-right y-down z-forward
        ss_0 := _ndc_to_screen(point_0)
        ss_1 := _ndc_to_screen(point_1)
        ss_2 := _ndc_to_screen(point_2)
        draw_triangle_wireframe(ss_0, ss_1, ss_2)
    }
}


@(private)
_ndc_to_screen :: proc(point: [3]f32) -> [2]i32 {
    HALF_SCREEN_X :: graphics.LCD_COLUMNS / 2
    HALF_SCREEN_Y :: graphics.LCD_ROWS / 2

    x := i32(HALF_SCREEN_X * point.x) + HALF_SCREEN_X
    y := i32(HALF_SCREEN_Y * point.y) + HALF_SCREEN_Y
    return {x, y}
}

draw_triangle :: proc(p0, p1, p2: [2]i32) {
    swap :: #force_inline proc "contextless" (a, b: [2]i32) -> ([2]i32, [2]i32) {
        return b, a
    }
    p0 := p0
    p1 := p1
    p2 := p2

    // Sort low y to high y
    if p0.y > p1.y do p0, p1 = swap(p0, p1)
    if p0.y > p2.y do p0, p2 = swap(p0, p2)
    if p1.y > p2.y do p1, p2 = swap(p1, p2)

    total_height          := f32(p2.y - p0.y)
    first_segment_height  := f32(p1.y - p0.y + 1)
    second_segment_height := f32(p2.y - p1.y + 1)
    
    for y in p0.y..<p1.y {
        // start at edge 0->2
        // end at edge 0->1
        height_progress :=  f32(y - p0.y) / total_height
        segment_progress := f32(y - p0.y) / first_segment_height
        start_x   := i32(math.lerp(f32(p0.x), f32(p2.x), height_progress))
        end_x     := i32(math.lerp(f32(p0.x), f32(p1.x), segment_progress))
        draw_span(start_x, end_x, y)
    }
    for y in p1.y..=p2.y {
        // start at edge 0->2
        // end at edge 1->2
        height_progress :=  f32(y - p0.y) / total_height
        segment_progress := f32(y - p1.y) / second_segment_height
        start_x   := i32(math.lerp(f32(p0.x), f32(p2.x), height_progress))
        end_x     := i32(math.lerp(f32(p1.x), f32(p2.x), segment_progress))
        draw_span(start_x, end_x, y)
    }
}

draw_triangle_bounds :: proc(p0, p1, p2: [2]i32) {
    min, max: [2]i32
    min.x = math.min(p0.x, p1.x, p2.x)
    min.y = math.min(p0.y, p1.y, p2.y)
    max.x = math.max(p0.x, p1.x, p2.x)
    max.y = math.max(p0.y, p1.y, p2.y)

}

draw_triangle_wireframe :: proc(p0, p1, p2: [2]i32) {
        draw_line(p0, p1)
        draw_line(p1, p2)
        draw_line(p2, p0)
}

draw_line :: proc(p0, p1: [2]i32) {
    swap :: #force_inline proc "contextless" (a, b: i32) -> (i32, i32) {
        return b, a
    }

    x0 := p0.x
    y0 := p0.y
    x1 := p1.x
    y1 := p1.y
    slope_swap := false

    if math.abs(x0 - x1) < math.abs(y0 - y1) {
        x0, y0 = swap(x0, y0)
        x1, y1 = swap(x1, y1)
        slope_swap = true
    }
    if x0 > x1 {
        x0, x1 = swap(x0, x1)
        y0, y1 = swap(y0, y1)
    }
    
    dx := x1 - x0
    dy := y1 - y0

    d_error : i32 = math.abs(dy) * 2
    error : i32 = 0

    y_step : i32 = 1 if y1 > y0 else -1
    y := y0
    for x in x0..=x1 {
        coord : [2]i32 = {y, x} if slope_swap else {x, y} // swap back if we slope swapped
        add_fragment(coord.x, coord.y)

        error += d_error
        if error > dx {
            y += y_step
            error -= dx * 2
        }
    }
}

draw_span :: #force_inline proc "contextless" (x_begin, x_end, y: i32) {
    for x in x_begin..=x_end {
        add_fragment(x, y)
    }
}


// foo := 0
add_fragment :: #force_inline proc "contextless" (x, y: i32) {
    // context = playdate.default_context()
    // set_pixel(bound_buffer, x, y, true)
    set_fragment(&bound_render_target, x, y, 1)

    // foo += 1
}


// Sets bit directly in framebuffer. Probably only want to pack bits at the end
set_pixel :: #force_inline proc "contextless" (image_buffer: []u8, x, y: i32, value: bool) {
    pixel_byte_idx := (x / 8) % graphics.LCD_ROWSIZE + y * graphics.LCD_ROWSIZE 
    pixel_bit_offset := u8(7 - x % 8)

    if value == true {
        image_buffer[pixel_byte_idx] |= 1 << pixel_bit_offset
    } else {
        image_buffer[pixel_byte_idx] &~= 1 << pixel_bit_offset
    }
}


set_fragment :: #force_inline proc "contextless" (render_target: ^Render_Target, x, y: i32, value: u8) {
    idx := (u32(x) % render_target.width) + (u32(y) * render_target.width)
    render_target.buffer[idx] = value
}

create_render_target :: proc(width, height: u32) -> Render_Target {
    rt := Render_Target {
        width = width,
        height = height,
    }

    rt.buffer = make([]u8, width * height)

    return rt
}

clear_render_target :: proc(target: ^Render_Target, value: u8) {
    mem.set(raw_data(target.buffer), value, len(target.buffer))
}

destroy_render_target :: proc(target: ^Render_Target) {
    delete(target.buffer)
}

// Copies the render target to the framebuffer
present_render_target :: proc(target: ^Render_Target) {
    unimplemented()
    // framebuffer := graphics.get_frame()
    // assert(len(target.buffer) == len(framebuffer) * 8)
    //
    // pack_bits :: #force_inline proc "contextless" (bools: u64) -> u8 {
    //     MAGIC :: 0x8040201008040201 
    //     return u8((MAGIC * bools) >> 56)
    // }
    //
    // in_idx := 0
    // for _, out_idx in framebuffer {
    //     bools: u64 = (transmute(^u64) (&target.buffer[in_idx]))^
    //     framebuffer[out_idx] = pack_bits(bools)
    //     in_idx += 8
    // }
}
