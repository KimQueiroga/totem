# Totem

Frontend Flutter do sistema de autoatendimento do laboratorio.

## Requisitos

- Flutter 3.35.1 ou superior
- Dart 3.9.0 ou superior

## Desenvolvimento

Instalar dependencias:

```bash
flutter pub get
```

Executar:

```bash
flutter run
```

Executar no navegador apontando para o BFF local:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define=BFF_BASE_URL=http://127.0.0.1:8000/api
```

Exemplo de URL do terminal:

```text
http://127.0.0.1:8080/terminal=ihpmgaimtotem1
```

Rodar validacoes:

```bash
flutter analyze
flutter test
```
