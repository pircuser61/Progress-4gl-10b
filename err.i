&GLOB err-ret{1} on error undo _tr{1}, return on stop undo _tr{1}, return on endkey undo _tr{1}, return on quit undo _tr{1}, return 

&GLOB err-ret-error{1} on error undo _tr{1}, return error on stop undo _tr{1}, return error on endkey undo _tr{1}, return error on quit undo _tr{1}, return error

&GLOB err-ret-err{1}   on error undo _tr{1}, return error   on stop undo _tr{1}, return error subst('STOP: &1', program-name(1))   on endkey undo _tr{1}, return error   on quit undo _tr{1}, return error

&GLOB err-leave{1} on error undo _tr{1}, leave _tr{1} on stop undo _tr{1}, leave _tr{1} on endkey undo _tr{1}, leave _tr{1} on quit undo _tr{1},  leave _tr{1}

&GLOB err-next{1} on error undo _tr{1}, next _tr{1} on stop undo _tr{1}, next _tr{1} on endkey undo _tr{1}, next _tr{1} on quit undo _tr{1}, next _tr{1}
 
&GLOB err-ret-napply{1} on error undo _tr{1}, return no-apply on stop undo _tr{1}, return no-apply on endkey  undo _tr{1}, return no-apply on quit undo _tr{1}, return no-apply

&GLOB err-throw{1}  on error undo, throw  on stop undo _tr{1}, return error subst('STOP: &1', program-name(1))  on endkey undo _tr{1}, return error  on quit undo _tr{1},  return error 

&GLOB err-throw-napply{1} on error undo, throw on stop undo _tr{1}, return no-apply on endkey  undo _tr{1}, return no-apply on quit undo _tr{1}, return no-apply

&GLOB err-ret-error-cancel{1} on error undo _tr{1}, return error on stop undo _tr{1}, return error on quit undo _tr{1}, return error on endkey undo _tr{1}, return error new cancelerror()


&GLOB import on endkey undo, leave on error undo, throw on stop undo, return error on quit undo, return error  
