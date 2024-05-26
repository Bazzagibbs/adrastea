package adrastea_graphics

import pd_gfx "../playdate/graphics"

Color :: enum u8 {
    white = 0,
    black = 1,
}

Mesh :: struct {
    vertices        : #soa[]Vertex_Attributes,
    index_buffer    : [][3]i16,
}

Vertex_Attributes :: struct {
    position   : [3]f32,
    normal     : [3]f32,
    tex_coord  : [2]f32,
}


Fragment :: struct {
    depth   : f32,
    discard : bool,
    color   : Color,
    // stencil : bool,
}


Render_Target :: struct {
    support_depth       : bool,
    width               : u32,
    height              : u32,
    buffer_color        : []Color,
    buffer_depth        : []f32,
}

Render_Pass_Property_Block :: struct {
    model_mat      : matrix[4, 4]f32,
    view_mat       : matrix[4, 4]f32,
    projection_mat : matrix[4, 4]f32,
    
    mv_mat         : matrix[4, 4]f32,
    mvp_mat        : matrix[4, 4]f32,
}

Render_Pass :: struct {
    render_target : ^Render_Target,
    properties    : Render_Pass_Property_Block,
}


Shader :: struct (Mat_Props, V2F: typeid) {
    vertex_program      : proc "contextless" (vertex_input: Vertex_Attributes, render_pass_properties: ^Render_Pass_Property_Block, material_properties: ^Mat_Props) -> V2F,
    fragment_program    : proc "contextless" (vert_to_frag: V2F, render_pass_properties: ^Render_Pass_Property_Block, material_properties: ^Mat_Props) -> Fragment,
}


Shader_Cull_Backface_Flags :: bit_set[Shader_Cull_Backface_Flag; u8]
Shader_Cull_Backface_Flag  :: enum {
    Clockwise,
    Counter_Clockwise,
}

Shader_Depth_Test_Flags :: bit_set[Shader_Depth_Test_Flag; u8]
Shader_Depth_Test_Flag  :: enum {
    Less,
    Equal,
    Greater,
}

Material :: struct ($Mat_Props, $V2F: typeid) {
    shader         : ^Shader(Mat_Props, V2F),
    properties     : Mat_Props,
    cull_backface  : Shader_Cull_Backface_Flags,
    depth_test     : Shader_Depth_Test_Flags,
    depth_write    : b8,
}
