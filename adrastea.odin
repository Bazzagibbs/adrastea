package adrastea

import "core:runtime"

import "playdate"
import pd_sys "playdate/system"

callback_context: runtime.Context

update_callback: Update_Callback_Proc

init :: proc "contextless" (api: ^playdate.Api) {
    playdate.load_procs(api)
    callback_context = playdate.default_context()
}


set_update_callback :: proc "contextless" (callback: Update_Callback_Proc) {
    update_callback = callback
    pd_sys.set_update_callback(_pd_callback_internal, &callback_context)
}


@(private)
_pd_callback_internal :: proc "c" (user_data: rawptr) -> i32 {
    if update_callback == nil do return 0

    context = (^runtime.Context)(user_data)^
    return update_callback() ? 1 : 0
}
