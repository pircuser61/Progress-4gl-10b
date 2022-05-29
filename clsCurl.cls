{err.i}
{catch.i}


class clsCurl implements iHttpRequest:
    /*
       Разницы между ' --stderr ' + fileErrors 
        и ' 2> ' + fileErrors пока не заметил,
        наверн второй вариант получше ... отловит не только вывод curla
    */
    
    /* Пара слов об обработке ошибок:  
    
        -f не гарантирует возврат ошибки если HTTP не 200
        запуск c  --write-out "~%~{response_code}~\n  1> <fileName>  (ЕСЛИ ПОСЛЕ 1 будет пробел получим нежданчик)
        даст в filename список кодов возврата, далее их можно как то анализировать ... 
        
        check-http-cod:            
                    ┌────────Ошибка────────┐
                    │         405          │
                    │ ──────────────────── │
                    │         <OK>         │
                    └──────────────────────┘
        
        -f Всеже дает более понятный curl: (22) The requested URL returned error: 404
            вместо просто "404"
            с другогой стороны можно и хедеры сдампить в отдельный файл и пробежатся по ним ...
                    ┌──────────────────────Ошибка──────────────────────┐
                    │ curl: (22) The requested URL returned error: 405 │
                    │ ──────────────────────────────────────────────── │
                    │                       <OK>                       │
                    └──────────────────────────────────────────────────┘

        -D (без -f) :dumpHeaders(true):forceErrors(false) - в ошибке будут все хэдеры
                    ┌───────────────Ошибка────────────────┐
                    │ HTTP/1.1 200 Connection established │
                    │   HTTP/1.1 405 Method Not Allowed   │
                    │ ─────────────────────────────────── │
                    │                <OK>                 │
                    └─────────────────────────────────────┘
    */
        
    def public var osCmd as char no-undo.
    
    def private var cUrl as char no-undo.
    def private var cPath as char no-undo.
    def private var cPort as char no-undo init '8080'.
    def private var cContentType as char no-undo init ?.
    def private var cAcceptType as char no-undo init 'application/xml'. 
    def private var cProxy as char no-undo init ?.  /*'proxy-srv.m0.maxidom.ru:3128'*/ 
    def private var listHeaders as char no-undo init ''.
    
    def public var fileErrors as char no-undo.
    def public var fileHeaders as char no-undo init ?.
    def public var fileStdOut as char no-undo.
    
    def private var lDumpHeaders as l no-undo init false.
    def private var lForceErrors as l no-undo init true.
    def private var lWriteOut as l no-undo init true.
    
    
    constructor public clsCurl(c-host as char, c-path as char):
        this-object(c-host, c-path, '8080').
    end constructor.    
 
    
    constructor public clsCurl(c-host as char, c-path as char, c-port as char):
        _tr:
        do {&err-ret-error}:
            this-object:cUrl = subst('&1:&2&3', c-host, c-port, c-path).
            init-files().
            {&catch-ret-err}
        end.
    end constructor.
    

    constructor public clsCurl(c-url as char):
        _tr:
        do {&err-ret-error}:
            this-object:cUrl = c-url.
            init-files().
            {&catch-ret-err}
        end.
    end constructor.


    destructor public clsCurl():
        os-delete value(fileErrors).
        os-delete value(fileStdOut).
        if fileHeaders <> ? then
            os-delete value(fileHeaders).
    end destructor.
    

    method private void init-files():
        _tr:
        do {&err-ret-error}:
            run get_tmp_file.p('', output fileErrors).
            run get_tmp_file.p('', output fileStdOut).
            {&catch-ret-err}
        end.
    end method.
    
    
    method public iHttpRequest proxy(c-proxy as char):
        cProxy = c-proxy.
        return this-object.
    end method.
    

    method public iHttpRequest proxy():
        cProxy = 'proxy-srv.m0.maxidom.ru:3128'.
        return this-object.
    end method.

    
    method public iHttpRequest ContentType(c-type as char):
        case c-type:
            when 'application/x-www-form-urlencoded' or 
                when 'text/xml' or
                when 'text/plain' or 
                when 'application/json' then
                    cContentType = c-type.
            otherwise return error subst('Проверьте ContentType и добавте в список. "&1"', c-type).
        end case.
        return this-object.
    end method.
    
    
    method public iHttpRequest AcceptType (c-type as char):
        case c-type:
            when 'text/plain' or
            when 'text/xml' or
            when 'application/json' or
            when 'application/xml' then
                cAcceptType = c-type.
            otherwise return error 'Проверьте AcceptType и добавте в список'.
        end case.
        return this-object.
    end method.

    
    method public iHttpRequest Header(c-key as char, c-val as char):
         listHeaders = listHeaders + subst(' -H "&1: &2"', c-key, c-val).
         return this-object.             
    end method.
    
    
    method public clsCurl DumpHeaders(lval as l):
        lDumpHeaders = lval.
        return this-object.
    end method.


    method public clsCurl ForceErrors(lval as l):
        lForceErrors = lval.
        return this-object.
    end method.


    method public clsCurl WriteOut(lval as l):
        lWriteOut = lval.
        return this-object.
    end method.
    
    
    method private void init-osCmd():
        _tr:
        do {&err-ret-error}:
            if lDumpHeaders and fileHeaders = ? then 
                run get_tmp_file.p('', output fileHeaders).
            osCmd = 'curl ' + cUrl
                  + ' -s -S'   
           /*       + ' --stderr ' + fileErrors  2> Так же работает ... */
                  + ' 1> ' + fileStdOut
                  + ' 2> ' + fileErrors.
            assign
                osCmd = osCmd + ' --write-out "~%~{response_code}~\n"' when  lWriteOut
                osCmd = osCmd + ' -f' when lForceErrors
                osCmd = osCmd + ' -D ' + fileHeaders when lDumpHeaders
                osCmd = osCmd + subst(' -H "Content-Type: &1"', cContentType) when  cContentType <> ?
                osCmd = osCmd + subst(' -H "Accept: &1"', cAcceptType) when cAcceptType <> ?
                osCmd = osCmd + listHeaders
                osCmd = osCmd + ' --proxy1.0 ' + cProxy when cProxy <> ?.
            {&catch-ret-err}
        end.
    end method.


    method public void get(fileReq as char, fileResponse as char):
        _tr:
        do {&err-ret-error}:
            if cContentType = ? then cContentType = 'text/plain'.
            init-osCmd().
            osCmd = osCmd + ' -X GET'.
            exec(fileResponse, false).
            check-http-cod().
            {&catch-ret-err}
        end.
    end method.

    
    method public void post(fileRequest as char):
        _tr:
        do {&err-ret-error}:
            post(fileRequest, ?).
            {&catch-ret-err}
        end.
    end method.
    
    
    method public void post(fileRequest as char, fileResponse as char):
        _tr:
        do {&err-ret-error}:
            if cContentType = ? then cContentType = 'application/x-www-form-urlencoded'.
            init-osCmd().
            osCmd = osCmd
                  + ' -X POST'
                  + subst(' -d "@&1"', fileRequest).
            exec(fileResponse, true).
            check-http-cod().
            {&catch-ret-err}
         end.
    end method.


    method public void postString(c-string as char, fileResponse as char):
        _tr:
        do {&err-ret-err}:
            if cContentType = ? then cContentType = 'application/x-www-form-urlencoded'.
            init-osCmd().
            osCmd = osCmd
                  + ' -X POST'
                  + subst(" -d '&1'", c-string). 
            exec(fileResponse, true).
            check-http-cod().
            {&catch-ret-err}
        end.
    end method.
            

    method private void check-http-cod():
        def var i-cod as int no-undo init ?.
        _tr:
        do {&err-ret-error}:
            input from value(fileStdOut).
            _tr:
            do while true {&err-leave}:
                import i-cod.
                if i-cod <> 200 then 
                    leave _tr.
            end.
            input close.
            if i-cod <> 200 then 
                return error getErrStr().
            {&catch-ret-err}
        end.
    end method.

    
    method public void exec(fileResponse as char, l-post as l):
        _tr:
        do {&err-ret-error}:
            if fileResponse = ? then 
                fileResponse = '/dev/null'.
            else
                os-delete value(fileResponse).
            osCmd = osCmd + ' --output ' + fileResponse.
            unix silent value(osCmd).
            {&catch-ret-err}
        end.
    end method.


    method private char getErrStr():
        def var iNN as int no-undo.
        def var cErr as char no-undo init ''.
        def var cTmp as char no-undo.
        _tr:
        do {&err-ret-error}:
            
            if search(fileErrors) <> ? then do:
                input from value(fileErrors). 
                _tr:
                do iNN = 1 to 10 {&err-leave}:
                    import unformatted cTmp.
                    cErr = cErr + cTmp + '~n'.
                end.
                input close.
                if cErr <> '' then return cErr.
            end.
            
            if search(fileHeaders) <> ? then do: /* Вызов был с DumpHeaders */
                input from value(fileHeaders).
                _tr:
                do iNN = 1 to 10 {&err-leave}:
                    import unformatted cTmp.
                    if cTmp begins 'http' then
                        cErr = cErr + cTmp + '~n'.
                end.
                input close.
                if cErr <> '' then return cErr.
            end.
            
            if search(fileStdOut) <> ? then do:  /* в StdOut должны быть HEADER'ы */
                input from value(fileStdOut).
                    _tr:
                    do iNN = 1 to 10 {&err-leave}:
                        import unformatted cTmp.
                        cErr = cErr + cTmp + '~n'.
                    end.
                input close.
                if cErr <> '' then return cErr.
            end.
             
            return 'clsCurl:unkn error'.
            {&catch-ret-err}
        end.
    end method. 

end class.
