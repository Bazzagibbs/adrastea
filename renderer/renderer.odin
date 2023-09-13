package adrastea_renderer

import "core:math"
import "../playdate"
import "../playdate/graphics"
import "core:log"

clear :: proc(bg_color: graphics.Color) {
    graphics.clear(bg_color)
}



// draw_mesh :: proc(mesh: ^Mesh) {
// }

draw_line :: proc(x1, y1, x2, y2: i32) {
    swap :: #force_inline proc "contextless" (a, b: i32) -> (i32, i32) {
        return b, a
    }

    x1 := x1
    y1 := y1
    x2 := x2 
    y2 := y2

    dx := math.abs(x2 - x1)
    dy := math.abs(y2 - y1)

    slope_swap := dy > dx

    if slope_swap {
        x1, y1 = swap(x1, y1)
        x2, y2 = swap(x2, y2)
    }
    if x1 > x2 {
        x1, x2 = swap(x1, x2)
        y1, y2 = swap(y1, y2)
    }
    
    dx = math.abs(x2 - x1)
    dy = math.abs(y2 - y1)

    error: i32 = dx / 2
    
    y := y1
    y_step: i32 = 1 if y1 < y2 else -1

    for x in x1..=x2 {
        coord : [2]i32 = {y, x} if slope_swap else {x, y}
        add_fragment(coord.x, coord.y)
        error -= dy
        if error < 0 {
            y += y_step
            error += dx
        }
    }
}

add_fragment :: #force_inline proc "contextless" (x, y: i32) {
    context = playdate.default_context()
    // TODO: output to fragment buffer
    set_pixel(graphics.get_frame(), x, y, true)

}


// Sets bit directly in framebuffer. Probably want to do this after fragment shader, SIMD in one pass.
set_pixel :: #force_inline proc "contextless" (image_buffer: []u8, x, y: i32, value: bool) {
    pixel_byte_idx := (x / 8) % graphics.LCD_ROWSIZE + y * graphics.LCD_ROWSIZE 
    pixel_bit_offset := u8(7 - x % 8)

    if value == true {
        image_buffer[pixel_byte_idx] |= 1 << pixel_bit_offset
    } else {
        image_buffer[pixel_byte_idx] &~= 1 << pixel_bit_offset
    }
}
