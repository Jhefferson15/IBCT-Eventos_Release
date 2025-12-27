# Processo de Release

Este documento descreve como gerar builds de produção e lançar novas versões.

## Pré-requisitos
- Certifique-se de ter atualizado a versão no `pubspec.yaml` (veja [VERSIONING.md](VERSIONING.md)).
- Verifique se o arquivo `.env` de produção está configurado corretamente.

## Gerando o Build

### Android
Para gerar um App Bundle (.aab) para a Play Store:
```bash
flutter build appbundle --release
```

Para gerar um APK para testes ou distribuição direta:
```bash
flutter build apk --release
```

O arquivo gerado estará em `build/app/outputs/bundle/release/` ou `build/app/outputs/flutter-apk/`.

### iOS
Para gerar o arquivo para o TestFlight/App Store:
```bash
flutter build ios --release
```
_Nota: Requer Xcode e macOS._

## GitHub Releases

1.  Vá até a aba "Releases" no GitHub.
2.  Clique em "Draft a new release".
3.  Selecione a tag criada (ex: `v1.2.0`).
4.  Adicione um título e descrição (Changelog).
5.  (Opcional) Anexe os arquivos `.apk` ou `.aab` gerados.
6.  Clique em "Publish release".
