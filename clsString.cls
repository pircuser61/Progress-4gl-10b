{err.i}
{catch.i}


class clsString:
    /*  ISO-DATE function 
    method public char dateFormatIso (input v-x as date):
        return string(year(v-x),'9999') 
            + '-' + string(month(v-x),'99') 
            + '-' + string(day(v-x),'99').
    end method.
    
        
    method public char dateFormatUs (input v-x as date):
        return string(month(v-x),'99') 
            + '~/' + string(day(v-x),'99') 
            + '~/' + string(year(v-x),'9999').
    end method.
    */
    
    method public char RU-date(input v-x as date):
        return string(day(v-x),'99') 
            + '.' + string(month(v-x),'99') 
            + '.' + string(year(v-x),'9999').
    end method.
    
    
    method public date ToDateISO(c-val as char):
        def var yyyy as int no-undo.
        def var mm as int no-undo.
        def var dd as int no-undo.
        def var dt-val as date no-undo.
        _tr:
        do {&err-ret-error}:
            assign
                yyyy = int(entry(1, c-val, '-'))
                mm = int(entry(2, c-val, '-'))
                dd = int(entry(3, c-val, '-')) no-error. 
            if error-status:error then 
                return error subst('Ожидалась дата в формате yyyy-mm-dd.~n(получено &1)', c-val).
            dt-val = date(mm, dd, yyyy).
            return dt-val.
            {&catch-ret-err}
        end.
    end method.


    method public date toDateRU(c-val as char):
        def var yyyy as int no-undo.
        def var mm as int no-undo.
        def var dd as int no-undo.
        def var dt-val as date no-undo.
        _tr:
        do {&err-ret-error}:
            assign
                yyyy = int(entry(3, c-val, '.'))
                mm = int(entry(2, c-val, '.'))
                dd = int(entry(1, c-val, '.')) no-error.
            if error-status:error then 
                return error subst('Ожидалась дата в формате dd.mm.yyyy.~n(получено &1)', c-val).
            dt-val = date(mm, dd, yyyy).
            return dt-val.
            {&catch-ret-err}
        end.
    end method.
    

    method public int toTime(c-val as char): /* HH:MM -> int */
        def var hh as int init ?.
        def var mm as int init ?.
        def var ss as int init 0.
        _tr:
        do {&err-ret-error}:
            assign
                hh = int(entry(1, c-val, ':'))
                mm = int(entry(2, c-val, ':')) no-error.
            if error-status:error or 
                hh = ? or hh < 0 or hh > 23 or 
                mm = ? or mm < 0 or mm > 59 then 
                return error subst('Ожидалась дата в формате HH:MM~n(получено &1)', c-val).
            ss = int(entry(3, c-val, ':')) no-error.  /* HH:MM:SS - тоже можно */
            return (hh * 3600 + mm * 60 + ss).
            {&catch-ret-err}
        end.
    end method.


    method public deci toDeci(c-val as char, c-delimiter as char):
        def var f-val as deci no-undo.
        _tr:
        do {&err-ret-error}:
            if num-entries(c-val, c-delimiter) > 2 then 
                return error 'Более одного разделителся в числе'.
            if c-delimiter <> session:NUMERIC-DECIMAL-POINT then do:
                c-val = replace(c-val, session:NUMERIC-DECIMAL-POINT, '').            /* 1.999,00 -> 1999,00 */
                c-val = replace(c-val, c-delimiter, session:NUMERIC-DECIMAL-POINT).   /*  1999,00 -> 1999.00 */
            end.
            f-val = deci(c-val) no-error.
            if not error-status:error then 
                return f-val.
            return error subst('Ошибка преобразования "&1" в число с разделителем "&2".', 
                c-val, c-delimiter).
        end.
    end method.


    method public int hexToInt(c-val as char):
        def var i-nn as int no-undo.
        def var c-digit as char no-undo.
        def var i-digit as int no-undo.
        def var i-result as int no-undo init 0.

        _tr:
        do {&err-ret-error}:
            do i-nn = 1 to length(c-val):
                i-result = i-result * 16.

                c-digit = substring(c-val, i-nn, 1).
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
            {&catch-ret-err}
        end.
    end method.
end class.
/**/
