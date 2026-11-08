
# Cameek.W3CssJs.Mermaid

![NuGet](https://img.shields.io/nuget/v/Cameek.W3CssJs.Mermaid?label=NuGet&logo=nuget)  
![.NET](https://img.shields.io/badge/.NET-8.0-blue?logo=dotnet)

**Cameek.W3CssJs.Mermaid** is a Razor Class Library (RCL) that contains static assets (JavaScript) for [MermaidJS](https://mermaid-js.github.io/mermaid/).  
It is intended to be referenced from other Blazor or Razor ASP.NET Core projects to enable easy rendering of diagrams and flowcharts from simple text definitions.

This library supports both Blazor WebAssembly and Blazor Server applications.

The package now bundles **Mermaid 11.17.2**, the current stable release in the
Mermaid 11 series. It retains the existing browser and ESM URLs and includes
their complete local module dependencies. No CDN access is needed at runtime.

The additional `mermaid.core.mjs` file is upstream's unbundled entrypoint for
bundler users. It requires Mermaid's upstream npm dependencies and is not a
standalone browser script. Use the two `PathsMermaid` entrypoints below for
packaged offline browser rendering.

### Refreshing the bundled files

Contributors need Python 3 for the download helpers:

```bash
bash .scripts/download-mermaid.sh
```

On Windows, run `.scripts/download-mermaid.ps1` or `.scripts/download-mermaid.bat`.
All three launchers use the same pinned version in `download-mermaid.py`. The
helper downloads the official npm archive, verifies its SHA-512 integrity, and
copies the browser dependency closure and packaged MIT license without rewriting
JavaScript. Old hashed chunks are removed after the new distribution is verified.

---

## ✨ Features

- Includes **MermaidJS** (`mermaid.min.js`) for direct browser usage
- Includes **MermaidJS ESM** module (`mermaid.esm.min.mjs`) for modern environments
- Files are accessible under `_content/Cameek.W3CssJs.Mermaid/`
- No external CDN dependency required after deployment
- Ideal for offline use or self-contained Blazor apps

---

## 📦 Installation

Install from NuGet:

```bash
dotnet add package Cameek.W3CssJs.Mermaid --version 11.17.2
```

Or add directly to your `.csproj`:

```xml
<PackageReference Include="Cameek.W3CssJs.Mermaid" Version="11.17.2" />
```

---

## 🛠 Usage

In your `index.html` (Blazor WebAssembly) or `_Host.cshtml` (Blazor Server), include:

### ✅ Browser (Standard)

```html
<script src="_content/Cameek.W3CssJs.Mermaid/js/mermaid.min.js"></script>

<script>
  mermaid.initialize({ startOnLoad: true });
</script>
```

### ✅ ESM (Optional Advanced Setup)

If you are working in an ESM-compatible setup:

```html
<script type="module">
  import mermaid from '_content/Cameek.W3CssJs.Mermaid/js/mermaid.esm.min.mjs';
  mermaid.initialize({ startOnLoad: true });
</script>
```

---

## 🎯 Example

```html
<div class="mermaid">
graph TD
    A[Start] --> B{Is it working?}
    B -- Yes --> C[Great!]
    B -- No --> D[Check Logs]
</div>
```

Mermaid will automatically render the diagram from the text inside the `<div class="mermaid">`.

---

## 📄 License

This package redistributes official MermaidJS assets under their original [MIT license](https://github.com/mermaid-js/mermaid/blob/develop/LICENSE).  
See the included `LICENSE-mermaid.txt` inside the NuGet package.

---

## 👤 Author

Created and maintained by [CameekOrg](https://github.com/cameekorg).  
This project is intended for internal use across Cameek-based Blazor solutions.

---

## 📬 Related Projects

- [Cameek.W3CssJs.Bootstrap](https://www.nuget.org/packages/Cameek.W3CssJs.Bootstrap) – Bootstrap 5 packaged for Blazor apps
- [Cameek.W3CssJs.PrismJs](https://www.nuget.org/packages/Cameek.W3CssJs.PrismJs) – PrismJS syntax highlighting for Blazor
- [MermaidJS](https://mermaid-js.github.io/mermaid/) – Generation of diagrams and flowcharts from text
