# Cameek.W3CssJs.Bootstrap

![NuGet](https://img.shields.io/nuget/v/Cameek.W3CssJs.Bootstrap?label=NuGet&logo=nuget)  
![.NET](https://img.shields.io/badge/.NET-8.0-blue?logo=dotnet)

**Cameek.W3CssJs.Bootstrap** is a Razor Class Library (RCL) that contains static assets (CSS, JavaScript, and Fonts) for [Bootstrap 5](https://getbootstrap.com/).  
It is intended to be referenced from other Blazor or Razor ASP.NET Core projects to enable easy styling and responsive layout support.

This library supports both Blazor WebAssembly and Blazor Server applications.

---

## ✨ Features

- Includes full Bootstrap 5.3.x core (CSS + JS)
- Includes Grid, Reboot, and Utilities modules (minified and RTL)
- Provides Bootstrap JavaScript bundles (standard, bundle, and ESM versions)
- Includes **Bootstrap Icons** CSS + web fonts (`.woff`, `.woff2`)
- Files are accessible under `_content/Cameek.W3CssJs.Bootstrap/`
- Ideal for offline or self-contained Blazor deployment

---

## 📦 Installation

Install from NuGet:

```bash
dotnet add package Cameek.W3CssJs.Bootstrap --version 5.3.2
```

Or add directly to your `.csproj`:

```xml
<PackageReference Include="Cameek.W3CssJs.Bootstrap" Version="5.3.2" />
```

---

## 🛠 Usage

In your `index.html` (Blazor WebAssembly) or `_Host.cshtml` (Blazor Server), include:

### ✅ Basic Bootstrap (CSS + Bundle JS)

```html
<link href="_content/Cameek.W3CssJs.Bootstrap/css/bootstrap.min.css" rel="stylesheet" />
<script src="_content/Cameek.W3CssJs.Bootstrap/js/bootstrap.bundle.min.js"></script>
```

### 🧩 Optional Extensions (Grid, RTL, Utilities)

```html
<link href="_content/Cameek.W3CssJs.Bootstrap/css/bootstrap-grid.min.css" rel="stylesheet" />
<link href="_content/Cameek.W3CssJs.Bootstrap/css/bootstrap-utilities.rtl.min.css" rel="stylesheet" />
```

### 🎨 Bootstrap Icons (Fonts)

```html
<link href="_content/Cameek.W3CssJs.Bootstrap/css/bootstrap-icons.css" rel="stylesheet" />
```

This CSS file will automatically load fonts from:

- `_content/Cameek.W3CssJs.Bootstrap/css/fonts/bootstrap-icons.woff2`
- `_content/Cameek.W3CssJs.Bootstrap/css/fonts/bootstrap-icons.woff`

---

## 📄 License

This package redistributes official Bootstrap and Bootstrap Icons assets under their respective [MIT license](https://github.com/twbs/bootstrap/blob/main/LICENSE).  
See also the included `LICENSE-bootstrap.txt` in the NuGet package.

---

## 👤 Author

Created and maintained by [CameekOrg](https://github.com/cameekorg).  
This project is intended for internal use across Cameek-based Blazor solutions.

---

## 📬 Related Projects

- [Cameek.W3CssJs.PrismJs](https://www.nuget.org/packages/Cameek.W3CssJs.PrismJs) – PrismJS syntax highlighting for Blazor
- [Bootstrap](https://getbootstrap.com/) – Open-source UI toolkit for building responsive web apps
