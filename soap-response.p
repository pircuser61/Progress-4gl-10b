def input param fileSoap as char no-undo.
def input param fileBody as char no-undo.

{err.i}
{catch.i} 
 
def var hReader as handle no-undo.
def var lcChars as longchar no-undo.
def var l-xml-out as l no-undo init false.
def var has-data as l no-undo init false.
 
 _tr:
do {&err-ret-error}:
    os-delete value(fileBody).
    create sax-reader hReader.
    hReader:set-input-source('file', fileSoap).
    hReader:handler = this-procedure.
    hReader:sax-parse().
    if SAX-COMPLETE <> hReader:parse-status then
        return error 'Ошибка разбора ответа веб-сервиса'.
    
    if not has-data then 
        return error 'В ответе SOAP пустой xmlOut'.
    
    {&catch-ret-err}
    finally:
        delete object hReader no-error.
    end finally.
end.


procedure StartElement:
    def input param namespaceURI as char no-undo.
    def input param localName as char no-undo.
    def input param qName as char no-undo.
    def input param attributes as handle no-undo.
    if qName = 'xmlOut' then l-xml-out = true.
end procedure.


procedure EndElement:
    def input param namespaceURI as char no-undo.
    def input param localName as char no-undo.
    def input param qName as char no-undo.
    if qName = 'xmlOut' then l-xml-out = false.
end procedure.


procedure Characters:
    def input param charData as longchar no-undo.
    def input param numChars as int no-undo.
    
    if l-xml-out then
    _tr:
    do {&err-ret-error}:
        has-data = true.
        copy-lob charData to file fileBody append convert target codepage 'utf-8'.
        {&catch-ret-err}
    end.
end procedure.


procedure Warning:
    def input param errMessage as char no-undo.
    return error errMessage.
end procedure.


procedure Error:
    def input param errMessage as char no-undo.
    return error errMessage.
end procedure.


procedure FatalError:
    def input param errMessage as char no-undo.
    return error errMessage.
end procedure.
/**/
