# Versionamento e Tags

Este projeto utiliza **Semantic Versioning (SemVer)** para controle de versões.

## Formato da Versão
`MAJOR.MINOR.PATCH+BUILD_NUMBER`

- **MAJOR**: Mudanças incompatíveis na API/DB ou grandes refatorações.
- **MINOR**: Novas funcionalidades compatíveis com versões anteriores.
- **PATCH**: Correções de bugs compatíveis com versões anteriores.
- **BUILD_NUMBER**: Número sequencial para builds (usado pelo Android/iOS).

Exemplo: `1.2.0+15`

## Como Atualizar a Versão

1.  Abra o arquivo `pubspec.yaml`.
2.  Localize a linha `version: 1.0.0+1`.
3.  Incremente os números conforme a natureza da mudança.

## Git Tags

Recomendamos o uso de tags do git para marcar lançamentos.

```bash
# Adicionar mudanças
git add .
git commit -m "chore: bump version to 1.2.0"

# Criar a tag
git tag v1.2.0

# Enviar para o repositório
git push origin v1.2.0
```
