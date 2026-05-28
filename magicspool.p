/* Par metros de entrada */
DEF INPUT PARAMETER wCategory  AS CHAR NO-UNDO.
DEF INPUT PARAMETER wAction    AS CHAR NO-UNDO.
DEF INPUT PARAMETER wTitle     AS CHAR NO-UNDO.
DEF INPUT PARAMETER wBody      AS CHAR NO-UNDO.

/* Variables para manejo del documento XML */
DEF VAR hText        AS HANDLE   NO-UNDO.
DEF VAR hSocket      AS HANDLE   NO-UNDO.
DEF VAR hDoc         AS HANDLE   NO-UNDO.
DEF VAR hRoot        AS HANDLE   NO-UNDO.
DEF VAR hBody        AS HANDLE   NO-UNDO.

/* Variables para manejo de Sockets y Archivos */
DEF VAR mFileContent AS MEMPTR   NO-UNDO.
DEF VAR mMessage     AS MEMPTR   NO-UNDO.
DEF VAR lcXml        AS LONGCHAR NO-UNDO.
DEF VAR cFinalBody   AS LONGCHAR NO-UNDO.

/* Variables de entorno y configuraci¢n */
DEF VAR cSpoolerHost AS CHAR     NO-UNDO.
DEF VAR cSpoolerPort AS CHAR     NO-UNDO.
DEF VAR cSessionId   AS CHAR     NO-UNDO.

/* 1. Recuperar configuraci¢n del entorno */
cSpoolerHost = OS-GETENV("SPOOLER_HOST").
cSpoolerPort = OS-GETENV("SPOOLER_PORT").
cSessionId   = OS-GETENV("SESSION_ID").

/* Asignar valores por defecto si no existen en el entorno */
IF cSpoolerHost = "" OR cSpoolerHost = ? THEN cSpoolerHost = "127.0.0.1".
IF cSpoolerPort = "" OR cSpoolerPort = ? THEN cSpoolerPort = "6123".

/* 2. Procesar el cuerpo del mensaje (Validar si es un archivo) */
cFinalBody = wBody.

IF wCategory = "FILE" AND wBody <> "" THEN DO:
    FILE-INFO:FILE-NAME = wBody.
    IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
        COPY-LOB FROM FILE wBody TO mFileContent.
        cFinalBody = BASE64-ENCODE(mFileContent).
        SET-SIZE(mFileContent) = 0.
    END.
    ELSE RETURN.
END.

/* 3. Construir el documento XML (Sintaxis compatible con 10.2B) */
CREATE X-DOCUMENT hDoc.

CREATE X-NODEREF hRoot.
CREATE X-NODEREF hBody.
CREATE X-NODEREF hText.

/* Crear nodo ra¡z <message> */
hDoc:CREATE-NODE(hRoot, "message", "ELEMENT").
hDoc:APPEND-CHILD(hRoot).

/* Asignar atributos al nodo ra¡z */
hRoot:SET-ATTRIBUTE("category",   wCategory).
hRoot:SET-ATTRIBUTE("action",     wAction).

IF wTitle <> ? AND wTitle <> "" THEN
    hRoot:SET-ATTRIBUTE("title", wTitle).

IF cSessionId <> ? AND cSessionId <> "" THEN
    hRoot:SET-ATTRIBUTE("session_id", cSessionId).

/* Crear y anidar el nodo <body> y su texto interno */
IF cFinalBody <> "" THEN DO:
    hDoc:CREATE-NODE(hBody, "body", "ELEMENT").
    hRoot:APPEND-CHILD(hBody).
    hDoc:CREATE-NODE(hText, "", "TEXT").
    hText:LONGCHAR-TO-NODE-VALUE(cFinalBody).
    hBody:APPEND-CHILD(hText).
END.

/* Volcar el XML a la variable LONGCHAR */
hDoc:SAVE("LONGCHAR", lcXml).

/* --- Grabar a fichero para auditor¡a --- */
DEF VAR cDebugPath AS CHAR NO-UNDO.
cDebugPath = "/tmp/" + cSessionId + "_last_message.xml".
COPY-LOB FROM lcXml TO FILE cDebugPath.

/* 4. Enviar el XML a trav‚s del Socket */
CREATE SOCKET hSocket.
hSocket:CONNECT("-H " + cSpoolerHost + " -S " + cSpoolerPort) NO-ERROR.

IF hSocket:CONNECTED() THEN DO:
    /* Preparar el buffer de memoria con el tama¤o exacto del XML + nulo */
    SET-SIZE(mMessage) = LENGTH(lcXml) + 1.
    PUT-STRING(mMessage, 1) = lcXml.

    /* Escribir en el socket descontando el car cter nulo final */
    hSocket:WRITE(mMessage, 1, GET-SIZE(mMessage) - 1).
    hSocket:DISCONNECT().
END.
ELSE MESSAGE "Fallo de conexi¢n al Spooler" VIEW-AS ALERT-BOX ERROR.

/* 5. Limpieza garantizada de recursos (Handles y Memoria) */
FINALLY:
    IF VALID-HANDLE(hSocket) THEN DELETE OBJECT hSocket.
    IF VALID-HANDLE(hDoc)    THEN DELETE OBJECT hDoc.
    IF VALID-HANDLE(hRoot)   THEN DELETE OBJECT hRoot.
    IF VALID-HANDLE(hBody)   THEN DELETE OBJECT hBody.
    IF VALID-HANDLE(hText)   THEN DELETE OBJECT hText.

    SET-SIZE(mFileContent) = 0.
    SET-SIZE(mMessage)     = 0.
END FINALLY.
