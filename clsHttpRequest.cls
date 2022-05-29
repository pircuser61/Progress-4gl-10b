{err.i}
{catch.i}

&scoped HTTPnewline chr(13) + chr(10)  /* в винде '~r~n' даст "chr(13) + chr(13) + chr(10)" вместо "chr(13) + chr(10)" */

/* в триггере нельзя выбрасывать ошибки 
    поэтосу hSocket:set-read-response-procedure('getResponse') не используется.
*/

class clsHttpRequest implements iHttpRequest:
    def private var cHttpVer as char no-undo init '1.1'.  /* 1.0, 1.1 */
    
    def private var cHost as char no-undo.
    def private var cPort as char no-undo init '8080'.
    def private var cPath as char no-undo.
    def private var cTimeOut as char no-undo init '20'.
    
    def private var hSocket as handle no-undo.
    def private var totalBytesRead as int no-undo.
    def private var lcResponseBlock as longchar no-undo.
    def private var lcResponseBuffer as longchar no-undo init ''. /* если chunked блок разбился паетами посредине */
    def private var fileResponse as char no-undo.
    def private var iContentLength as int no-undo.
    def private var iHeaderLength as int no-undo.
    
    def private var mHTTPheader as memptr no-undo.
    def private var lChunked as l no-undo.
    def private var lSSL as l no-undo init false.
       
    def private var cContentType as char no-undo init 'text/xml;charset=UTF-8'. 
    
    constructor public clsHttpRequest(c-host as char, url-path as char):
        this-object:cHost = c-host.
        this-object:cPath = if url-path begins '/' then url-path
                            else '/' + url-path.
        create socket hSocket.
    end constructor. 
    
    
    destructor public clsHttpRequest():
        hSocket:disconnect() no-error.
        delete object hSocket no-error.
    end destructor.
    
    method public iHttpRequest proxy(cproxy as char):
        return error 'Сокеты не поддерживают proxy.'.
    end method.
  
    method public iHttpRequest proxy():
        return error 'Сокеты не поддерживают proxy.'.
    end method.


    method public iHttpRequest ContentType(c-type as char):
        case c-type:
            when 'application/x-www-form-urlencoded' or
                when 'text/xml' or
                when 'text/plain' or
                when 'application/soap+xml' then
                cContentType = c-type.
            otherwise return error subst('Проверьте ContentType и добавте в список. "&1"', c-type).
        end case.
        return this-object.
    end method.

    method public iHttpRequest AcceptType(c-type as char):
        return error 'В разработке'.
    end method.    
    
    
    method public iHttpRequest Header(c-key as char, c-val as char):
        return error 'В разработке'.
    end method.


    method public iHttpRequest httpVer(ver as char):
        if ver = '1.0' or ver = '1.1' then
            cHttpVer = ver.
        else 
            return error 'Данная версия http не поддерживается.'.
    end method.
    
    
    method public clsHttpRequest port(c-port as char):
        this-object:cPort = c-port.
        return this-object.
    end method.
    
    
    method public clsHttpRequest timeOut(i-timeout as int):
        this-object:cTimeOut = string(i-timeout).
        return this-object.
    end method.

    
    method public clsHttpRequest SSL(l-ssl as l):
        this-object:lSSL = l-ssl = yes.  /* ? - not allowed */
    end method.
    
    
    method public void GET():
        _tr:
        do {&err-ret-error}:
            if true then return error 'В разработке'.
            connect().
            createHttpHeader(0).
            hSocket:write(mHTTPheader, 1, get-size(mHTTPheader) - 1).
            set-size(mHTTPheader) = 0.
            readReponse().
        end.
    end method.
    

    method public void POST(fileRequset as char, fileResponse as char):
        def var mRequest as memptr no-undo.
        _tr:
        do {&err-ret-error}:
            if totalBytesRead <> 0 then 
                return error 'Этот инстанс уже отработал.'
                            + '~nПовторное использование может приводить к зависаниям.'
                            + '~nСоздайте новый запрос - '
                            + ' это все равно быстрее внешних скриптов.'.
                    
            this-object:fileResponse = fileResponse.
            os-delete value(fileResponse).
            copy-lob from file fileRequset to mRequest.
            createHttpHeader(get-size(mRequest)).
            connect().
            hSocket:write(mHTTPheader, 1, get-size(mHTTPheader) - 1). 
            hSocket:write(mRequest, 1, get-size(mRequest)).
            set-size(mRequest) = 0.
            set-size(mHTTPheader) = 0.
            readReponse().
            {&catch-ret-err}
        end.
    end method.
    
    
    method private void connect():
        def var connection-string as char no-undo.
        _tr:
        do {&err-ret-error}:
            connection-string = subst('-H &1 -S &2', cHost, cPort).
            if lSSl then 
                connection-string = connection-string + ' -ssl -nohostverify'.
            hSocket:connect(connection-string) no-error.
            if hSocket:connected() = false then
                return error 'connection failure~n' + error-status:get-message(1).
            
            if hSocket:set-socket-option('SO-RCVTIMEO', cTimeOut) <> yes then
                    return error subst('cant set timeout: &1', cTimeOut).
            if hSocket:connected() = false then
                return error 'connection failure~n' + error-status:get-message(1).
        {&catch-ret-err}
        end.
    end method.
    
    
    method private void readReponse():
        def var i-nn as int no-undo init 0.
        def var next-block as l no-undo init true.
        def var bytesAvail as int no-undo.
        def var mResponse as memptr no-undo.
        
        _tr:
        do {&err-ret-error}:
            totalBytesRead = 0.
            _response:
            do while next-block:
                bytesAvail = hSocket:get-bytes-available().
                if bytesAvail = 0 then 
                    if hSocket:connected() then do:
                        wait-for read-response of hSocket.
                        next _response.
                    end.
                    else 
                        return error 'Соединение закрыто, данные получены не полностью'.

                set-size(mResponse) = bytesAvail + 1.
                set-byte-order(mResponse) = big-endian.
                hSocket:read(mResponse, 1, bytesAvail).
                totalBytesRead = totalBytesRead + hSocket:bytes-read.
                
                /*
                lcResponseBlock = get-string(mResponse, 1) no-error.
                if error-status:error then return error 'Пакет не поместился, бида бида'.
                */
                copy-lob mResponse for bytesAvail to lcResponseBlock.
                i-nn = i-nn + 1.
                if i-nn = 1 then readHttpHeader().
                next-block = appendResponseBlock(). 
                set-size(mResponse) = 0.    /* Если не почистить - останетмя мусор, который НЕе затрет hSocket:read 
                                                еслино новый буфер меньше предыдущено */   
            end.
            {&catch-ret-err}
            finally:
                set-size(mResponse) = 0.
            end finally.    
        end.
    end method.
    
    
    method private void readHttpHeader():
        def var status-cod as char no-undo init ?.
        def var i-line-start as int no-undo.
        def var i-line-end as int no-undo.
        def var c-line as char no-undo.
        def var chttpHeader as char no-undo.
        _tr:
        do {&err-ret-error}:
            /*
            display lcResponseBlock view-as editor large size 120 by 16
            with view-as dialog-box title 'HEADER'.
            pause.
            */
            lChunked = false.
            i-line-start = 1.
            i-line-end = index(lcResponseBlock, {&HTTPnewline}).
            _lines:
            do while i-line-end > i-line-start:  /* line-start = line-end - пустая строка */
                c-line = substring(lcResponseBlock, i-line-start, i-line-end - i-line-start).
                i-line-start = i-line-end + 2.
                i-line-end = index(lcResponseBlock, {&HTTPnewline}, i-line-start).

                if c-line begins 'HTTP/' then do:
                    status-cod = entry(2, c-line, ' ') no-error.
                end.
                else if c-line begins 'Transfer-Encoding' then do:
                    if c-line = 'Transfer-Encoding: chunked' then lChunked = true.
                    else return error 'unkn: ' + c-line.
                end.
                else if c-line begins 'Content-Length' then 
                    iContentLength = int(entry(2, c-line, ':')).
            end.
            
            if status-cod <> '200' then return error subst('HTTP:status cod: &1', status-cod).
            i-line-start = i-line-end + 2. /* пустая строка, конец HTTP заголовка */
            iHeaderLength = i-line-start - 1.
            
            chttpHeader = substring(lcResponseBlock, 1, i-line-start).
            if lChunked then
                lcResponseBlock = substring(lcResponseBlock, i-line-start - 2). 
                            /* -2 Возвращаем {&httpnewLine} перед размером chunka */
            else
                lcResponseBlock = substring(lcResponseBlock, i-line-start).
            {&catch-ret-err}
        end.
    end method.
    
    
    method private l appendResponseBlock():
        def var lc-block as longchar no-undo.
        def var size-start as int no-undo.
        def var size-end as int no-undo.
        def var block-size as int no-undo.
        def var block-hex-size as char no-undo.
        def var resp-len as int no-undo.
        def var block-start as int no-undo.
        def var block-end as int no-undo.
        def var ctmp as char no-undo.
        _tr:
        do {&err-ret-error}:
            if not lChunked then do:
                copy-lob lcResponseBlock to file fileResponse append.
                return totalBytesRead < iContentLength + iHeaderLength. 
            end.
            
            /*
              CHUNCKED - ответ разбит на блоки (chunk'и): 
                
                {&HTTPnewline}<размер блока hex>{&HTTPnewline}<ТелоБлока>,
                
                блок размера 0 - признак окончания передачи.
                сами блоки могут падать в cокет разными пакетами,
                т.е. могла прилетить как часть блока, так и часть размера
            */
            
            /* добавляем остаток предыдущего пакета */ 
            lcResponseBlock = lcResponseBuffer + lcResponseBlock.
            lcResponseBuffer = ''.
            resp-len = length(lcResponseBlock).
            block-start = 1. 
            do while true:
                ctmp = substring(lcResponseBlock, block-start, 2).
                if ctmp <> {&HTTPnewline} then do:
                    ctmp = replace(ctmp, '~n', '~\n').
                    ctmp = replace(ctmp, '~r', '~\r').
                    return error subst('{&HTTPnewline} <> &1', ctmp).
                end.
                size-start = block-start + 2. /* пропуск  {&HTTPnewline} перед размером chunka */
                size-end = index(lcResponseBlock, {&HTTPnewline}, size-start). /* размер chunka */
                if size-end = 0 then 
                    leave.  /* в пакет влезла только часть размера chunk'a */
                block-hex-size = substring(lcResponseBlock, size-start, size-end - size-start).
                block-size = hexToInt(block-hex-size).
                if block-size = ? then 
                    return error 'clsHttpRequst: block-size == ?'.
                if block-size = 0 then  /* блок chunk размера - признак конца передачи */
                    return false.
                
                block-end = size-end + 2 + block-size. /* +2 скипает  {&HTTPnewline} после размера chunka */
                if block-end > resp-len then leave. /* chunk не влез в пакет */
                block-start = block-end - block-size.
                lc-block = substring(lcResponseBlock, block-start, block-size).
                block-start = block-end.
                copy-lob lc-block to file fileResponse Append.
            end. 
            lcResponseBuffer = substring(lcResponseBlock, block-start).  /* сохраняем остаток */
            return true.
            {&catch-ret-err}
        end.
    end method.
    
    
    method private void createHttpHeader(post-size as int64):
        def var c-http as char no-undo.
        def var c-url as char no-undo.
        
        _tr:
        do {&err-ret-error}: 
            c-url = subst('http://&1:&2&3', cHost, cPort, cPath).
            c-http = 'POST ' + c-url + ' HTTP/' + cHttpVer  
                   + {&HTTPnewline} + 'Content-Type: ' + cContentType
                   + {&HTTPnewline} + 'SOAPAction: ""'
                   + {&HTTPnewline} + 'Content-Length: ' + string(post-size)
              /*   + {&HTTPnewline} + 'Connection: Keep-Alive'                         */
              /*   + {&HTTPnewline} + 'Accept-Encoding: gzip,deflate'                  */
                   + {&HTTPnewline} + 'Host: ' + cHost + ':' + cPort                 
                   + {&HTTPnewline} + 'User-Agent: Socket httpRequest (Progress 4gl)' 
                   + {&HTTPnewline} + {&HTTPnewline}.
          
          /*  рабочий запрос из soap ui
             if no then
             c-http = 'POST http://gesweb.m0.maxidom.ru:8080/ws_ora_gate1/ws_ora_gate HTTP/1.1'
        /*  + {&HTTPnewline}           + 'Accept-Encoding: gzip,deflate' */
          + {&HTTPnewline}           + 'Content-Type: text/xml;charset=UTF-8'
          + {&HTTPnewline}           + 'SOAPAction: ""'
          + {&HTTPnewline}           + 'Content-Length: 909'
          + {&HTTPnewline}           + 'Host: gesweb.m0.maxidom.ru:8080'
          + {&HTTPnewline}           + 'Connection: Keep-Alive'
       /*   + {&HTTPnewline}           + 'User-Agent: Apache-HttpClient/4.1.1 (java 1.5)'
         */  + {&HTTPnewline} + {&HTTPnewline}.

          
            display   'POST ' + c-url + ' HTTP/' + cHttpVer   format 'x(100)'
             skip c-http 
            view-as editor size 100 by 12 with 
            view-as dialog-box title 'socket HTTP HEADER'. 
            pause.
            
          */  
            set-size(mHTTPheader) = length(c-http) + 1. /*, 'RAW'*/
            set-byte-order(mHTTPheader) = BIG-endIAN.
            put-string(mHTTPheader, 1) = c-http.
            {&catch-ret-err}
        end.
    end method.
    
    
    method private int hexToInt(x as char):
        def var i-nn as int no-undo.
        def var c-digit as char no-undo.
        def var i-digit as int no-undo.
        def var i-result as int no-undo init 0.
        
        _tr:
        do {&err-ret-error}:
            do i-nn = 1 to length(x):
                i-result = i-result * 16.
                
                c-digit = substring(x, i-nn, 1).
                case c-digit:
                    when 'a' then i-digit = 10.
                    when 'b' then i-digit = 11.
                    when 'c' then i-digit = 12.
                    when 'd' then i-digit = 13.
                    when 'e' then i-digit = 14.
                    when 'f' then i-digit = 15.
                    otherwise i-digit = int(c-digit).
                end case.
                
                i-result = i-result + i-digit.  
            end.
            return i-result.
            catch e as progress.lang.error:
                return error subst('hexToInt: &1~n&2', x, e:getMessage(1)).
            end catch.
        end.
    end method.
    
end class.
/**/
