# flutter_translate_localizer

A Dart CLI tool that reads a YAML configuration file and automatically translates
your JSON language files into multiple target languages using the Google Translate
public API.

---

## Features

- 📝 **YAML-driven configuration** – declare source and target languages in a
  single `translate_config.yaml`.
- 🌐 **Automatic translation** – uses Google Translate (no API key required).
- 🗂️ **Nested JSON support** – traverses arbitrarily nested JSON objects and
  lists, translating every string value.
- 📁 **Configurable paths** – override the source and output directories in the
  YAML file.
- ⚡ **CLI executable** – run with a single `dart run` command.

---

## Getting started

### 1. Add the dependency

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_translate_localizer: ^1.0.0
```

Or install globally:

```bash
dart pub global activate flutter_translate_localizer
```

### 2. Create the configuration file

Add a `translate_config.yaml` to your project root:

```yaml
# Minimum configuration
source:
  - en          # language code of the source JSON file

output:
  - es          # one or more target language codes
  - ar
```

With custom directories:

```yaml
source:
  - en

output:
  - es
  - ar

# Directory that contains the source JSON file (default: lib/lang)
source_destination:
  - assets/lang

# Directory where translated files will be saved (default: lib/lang)
translated_destination:
  - lib/translated
```

File extension can be provided and to cover the arb nomenclature you can provide the prefix of the file name e.g suffix can be provided as "arb_" then the translated file will be arb_en.arb:

```yaml
source:
  - en

output:
  - ar
  - es


file_extension:
  - arb

file_name_prefix:
  - arb_
```

### 3. Create the source language file

Place your source JSON at the path specified by `source_destination`
(`lib/lang` by default).  Example – `lib/lang/en.json`:

```json
{
  "welcome": "Welcome",
  "goodbye": "Goodbye",
  "greetings": {
    "hello": "Hello",
    "good_morning": "Good morning"
  }
}
```

### 4. Run the tool

```bash
dart run flutter_translate_localizer
```

Or, if activated globally:

```bash
flutter_translate
```

The tool will create `es.json`, `ar.json` etc. inside the
`translated_destination` directory.

---

## CLI options

| Flag | Short | Default | Description |
|---|---|---|---|
| `--config` | `-c` | `translate_config.yaml` | Path to the YAML config file |
| `--verbose` | `-v` | `false` | Print progress messages |
| `--help` | `-h` | | Show usage information |

```bash
dart run flutter_translate_localizer --config path/to/config.yaml --verbose
```

---

## Supported language codes

Use standard [BCP 47 / ISO 639-1](https://cloud.google.com/translate/docs/languages)
language codes, for example:

| Code | Language |
|------|----------|
| `en` | English |
| `es` | Spanish |
| `ar` | Arabic |
| `fr` | French |
| `de` | German |
| `zh` | Chinese (Simplified) |
| `ja` | Japanese |
| `pt` | Portuguese |

---

## Project structure

```
your_project/
├── translate_config.yaml   ← configuration
├── lib/
│   └── lang/
│       ├── en.json         ← source file
│       ├── es.json         ← generated
│       └── ar.json         ← generated
└── pubspec.yaml
```

---

## Contributing

Pull requests are welcome.  Please run the tests before submitting:

```bash
dart test
```

---

## License

MIT