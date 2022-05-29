routine-level on error undo, throw.

/* 
   Пробегается по всем узлам .json
   Должно получиться что то вроде sax-reqder, 
   только вместо callback'ов используется override  для методов.
   
   За основу взято https://www.json.org/json-ru.html 
*/


class clsJSON_v1:
    def private var cText as longchar no-undo.
    def private var iPos as int no-undo.
    def private var iRow as int no-undo.
    def private var iRowPos as int no-undo.
    def private var iLen as int no-undo.
    
    def private var cSymb as char no-undo.
    
    def private var cString as char no-undo.
    def private var fNumber as decimal no-undo.
    def private var valueType as char no-undo.
    

    method public void parseFile(cFile as char):
        copy-lob file cFile to cText convert source codepage 'utf-8'.
        parse().
    end method.
    
    
    method public void parseLongchar(jsonText as longchar):
        cText = jsonText.
        parse().
    end method.


    method protected char curr-str():   /* Для отладки */
        return subst('&1 &2 &3 &4', cString, iRow, iRowPos, cSymb).
    end method.
    
    
    method private void parse():    
        iPos = 0.
        iRow = 1.
        iRowPos = 0.
        iLen = length(cText).
        
        nextPos().
        whiteSpace().
        someValue().
         
        catch appe as progress.lang.apperror:
            appe:returnValue = appe:returnValue 
                             + subst('~nстрока &1 позиция &2 символ "&3".', iRow, iRowPos, cSymb).
            return error appe.
        end catch.
    end method.


    method private void nextPos():
        if iPos < 0 then 
            return error 'Неожиданный конец файла.'.
        iPos = iPos + 1.
        if iPos > iLen then /* первый nextPos на последнм элементе файла */ 
            assign 
                iPos = -99
                cSymb = 'EOF'.
        else
            cSymb = substring(cText, iPos, 1).
    
        if cSymb = '~n' then 
            assign
                iRow = iRow + 1
                iRowPos = 1.
        else 
            iRowPos = iRowPos + 1.
    end method. 


    method private char nextStr(len as int):
        def var c-res as char no-undo.
        def var i-nn as int no-undo.
        do i-nn = 1 to len:
            c-res = c-res + cSymb.
            nextPos().
        end.
        return c-res.
    end method.
     
    
    method private void whiteSpace():
        do while iPos > 0:
            case cSymb:
                when '~n' or 
                when ' ' or
                when '~r' or 
                when '~t' then 
                    nextPos().
                
                otherwise return.
            end case.
        end.
    end method.


    method private log isDigit():
        return cSymb >= '0' and cSymb <= '9'.
    end method.

    
    method private void array():
        valueType = 'array'.
        onArrayStart().
        nextPos().
        whiteSpace().
        if cSymb = ']' then do:
            cString = ''.
            onArrayEnd().
            nextPos().
            return.
        end.    
        do while true:
            someValue().
            if cSymb = ']' then do:
                cString = ''.
                onArrayEnd().
                nextPos().
                return.
            end.
            if cSymb = ',' then do:
                nextPos().
                next.
            end.
            return error 'Не найден конец массива "]".'.
        end.
    end method.


    method private void object():
        valueType = 'object'.
        onRecordStart().
        nextPos().
        whiteSpace().
        if cSymb = '}' then do:
            cString = ''.
            onRecordEnd().
            nextPos().
            return.
        end.
        do while true:
            pair().
            if cSymb = '}' then do:
                cString = ''.
                onRecordEnd().
                nextPos().
                return.
            end.
            if cSymb = ',' then do:
                nextPos().
                next.
            end.
            return error 'Не найден конец записи "}".'.
        end.
    end method.


    method private void pair():
        def var cKey as char no-undo.
        
        onPairStart().
        whiteSpace().
        stringValue().
        cKey = cString.
        whiteSpace().
        if cSymb <> ':' then 
            return error subst('Ожидался разделитель ":" пары ключ-значение (&1), получен "&2".',
                cString, cSymb).
        nextPos().
        onPairKey(cKey).
        someValue().
        onPairEnd(cKey, valueType, cString).
    end method.

    
    method private void someValue():    
        whiteSpace().
        onValueStart().
        case cSymb:
            when '"' then stringValue().
            when '~{' then object().
            when '[' then array().
            when 'n' then nullValue().
            when 't' then trueValue().
            when 'f' then falseValue().
            when '-' then number().
            otherwise do: 
                if isDigit() then 
                    number(). 
                else 
                    return error subst('Ошибка разбора, получен "&1", ',  cSymb)
                       + 'Ожидался: "STRING", "NUMBER", "NULL", "TRUE", "FALSE", "~{", "["'.
            end.
        end case.
        onValueEnd(valueType, '').
        whiteSpace().
    end method.


    method private void nullValue():
        def var c-tmp as char no-undo.
        c-tmp = nextStr(4).
        if c-tmp <> 'null' then
            return error subst('Неверный литерал (&1).', c-tmp).
        cString = ?.
        valueType = 'null'.
    end method.


    method private void trueValue():
        def var c-tmp as char no-undo.
        c-tmp = nextStr(4).
        if c-tmp <> 'true' then
            return error subst('Неверный литерал (&1).', c-tmp).
        cString = 'true'.
        valueType = 'true'.
    end method.


    method private void falseValue():
        def var c-tmp as char no-undo.
        c-tmp = nextStr(5).
        if c-tmp <> 'false' then
            return error subst('Неверный литерал (&1).', c-tmp).
        cString = 'false'.
        valueType = 'false'.
    end method.


    method private void nextDigit():
        nextPos().
        if isDigit() <> true then
            return error 'Ожидалось число.'.
    end method.


    method private void number():
        def var i-val as int no-undo.
        def var i-len as int no-undo.
        def var iSign as int no-undo init 1.
       
        valueType = 'number'.
        if cSymb = '-' then do:
            iSign = -1.
            nextDigit().
        end.
        fNumber = int(cSymb) no-error.
        nextPos().
        do while isDigit():
            fNumber = fNumber * 10 + int(cSymb).
            nextPos().
        end.
        if cSymb <> '.' then do:
            cString = string(fNumber).
            return.
        end.
        nextDigit().
        i-val = int(cSymb).
        i-len = 10.
        do while isDigit():
            i-val = i-val * 10 + int(cSymb).
            i-len = i-len * 10.
            nextPos().
        end.
        if cSymb = 'e' then 
            return error 'Експонента не поддерживается'.
        
        fNumber = fNumber + i-val / i-len.
        fNumber = iSign * fNumber.
        cString = string(fNumber).
    end method.


    method private void stringValue():
        valueType = 'string'.
        cString = ''.

        do while true:
            nextPos().
            case cSymb:
                when '~\' then 
                    cString = cString + control-char().
                when '"' then do:
                    nextPos().
                    return.
                end.
                otherwise
                    cString = cString + cSymb.
            end case.
        end.
    end method.


    method private char control-char():
        nextPos().
        case cSymb:
            /* \", \\, \/, \t, \n, \r, \f и \b  \uFFFF */ 
            when '"' then return '"'. 
            when '~\' then return '~\'. 
            when '/' then return '~/'.
            when 't' then return '~t'.
            when 'n' then return '~n'.
            when 'r' then return '~r'.
            when 'f' then return '~f'.
            when 'b' then return '~b'. 
            when 'u' then   /* 'Unicode - не знаю что с ним делать.' */
                return  '~\' + nextStr(4).  /* \uA66D */
            otherwise return '~\' + cSymb.
        end case.
    end method.
    
    
    method protected void onPairStart():
    end method.

    
    method protected void onPairKey(c-key as char):
    end method.
    
    
    method protected void onPairEnd(c-key as char, value-type as char, c-val as char):
    end method.
    
    method protected void onValueStart():
    end method.
    

    method protected void onValueEnd(c-type as char, c-value as char):
    end method.    
    

    method protected void onArrayStart():
    end method.
    

    method protected void onArrayEnd():
    end method.
    
    
    method protected void onRecordStart():
    end method.
    
    
    method protected void onRecordEnd():
    end method.

end class.
