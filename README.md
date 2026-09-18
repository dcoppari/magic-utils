# Magic Utils

[![Build and Release .deb](https://github.com/dcoppari/magic-utils/actions/workflows/build.yml/badge.svg)](https://github.com/dcoppari/magic-utils/actions/workflows/build.yml)

**Magic Utils** is a lightweight set of tools for converting PCL to PDF, generating printable QR codes, generating charts, printing ESC/POS receipts on thermal printers, and remotely spooling documents. It's built for legacy environments and automated printing workflows.

Included tools:

- `magicpcl`: converts PCL to PDF, applies background overlays, sends to printer or spools.
- `magicqr`: generates a QR code and outputs a PCL-ready file.
- `magicgraph`: generates a pie, bar, or line chart and outputs a PCL-ready file.
- `magicspool`: sends a Base64-encoded PDF over TCP to a remote spool server.
- `magicescpos`: generates ESC/POS binary receipts from JSON data using Jinja2 templates for thermal printers.
- `pcl6`: bundled binary to convert PCL to PDF.
- `fonts` font files for standalone usage (required by pcl6).

---

## 📦 Installation

1. Download the `.deb` package from the [Releases section](https://github.com/dcoppari/magic-utils/releases).
2. Install it:

```bash
sudo dpkg -i magic-utils_*.deb
```

The following files will be installed:

```
/usr/local/bin/magicpcl
/usr/local/bin/magicqr
/usr/local/bin/magicgraph
/usr/local/bin/magicspool
/usr/local/bin/magicescpos
/usr/local/bin/pcl6
/windows/fonts/*.ttf
```

---

## 🏷️ Releasing (maintainers)

Pushing a `v*` tag triggers `.github/workflows/build.yml`, which runs the test suite, builds the `.deb`, and publishes it as a GitHub Release. The job only runs if `base_ref` on the push event resolves to `refs/heads/master` — that field is **not** reliably set when a tag is pushed by itself (`git tag vX.Y.Z && git push origin vX.Y.Z`) once `master` is already up to date on the remote; the job then silently shows as **skipped** in Actions, with no error and no release.

To cut a release reliably:

```bash
git tag vX.Y.Z
git push origin master vX.Y.Z   # push the tag together with master in the same push
```

or create the release/tag from the GitHub UI targeting `master`. Either way, confirm it actually ran:

```bash
gh run list --workflow=build.yml --limit 1
```

---

## ⚙️ Dependencies

The package includes the `pcl6` binary, but requires the following system tools to be available:

- `bash`, `perl`
- `dos2unix`, `rlpr`, `lpr`
- `pdftk`, `qrencode`, `imagemagick`
- `gnuplot` (required by `magicgraph`)
- `python3`, `python3-jinja2` (required by `magicescpos`)

If installing on Ubuntu or Debian, they will be installed automatically if declared in a `.deb` or can be installed manually:

```bash
sudo apt install dos2unix rlpr lpr pdftk qrencode imagemagick gnuplot python3-jinja2
```

---

## 🚀 Quick Usage

### Convert PCL to PDF and spool

```bash
cat file.pcl | magicpcl -S output.pdf
```

### Print directly using rlpr

```bash
cat file.pcl | magicpcl -D output.pdf NoBackground PrinterName
```

### Generate QR code and convert to PCL

```bash
magicqr "https://example.com/invoice/1234" qr-code.pcl
```

### Generate a chart and convert to PCL

```bash
# Inline data
magicgraph pie "Ventas:40,Costos:30,Otros:30" torta.pcl 800 800

# From a CSV file
magicgraph bar ventas.csv barras.pcl 1000 600

# Line chart with default size (600x600)
magicgraph line consumo.csv linea.pcl
```

### Send a file to a remote spooler

```bash
magicspool output.pdf 192.168.1.10 6123
```

### Generate ESC/POS receipts for thermal printers

`magicescpos` renders receipt data from JSON into binary ESC/POS printer commands using Jinja2 templates. It supports CP437 character encoding, configurable column widths (e.g. 58mm / 80mm printers), formatting tags, and automated AFIP QR code generation (RG 4892/2020).

```bash
# Print receipt directly to a thermal printer
magicescpos comprobante.json | lp -s -dtickeadora

# Pipe JSON from STDIN
cat comprobante.json | magicescpos | lp -s -dtickeadora

# Save ESC/POS binary stream to a file
magicescpos comprobante.json > ticket.bin

# Specify column width (default: 40 cols; e.g. 32 cols for 58mm)
magicescpos comprobante.json -cols 32 | lp -s -dtickeadora

# Use a custom Jinja2 template (.j2)
magicescpos comprobante.json -t mi_plantilla.j2 > ticket.bin
```

#### Template ESC/POS Tags

The Jinja2 template can include the following embedded ESC/POS formatting tags:

| Tag | Description | ESC/POS Command |
| --- | --- | --- |
| `[init]` | Initialize / reset printer | `ESC @` |
| `[mode-a]` | Select standard Font A mode | `ESC ! 0` |
| `[center]` | Align text to center | `ESC a 1` |
| `[left]` | Align text to left | `ESC a 0` |
| `[right]` | Align text to right | `ESC a 2` |
| `[bold]`, `[/bold]` | Turn bold on / off | `ESC E 1` / `ESC E 0` |
| `[line]` | Dashed separator line (`-` repeated to column width) | Dynamic |
| `[double-line]` | Double separator line (`=` repeated to column width) | Dynamic |
| `[feed]` | Line feed (1 line) | `\n` |
| `[feed:N]` | Advance paper N lines (e.g., `[feed:2]`) | `ESC d N` |
| `[cut]` | Full paper cut | `GS V A 3` |
| `[drawer]` | Kick cash drawer pulse | `ESC p 0` |
| `[qr:DATA]` | Print native ESC/POS 2D QR Code | `GS ( k ...` |

#### Template Filters

- `pad_left(width, char=" ")`: Right-aligns string, padding with spaces (or custom char) on the left.
- `pad_right(width, char=" ")`: Left-aligns string, padding with spaces (or custom char) on the right.
- `truncate_str(width)`: Truncates string to specified width.
- `format_date`: Formats date strings to `DD/MM/YYYY`.
- `money(decimals=2)`: Formats numbers with thousands separator (commas) and rounded decimal points.

#### JSON Data Structure

The input JSON format expects three main keys:

- **`settings`**: Store and issuer details (`nombre`, `direccion`, `cuit`, `iibb`, `categoria_iva`). Setting `afip960` with the AFIP QR base URL (e.g., `"https://www.afip.gob.ar/fe/qr/?p="`) automatically generates and embeds a compliant AFIP QR code.
- **`header`**: Document metadata (`puesto`, `nro_movimiento`, `concepto_afip`, `descripcion_concepto`, `letra_movimiento`, `cuit_cliente`, `nombre_cliente`, `numero_cae`, `fecha_cae`, `importe_movimiento`, etc.).
- **`detail`**: Array of items (`codigo_detalle`, `descripcion_detalle`, `cantidad_detalle`, `alicuota_iva`, `neto_detalle`, `iva_detalle`, `exento_detalle`, etc.).

---

## 🛠️ Build from source

To generate the `.deb` package locally:

```bash
make
```

This will produce:

```
magic-utils_1.0.0_amd64.deb
```

## 📖 OpenEdge / Progress ABL

See [OPENEDGE.md](OPENEDGE.md) for:
- Using `magicspool.p` to send files, URLs, and notifications to a browser frontend.
- Printing QR codes and charts directly from ABL using `magicqr` and `magicgraph`.

---

## 👤 Author

Developed by **Diego Javier Coppari**
Contact: https://github.com/dcoppari

---

## License

This software is licensed under the **GNU Lesser General Public License (LGPL)**.
