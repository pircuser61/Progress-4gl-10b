{err.i}
{catch.i}

/*
  Проблема - saxReader - должен получить call-back процедуру...
  решение 
    
    1- Процедура фасад - которая просто вызывает методы текущего класса 
        https://github.com/consultingwerk/ADE-Sourcecode/blob/master/src/corelib/OpenEdge/Core/XML/saxreaderfacade.p
    
    2- Оборачивать/разворачивать средствами x-documtent

    3- Сделать *.p-шку для снятия SOAP - обертки 
        soap-response.p(input fileResponseSoap, input fileResponseBody)
*/



class clsSoapRequest:
    def public var cOraSv as char no-undo init 'sybil'.
    def public var cProgGate as char no-undo init ''.
    def public var objRequest as iHttpRequest.
    
    def private var fileRequest as char no-undo.
    def private var fileResponse as char no-undo.
    def private var fileResponseBody as char no-undo.
    def private var lcCdata as longchar no-undo.
    
    def private var l-xml-out as l no-undo.
    def private var lc-xml-out as longchar no-undo.
    

    constructor public clsSoapRequest():
        _tr:
        do {&err-ret-error}:
            init-files().
            {&catch-ret-err}
        end.    
    end constructor.
    
    
    constructor public clsSoapRequest(objHttpRequest as iHttpRequest):
        _tr:
        do {&err-ret-error}:
            this-object:objRequest = objHttpRequest.
            init-files().
            {&catch-ret-err}
        end.
    end constructor. 

    
    constructor public clsSoapRequest(c-url as char, c-path as char):
        _tr:
        do {&err-ret-error}:
            objRequest = new clsHttpRequest(c-url, c-path).
            init-files().
        end.
    end constructor.
    
    
    destructor public clsSoapRequest():
        os-delete value(fileRequest).
        os-delete value(fileResponse).
        os-delete value(fileResponseBody).
    end destructor.
    
    
    method protected void init-files():
        _tr:
        do {&err-ret-error}:
            run get_tmp_file.p('', output fileRequest).
            run get_tmp_file.p('', output fileResponse).
            run get_tmp_file.p('', output fileResponseBody).
        end.
    end method.
    
   /* 
    method public clsSoapRequest gate(c-gate as char):
        cProgGate = c-gate.
        return this-object.
    end method.
    */
    
    method public void request(fileXml as char, fileResponseBopy as char):
        _tr:
        do {&err-ret-error}:
            copy-lob from file fileXml to lcCdata.
            SoapEnvelope().
            objRequest:post(fileRequest, fileResponse).
            run soap-response.p(fileResponse, fileResponseBopy).
            {&catch-ret-err}
        end.
    end method.
    
    
    method public void request(hXmlDoc as handle):
        def var l-tmp as l no-undo.
        _tr:
        do {&err-ret-error}:
            hXmlDoc:save('longchar', lcCdata).
            SoapEnvelope().
            objRequest:post(fileRequest, fileResponse).
            run soap-response.p(fileResponse, fileResponseBody).
            l-tmp = hXmlDoc:Load('file', fileResponseBody, no) no-error.
            if l-tmp <> yes or error-status:num-messages > 0 then
                return error 'Ошибка при загрузке xml: ' + error-status:get-message(1).
            {&catch-ret-err}
        end.
    end method.
    
    
    method private void SoapEnvelope():
        def var hWriter as handle no-undo.
        def var hAttr as handle no-undo.
        _tr:
        do {&err-ret-error}:
            create sax-writer hWriter.
            create sax-attributes hAttr.
            /*
            hWriter:set-output-destination('memptr', mRequest).
            */
            hWriter:set-output-destination('file', fileRequest).
            assign
                hwriter:formatted = false /* true - ломает оракл Error="true" ErrorCode="9"> */
                hwriter:encoding  = "utf-8"
                hwriter:strict    = false.
            
            hWriter:start-document().
            hAttr:insert-attribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance').
            hAttr:insert-attribute('xmlns:xsd', 'http://www.w3.org/2001/XMLSchema').
            hAttr:insert-attribute('xmlns:urn', 'urn:gestori-gate:ws_ora_gate').
            
            hWriter:start-element('soapenv:Envelope', 'http://schemas.xmlsoap.org/soap/envelope/', hAttr).
            
            hWriter:write-empty-element('soapenv:Header').
            
            hWriter:start-element('soapenv:Body').
            
            delete object hAttr.
            create sax-attributes hAttr.
            hAttr:insert-attribute('soapenv:encodingStyle', 'http://schemas.xmlsoap.org/soap/encoding/').
            hWriter:start-element('urn:ws_ora_gate', '', hAttr).

            delete object hAttr.
            create sax-attributes hAttr.
            hAttr:insert-attribute('xsi:type', 'xsd:string').
            
            hWriter:write-data-element('wantOraServer', cOraSv, ? ,hAttr).
            hWriter:write-data-element('userid', 'none', ? ,hAttr).
            hWriter:write-data-element('module', 'none', ? ,hAttr).
            
            hWriter:write-data-element('gate2prog', cProgGate, ? ,hAttr).
            hWriter:start-element('param4prog', ? ,hAttr).
            hWriter:write-cdata(lcCdata).
            hWriter:end-element('param4prog').
            
            hWriter:end-element('urn:ws_ora_gate').
            hWriter:end-element('soapenv:Body').
            hWriter:end-element('soapenv:Envelope').
            hWriter:end-document().

            {&catch-ret-err}
            finally:
                delete object hWriter no-error.
                delete object hAttr no-error.
            end finally.
        end.
    end method.
end class.
/**/
