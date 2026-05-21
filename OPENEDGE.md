# Referencia de casos de uso en OpenEdge usando `magicspool.p`

## Llamada al procedimiento

```openedge
RUN magicspool.p (
    INPUT wCategory,   /* "FILE" | "URL" | "NOTIFICATION" */
    INPUT wAction,     /* depende de la categoría, ver abajo */
    INPUT wTitle,      /* nombre de archivo / etiqueta / título */
    INPUT wBody        /* ruta de archivo, URL, o texto del mensaje */
).
```

---

## Categoría `FILE`

`wBody` debe ser la **ruta absoluta** de un archivo existente en el servidor. El procedimiento lo lee,
lo codifica en base64 y lo envía. El archivo debe tener extensión (`reporte.pdf`, `datos.xlsx`, etc.).

### `download` — El usuario descarga el archivo

```openedge
RUN magicspool.p (
    INPUT "FILE",
    INPUT "download",
    INPUT "reporte-ventas.pdf",
    INPUT "/tmp/reporte-ventas.pdf"
).
```

El browser presenta el diálogo de descarga con el nombre `reporte-ventas.pdf`.

---

### `display` — El archivo se abre en el visor integrado

```openedge
RUN magicspool.p (
    INPUT "FILE",
    INPUT "display",
    INPUT "factura-001.pdf",
    INPUT "/tmp/facturas/factura-001.pdf"
).
```

Abre el PDF (o imagen, CSV, etc.) en la pestaña del visor sin descargarlo. El MIME se detecta
automáticamente por los bytes del archivo; para formatos de texto, se infiere desde la extensión
del nombre de archivo.

---

### `display` — CSV: tabla interactiva

Extensión requerida: `.csv`

```openedge
RUN magicspool.p (
    INPUT "FILE",
    INPUT "display",
    INPUT "ventas-mayo.csv",
    INPUT "/tmp/reportes/ventas-mayo.csv"
).
```

El visor renderiza las columnas con cabeceras y paginación. La primera fila se trata como encabezado.

---

### `display` — Markdown: documento renderizado

Extensión requerida: `.md`

```openedge
RUN magicspool.p (
    INPUT "FILE",
    INPUT "display",
    INPUT "instructivo-cierre.md",
    INPUT "/tmp/docs/instructivo-cierre.md"
).
```

El visor renderiza el Markdown con formato (títulos, listas, tablas, código). El usuario puede
alternar entre la vista renderizada y el fuente crudo.

---

### `display` — ICS: visor de calendario

Extensión requerida: `.ics`

```openedge
RUN magicspool.p (
    INPUT "FILE",
    INPUT "display",
    INPUT "reunion-clientes.ics",
    INPUT "/tmp/agenda/reunion-clientes.ics"
).
```

Muestra los eventos del archivo iCalendar (título, fecha, descripción, ubicación). Útil para
enviar turnos, reuniones o vencimientos al usuario activo en el terminal.

---

### `display` — KML: mapa interactivo

Extensión requerida: `.kml`

```openedge
RUN magicspool.p (
    INPUT "FILE",
    INPUT "display",
    INPUT "zonas-reparto.kml",
    INPUT "/tmp/geo/zonas-reparto.kml"
).
```

Abre un mapa Leaflet/OpenStreetMap con las geometrías del archivo. Soporta `Point`,
`LineString`, `Polygon` y `MultiGeometry` (un nivel de profundidad). Las descripciones de los
placemarks se muestran como texto plano al hacer click.

---

### `print` — Enviar a imprimir (fallback a descarga)

```openedge
RUN magicspool.p (
    INPUT "FILE",
    INPUT "print",
    INPUT "orden-compra.pdf",
    INPUT "/tmp/oc-2026-001.pdf"
).
```

> **Nota:** el frontend actual no tiene soporte nativo de impresión; la acción `print` se traduce
> a `download` internamente. El usuario descarga el archivo y lo imprime desde el visor de PDF
> del browser.

---

### Tabla de extensiones soportadas en `display`

| Extensión                           | MIME resuelto                          | Renderer               |
|-------------------------------------|----------------------------------------|------------------------|
| `.pdf`                              | `application/pdf` (magic bytes)        | PDF nativo del browser |
| `.png` `.jpg` `.gif` `.webp` `.svg` | `image/*` (magic bytes)                | Imagen                 |
| `.mp3` `.ogg` `.wav` `.aac`         | `audio/*` (magic bytes)                | Audio                  |
| `.mp4` `.webm`                      | `video/*` (magic bytes)                | Video                  |
| `.csv`                              | `text/csv` (extensión)                 | Tabla interactiva      |
| `.md`                               | `text/markdown` (extensión)            | Markdown renderizado   |
| `.ics`                              | `text/calendar` (extensión)            | Visor de calendario    |
| `.html` `.htm`                      | `text/html` (extensión)                | HTML embebido          |
| `.xml`                              | `application/xml` (extensión)          | XML con resaltado      |
| `.json`                             | `application/json` (extensión)         | JSON con resaltado     |
| `.txt`                              | `text/plain` (extensión)               | Texto plano            |
| `.kml`                              | `application/vnd.google-earth.kml+xml` (extensión) | Mapa Leaflet/OSM |

---

## Categoría `URL`

