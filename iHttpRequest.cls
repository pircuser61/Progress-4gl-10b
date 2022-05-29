/*
  Цель - сделать зпросы не зависящими от транспорта, 
  есть clsCurl, и clsSocket 
  Socket - доволньне быстрые, но не могут в proxy, и не тестировались на больших файлах
*/

interface iHttpRequest:
    method public void post(fileIn as char, fileOut as char).

    method public iHttpRequest ContentType(c-type as char).
    method public iHttpRequest AcceptType(c-type as char).
    method public iHttpRequest proxy().
    method public iHttpRequest proxy(proxy as char).
    method public iHttpRequest Header(c-key as char, c-val as char).
end interface.
