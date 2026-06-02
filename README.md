# Magic Utils

[![Build and Release .deb](https://github.com/dcoppari/magic-utils/actions/workflows/build.yml/badge.svg)](https://github.com/dcoppari/magic-utils/actions/workflows/build.yml)

**Magic Utils** is a lightweight set of tools for converting PCL to PDF, generating printable QR codes, generating charts, and remotely spooling documents. It's built for legacy environments and automated printing workflows.

Included tools:

- `magicpcl`: converts PCL to PDF, applies background overlays, sends to printer or spools.
- `magicqr`: generates a QR code and outputs a PCL-ready file.
- `magicgraph`: generates a pie, bar, or line chart and outputs a PCL-ready file.
- `magicspool`: sends a Base64-encoded PDF over TCP to a remote spool server.
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
/usr/local/bin/pcl6
/windows/fonts/*.ttf
```

---

## ⚙️ Dependencies

The package includes the `pcl6` binary, but requires the following system tools to be available:

- `bash`, `perl`
- `dos2unix`, `rlpr`, `lpr`
- `pdftk`, `qrencode`, `imagemagick`
- `gnuplot` (required by `magicgraph`)

If installing on Ubuntu or Debian, they will be installed automatically if declared in a `.deb` or can be installed manually:

```bash
sudo apt install dos2unix rlpr lpr pdftk qrencode imagemagick gnuplot
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