`wBody` es una URL absoluta (`https://…`) o una ruta relativa que empiece con `/`.
`wTitle` es el nombre que aparece en la pestaña del browser.

### `_self` — Abrir URL en el iframe embebido

```openedge
RUN magicspool.p (
    INPUT "URL",
    INPUT "_self",
    INPUT "Consulta de stock",
    INPUT "https://erp.interno/stock?item=A100"
).
```

Carga la URL dentro del iframe integrado en la sesión activa.

---

### `_blank` — Abrir URL en nueva pestaña del browser

```openedge
RUN magicspool.p (
    INPUT "URL",
    INPUT "_blank",
    INPUT "Portal de pagos",
    INPUT "https://pagos.proveedor.com/factura/4567"
).
```

Abre la URL en una pestaña nueva del browser del usuario.

---

### `_top` — Abrir a nivel superior (mapeado a pestaña nueva)

```openedge
RUN magicspool.p (
    INPUT "URL",
    INPUT "_top",
    INPUT "Reporte externo",
    INPUT "https://reportes.ejemplo.com/anual"
).
```

Semánticamente apunta a la ventana raíz; el frontend lo trata igual que `_blank` (pestaña nueva).

---

## Categoría `NOTIFICATION`

Muestra un mensaje flotante en la sesión del usuario. Al menos uno de `wTitle` o `wBody` debe
ser no vacío.

### `success` — Operación exitosa

```openedge
RUN magicspool.p (
    INPUT "NOTIFICATION",
    INPUT "success",
    INPUT "Factura generada",
    INPUT "La factura 001-00042 fue emitida correctamente."
).
```

---

### `info` — Información al usuario

```openedge
RUN magicspool.p (
    INPUT "NOTIFICATION",
    INPUT "info",
    INPUT "Sincronización",
    INPUT "Los precios fueron actualizados desde el servidor central."
).
```

---

### `warning` — Advertencia no bloqueante

```openedge
RUN magicspool.p (
    INPUT "NOTIFICATION",
    INPUT "warning",
    INPUT "Stock bajo",
    INPUT "El artículo A-100 tiene menos de 5 unidades en depósito."
).
```

---

### `error` — Error recuperable

```openedge
RUN magicspool.p (
    INPUT "NOTIFICATION",
    INPUT "error",
    INPUT "Fallo en impresión",
    INPUT "No se pudo conectar con la impresora LP-02. Reintente."
).
```

---

### `critical` — Error crítico / alerta urgente

```openedge
RUN magicspool.p (
    INPUT "NOTIFICATION",
    INPUT "critical",
    INPUT "Cierre de caja fallido",
    INPUT "Error al persistir el cierre. Contacte a sistemas de inmediato."
).
```

---

### Notificación solo con título (sin cuerpo)

```openedge
RUN magicspool.p (
    INPUT "NOTIFICATION",
    INPUT "success",
    INPUT "Proceso finalizado",
    INPUT ""
).
```

### Notificación solo con cuerpo (sin título)

```openedge
RUN magicspool.p (
    INPUT "NOTIFICATION",
    INPUT "info",
    INPUT "",
    INPUT "El batch nocturno terminó sin errores."
).
```

---

## Tabla resumen general

| Categoría      | `wAction`                                                  | `wTitle`               | `wBody`                           | Efecto en el browser               |
|----------------|------------------------------------------------------------|------------------------|-----------------------------------|------------------------------------|
| `FILE`         | `download`                                                 | Nombre del archivo     | Ruta del archivo en el servidor   | Diálogo de descarga                |
| `FILE`         | `display`                                                  | Nombre del archivo     | Ruta del archivo en el servidor   | Abre el visor integrado            |
| `FILE`         | `print`                                                    | Nombre del archivo     | Ruta del archivo en el servidor   | Descarga (print sin soporte aún)   |
| `URL`          | `_self`                                                    | Etiqueta de la pestaña | URL o ruta `/…`                   | Abre en iframe                     |
| `URL`          | `_blank`                                                   | Etiqueta de la pestaña | URL o ruta `/…`                   | Nueva pestaña del browser          |
| `URL`          | `_top`                                                     | Etiqueta de la pestaña | URL o ruta `/…`                   | Nueva pestaña (fallback de `_top`) |
| `NOTIFICATION` | `success` / `info` / `warning` / `error` / `critical`      | Opcional               | Opcional (al menos uno requerido) | Mensaje flotante con severidad     |

---

## Restricciones a tener en cuenta

- **Extensión obligatoria**: el nombre del archivo (`wTitle` en FILE) debe tener extensión. `reporte` → rechazado; `reporte.pdf` → válido.

- **Sin path traversal**: `../etc/passwd` en `wTitle` es rechazado por el servidor.

- **Archivo debe existir**: si `wBody` es una ruta que no existe en disco, el `FILE-INFO:FULL-PATHNAME` devuelve `?` y el procedimiento hace `RETURN` sin enviar nada.

- **`SESSION_ID` vacío**: si la variable de entorno no está seteada, el servidor rechaza el mensaje con `ERROR: Missing required attribute`.

- **Debug**: cada llamada sobreescribe `/tmp/[SESSION_ID]_last_message.xml` con el XML enviado — útil para diagnosticar sin necesidad de sniffear el socket.
