package adrastea

import "core:runtime"

import "playdate"
import pd_b "playdate/bindings"

callback_context: runtime.Context

update_callback: Update_Callback_Proc

init :: proc "contextless" (api: ^playdate.Api) {
    playdate.load_procs(api)
    callback_context = playdate.default_context()
}


set_update_callback :: proc "contextless" (callback: Update_Callback_Proc) {
    update_callback = callback
    pd_b.system.set_update_callback(_pd_callback_internal, &callback_context)
}


@(private)
_pd_callback_internal :: proc "c" (user_data: rawptr) -> pd_b.Sys_Result {
    if update_callback == nil do return .ok

    context = (^runtime.Context)(user_data)^
    return update_callback() ? .ok : .error
}
