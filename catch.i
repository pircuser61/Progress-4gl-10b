&scoped-define on-app catch e as Progress.Lang.AppError:
&scoped-define on-lang catch er as Progress.Lang.Error:

&glob on-cancel-return catch ce as cancelerror: undo, return. end.
&glob on-cancel-napply catch ce as cancelerror: undo, return no-apply. end.

/* callstack не работает без session:error-stack-trace = true, поэтому явно добавляю имя процедуры
&glob catch-ret-err {&on-app} return error e. end. {&on-lang} return error er. end.
*/
&glob catch-ret-err {&on-app} return error e. end. {&on-lang} if session:error-stack-trace then return error er. else return error subst('&1: &2', program-name(1), er:GetMessage(1)). end.

&glob catch-show {&on-app} message e:ReturnValue view-as alert-box title 'Ошибка'. end. {&on-lang} message er:GetMessage(1)   skip er:callstack view-as alert-box title 'Непредвиденная ошибка'. end.

&glob catch-show-napply {&on-app} message e:ReturnValue view-as alert-box. return no-apply. end. {&on-lang}  message er:GetMessage(1) view-as alert-box. return no-apply. end. 

&glob throw-error no-error. if error-status:error or error-status:num-messages > 0 then     undo, throw new progress.lang.AppError(error-status:get-message(1))
