{err.i}
{catch.i}

/* Обертка для x-noderef */

class xmlNodeWrap:
    def public var hDoc as handle no-undo.
    def public var hNode as handle extent no-undo.
    
    def var hText as handle no-undo.
    def private var oStr as clsString no-undo.    
    
    constructor public xmlNOdeWrap():
        _tr:
        do {&err-ret-error}:
            create x-document hDoc.
            create x-noderef hText.
            hDoc:encoding = 'utf-8'.
            oStr = new clsString().
        end.
    end constructor.
    
    
    constructor public xmlNodeWrap(i-size as int):
        _tr:
        do {&err-ret-error}:
            create x-document hDoc.
            create x-noderef hText.
            hDoc:encoding = 'utf-8'.
            
            set-size(i-size).
            oStr = new clsString().
        end.
    end constructor.

    
    destructor public xmlNodeWrap():
        def var v-i as int no-undo.
        do v-i = 1 to extent(hNode):
            if valid-handle(hNode[v-i]) then 
                delete object hNode[v-i].
        end.
        if valid-handle(hText) then delete object hText.
        if valid-handle(hDoc) then delete object hDoc.
    end destructor.
     
    
    method protected void set-size(i-size as int):
        def var v-i as int no-undo.
        _tr:
        do {&err-ret-error}:
            if extent(hNode) <> ? then /* можно сделать extent(hNode) = ? но не уверен на счет утечек .. 
                                        и hNode придется очищаять ..
                                        */
                return error 'Размер уже задан'.
            extent(hNode) = i-size.
            do v-i = 1 to extent(hNode):
                create x-noderef hNode[v-i].
            end.
            {&catch-ret-err} 
        end.
    end method.
    
    /*  date-iso standart function
    method protected char dateFormatIso (input v-x as date):
        return string(year(v-x),'9999') 
            + '-' + string(month(v-x),'99') 
            + '-' + string(day(v-x),'99').
    end method.
    */
    
    method protected char dateFormatRu (input v-x as date):
        return string(day(v-x),'99') 
            + '.' + string(month(v-x),'99') 
            + '.' + string(year(v-x),'9999').
    end method.
    
    
    method protected char dateFormatUs (input v-x as date):
        return string(month(v-x),'99') 
            + '~/' + string(day(v-x),'99') 
            + '~/' + string(year(v-x),'9999').
    end method.
    
    
    method protected char deciFormat(input v-x as deci):
        return deciFormat(v-x, ',').
    end method.
    
    
    method protected char deciFormat(input v-x as deci, deci-point as char):
        def var c-val as char no-undo.
        c-val = replace(string(v-x), session:numeric-separator, ''). /* удаляем разделитель разрядов на всякий */
        return replace(c-val, session:numeric-decimal-point, deci-point).
    end method.

    /*
      Если хотим сделать еще один .xml наприме повторный запрос
      createRoot вернет ошибку пока мы не очистим hDoc
    */
    method public void clear():
        _tr:
        do {&err-ret-error}:
            if hDoc:num-children = 0 then return.
            hDoc:get-document-element(hNode[1]).
            hNode[1]:delete-node().
            {&catch-ret-err}
        end.
    end method.


    method public void createRoot(cRootName as char):
        _tr:
        do {&err-ret-error}:
            hDoc:create-node(hNode[1], cRootName, 'Element').
            hDoc:append-child(hNode[1]).
            {&catch-ret-err}
        end.
    end method.
    
    
    method public void addNOde(iParent as int, iChild as int, cname as char):
        addNode(iParent, iChild, cname, '').
        {&catch-ret-err}
    end method.
    

    method public void addNode(iParent as int, iChild as int, cname as char, cval as date):
        addNode(iParent, iChild, cname, string(cval)).
        {&catch-ret-err}
    end method.


    method public void addNode(iParent as int, iChild as int, cname as char, cval as deci):
        addNode(iParent, iChild, cname, string(cval)).
        {&catch-ret-err}
    end method.
    
    
    method public void addNode(iParent as int, iChild as int, cname as char, cval as int):
        addNode(iParent, iChild, cname, string(cval)).
        {&catch-ret-err}
    end method.


    method public void addNode(iParent as int, iChild as int, cname as char, lval as log):
        if lval = ? then return error subst('&1 должен быть true или false, ? - не допустим', cname).
        addNode(iParent, iChild, cname, if lval then 'true' else 'false').
        {&catch-ret-err}
    end method.
    
    
    method public void addNode(iParent as int, iChild as int, cname as char, cval as char):
        def var hChild as handle no-undo.
        _tr:
        do {&err-ret-error}:
            hChild = hNode[iChild].
            hDoc:create-node(hChild, cname, 'Element').
            hNode[iParent]:Append-Child(hChild).
            
            if cval = ? or cval = '' then return.
            hDoc:create-node(hText,?, 'Text').
            hText:Node-Value = cval.
            hChild:Append-Child(hText).
            {&catch-ret-err}
        end.
    end method.
    

    method public void get-root():
        def var l-tmp as l no-undo.
        _tr:
        do {&err-ret-err}:
           l-tmp = hDoc:get-document-element(hNode[1]) no-error.
           if l-tmp <> yes then 
               return error 'Ошибка при загрузке xml: ' + error-status:get-message(1).
        end.
    end method.    

        
    method public char get-attribute(iNode as int, attr-name as char):
        return hNode[iNode]:get-attribute(attr-name).
        {&catch-ret-err}
    end method.


    method public int getCData(iParentNode as int, iChildNode as int):
        def var i-nn as int no-undo.
        _tr:
        do i-nn = 1 to hNode[iParentNode]:num-children {&err-ret-error}:
            getChild(iParentNode, i-nn, iChildNode).
            if hNode[iChildNode]:subtype = 'CDATA-SECTION' then 
                return i-nn.
            {&catch-ret-err}
        end.
        return error subst('Не найден "CDATA".').
    end method.
    
    
    method public int getElement(iParentNode as int, iChildNode as int, 
                                 cNodeName as char):
        def var i-nn as int no-undo.
        _tr:
        do i-nn = 1 to hNode[iParentNode]:num-children {&err-ret-error}:
            getChild(iParentNode, i-nn, iChildNode).
            if hNode[iChildNode]:subtype = 'Element' 
                and hNode[iChildNode]:name = cNodeName then
                return i-nn.
            {&catch-ret-err}        
        end.
        return error subst('Не найден тэг <&1>', cNodeName).
    end method.


    method public char getElementText(iParentNode as int, iChildNode as int,
                                     cNodeName as char):
        _tr:
        do {&err-ret-error}:                             
            getElement(iParentNode, iChildNode, cNodeName).
            return charValue(iChildNode).
            {&catch-ret-err}
        end.
    end method.                                 
    
    
    method public int getFirstElement(iParentNode as int, iChildNode as int):
        def var i-nn as int no-undo.
        _tr:
        do i-nn = 1 to hNode[iParentNode]:num-children {&err-ret-error}:
            getChild(iParentNode, i-nn, iChildNode).
            if hNode[iChildNode]:subtype = 'Element' then
                 return i-nn.
            {&catch-ret-err}
        end.
        return -1.
    end method.


    method public int getFirstElement(iParentNode as int, iChildNode as int, cNodeName as char):
        def var i-nn as int no-undo.
        _tr:
        do i-nn = 1 to hNode[iParentNode]:num-children {&err-ret-error}:
            getChild(iParentNode, i-nn, iChildNode).
            if hNode[iChildNode]:subtype = 'Element' and 
                hNode[iChildNode]:name = cNodeName then
                return i-nn.
            {&catch-ret-err}
        end.
        return -1.
    end method.
 
    
    method public int getNextElement(iParentNode as int, iChildNode as int, iStartElement as int):
        def var i-nn as int no-undo.
        _tr:
        do i-nn = iStartElement + 1 to hNode[iParentNode]:num-children {&err-ret-error}:
            getChild(iParentNode, i-nn, iChildNode).
            if hNode[iChildNode]:subtype = 'Element' then 
                return i-nn.
            {&catch-ret-err}
        end.
        return -1.
    end method.


    method public int getNextElement(iParentNode as int, iChildNode as int):
        def var iStartElement as int no-undo.
        _tr:
        do {&err-ret-error}:
            iStartElement = hNode[iChildNode]:child-num .
            return getNextElement(iParentNode, iChildNode, iStartElement).
            {&catch-ret-err}
        end.
    end method.


    method public int getNextElement(iParentNode as int, iChildNode as int, 
                                     cNodeName as char):
        def var i-nn as int no-undo.
        def var i-tmp as int no-undo.
        def var iStartElement as int no-undo.
        _tr:
        do {&err-ret-error}:
            iStartElement = hNode[iChildNode]:child-num.
            do i-nn = iStartElement to hNode[iParentNode]:num-children:
                i-tmp = getNextElement(iParentNode, iChildNode, i-nn).
                if i-tmp <= 0 then 
                    return i-tmp.
                if hNode[iChildNode]:name = cNodeName then 
                    return i-tmp.
            end.
            {&catch-ret-err}
        end.
        return -1.
    end method.
    
    
    method public void getChild(iParentNode as int, iNumChild as int, iChildNode as int):
        def var l-result as l no-undo.
        _tr:
        do {&err-ret-error}:
            l-result = hNode[iParentNode]:get-child(hNode[iChildNode], iNumChild) no-error.
            if not l-result or error-status:error then
                return error subst('Ошибка получения потомка &3 для &1: &2', 
                    hNode[iParentNode]:name, error-status:get-message(1), iNumChild).
            {&catch-ret-err}
        end.
    end method.


    method public char nodeName(iNode as int):
        _tr:
        do {&err-ret-error}:
            return hNode[iNode]:name.
            {&catch-ret-err}
        end.
    end method.
    
    
    method public char charValue(iNode as int):
        _tr:
        do {&err-ret-error}:
            if hNode[iNode]:num-children = 0 then 
                return ''.
            hNode[iNode]:get-child(hText, 1).
            if hText:subtype <> 'Text' then              /* Например <Node> </SubNode> i-value </Node> */ 
                return error 'hNodeValue:subtype <> "Text"'.   /* Лечится типичным do v-i to hNode:num-children: */
                                                              /* Но что то неохота тащить сюда */
            return trim(hText:node-value).
            {&catch-ret-err}
        end.
    end method.


    method public int intValue(iNode as int):
        def var c-val as char no-undo.
        def var i-val as int no-undo.
        _tr:
        do {&err-ret-error}:
            c-val = charValue(iNode).
            i-val = int(c-val) no-error.
            if error-status:error then
                return error subst('&1 должен быть целым числом. получено "&2"', 
                    hNode[iNode]:name, c-val).
            return i-val.
            {&catch-ret-err}
        end.
    end method.


    method public int int64Value(iNode as int):
        def var c-val as char no-undo.
        def var i-val as int no-undo.
        _tr:
        do {&err-ret-error}:
            c-val = charValue(iNode).
            i-val = int64(c-val) no-error.
            if error-status:error then
                return error subst('&1 должен быть целым числом. получено "&2"',
                    hNode[iNode]:name, c-val).
            return i-val.
            {&catch-ret-err}
        end.
    end method.


    method public deci deciValue(iNode as int):
        def var c-val as char no-undo.
        def var f-val as deci no-undo.
        _tr:
        do {&err-ret-error}:
            c-val = charValue(iNode).
            f-val = deci(c-val) no-error.
            if error-status:error then 
                return error subst('&1 должен быть числом.  получено "&2"', 
                    hNode[iNode]:name, c-val).
            return f-val.
            {&catch-ret-err}
        end.
    end method.


    method public deci deciValue(iNode as int, deci-point as char):
        /*
        def var c-val as char no-undo.
        def var f-val as deci no-undo.
        */
        _tr:
        do {&err-ret-error}:
            return oStr:toDeci(charValue(iNode), deci-point).
            /*
            c-val = charValue(iNode).
            c-val = replace(c-val, deci-point, session:numeric-decimal-point).
            f-val = deci(c-val) no-error.
            if error-status:error then
                return error subst('&1 должен быть числом.  получено "&2"',
                                      hNode[iNode]:name, c-val).
            return f-val.
            */
        {&catch-ret-err}
        end.
    end method. 

    
    method public logical logValue(iNode as int):
        def var c-val as char no-undo.
        def var l-val as l no-undo.
        _tr:
        do {&err-ret-error}:
            c-val = charValue(iNode).
            l-val = logical(c-val) no-error.
            if error-status:error then
                return error subst('&1 должен быть true/false.', hNode[iNode]:name).
            return l-val.
            {&catch-ret-err}
        end.
    end method.
    
    
    method public date dateValue(iNode as int):
        def var c-val as char no-undo.
        def var dt-val as date no-undo.
        _tr:
        do {&err-ret-error}:
            c-val = charValue(iNode).
            dt-val = date(c-val) no-error.
            if error-status:error then
                return error subst('&1 должен датой.~n(получено &2)',
                    hNode[iNode]:name, c-val).
            return dt-val.
            {&catch-ret-err}
        end.
    end method.
    

    method public date dateValueISO(iNode as int):
        def var c-val as char no-undo.
        def var yyyy as int no-undo.
        def var mm as int no-undo.
        def var dd as int no-undo.
        def var dt-val as date no-undo.
        _tr:
        do {&err-ret-error}:
            c-val = charValue(iNode).
            yyyy = int(entry(1, c-val, '-')) no-error.
            if error-status:error then leave _tr.
            
            mm = int(entry(2, c-val, '-')) no-error.
            if error-status:error then leave _tr.
            
            dd = int(entry(3, c-val, '-')) no-error. 
            if error-status:error then leave _tr.
            
            dt-val = date(mm, dd, yyyy).
            return dt-val.
            {&catch-ret-err}
        end.
        
        return error subst('&1 должен датой в формате yyyy-mm-dd.~n(получено &2)~n',
                            hNode[iNode]:name, c-val).
    end method.


    method public date dateValueRU(iNode as int):
        def var c-val as char no-undo.
        def var yyyy as int no-undo.
        def var mm as int no-undo.
        def var dd as int no-undo.
        def var dt-val as date no-undo.
        _tr:
        do {&err-ret-error}:
            c-val = charValue(iNode).
            yyyy = int(entry(3, c-val, '.')) no-error.
            if error-status:error then leave _tr.

            mm = int(entry(2, c-val, '.')) no-error.
            if error-status:error then leave _tr.

            dd = int(entry(1, c-val, '.')) no-error.
            if error-status:error then leave _tr.

            dt-val = date(mm, dd, yyyy).
            return dt-val.
            {&catch-ret-err}
        end.

        return error subst('&1 должен датой в формате dd.mm.yyyy.~n(получено &2)~n',
                            hNode[iNode]:name, c-val).
    end method.
    
    
     method public void view(encoding as char):
         def var cfile as char no-undo.
         _tr:
         do {&err-ret-error}:
             run get_tmp_file.p('ext: xml', output cfile).
             hDoc:save('file', cfile).
             clsFileView:viewXML(cfile, encoding).
             {&catch-ret-err}
             finally:
                 os-delete value(cfile).
             end finally.
         end.
    end method.
    
        
    method public void view():
        def var cfile as char no-undo.
        _tr:
        do {&err-ret-error}:
            run get_tmp_file.p('ext: xml', output cfile).
            hDoc:save('file', cfile).
            clsFileView:viewXML(cfile, ?).
            {&catch-ret-err}
            finally:
                os-delete value(cfile).
            end finally.
        end.
    end method.
end class.
/**/