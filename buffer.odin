package adrastea

Vertex_Buffer :: distinct []f32
Index_Buffer  :: distinct []i16

Accessor_Component_Type :: enum {
    float16,
    float32,
    vec2,
    vec3,
    vec4,
    int8,
    int16,
    int32,
    ivec2,
    ivec3,
    ivec4,
}

Accessor :: struct {
    count:          i16, // number of accessible fields in data
    offset:         i16, // starting index of first acccessible field
    stride:         i16, // size of an entire data element
    component_type: Accessor_Component_Type, // type of the field accessed by this accessor
}