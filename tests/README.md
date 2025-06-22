# Testes Automatizados

Este diretório contém testes automatizados para o gerenciador de dotfiles.

## Estrutura de Diretórios

- `fixtures/`: Contém arquivos de teste e configurações necessárias para os testes
- `test-*.sh`: Scripts de teste individuais
- `run-tests.sh`: Script para executar todos os testes

## Como Executar os Testes

1. Navegue até o diretório raiz do projeto:
   ```bash
   cd /caminho/para/dotfiles
   ```

2. Execute o script de testes:
   ```bash
   ./tests/run-tests.sh
   ```

## Testes Disponíveis

- `test-install.sh`: Testa a instalação dos dotfiles
- `test-update.sh`: Testa a atualização dos dotfiles (modo interativo)
- `test-update-noninteractive.sh`: Testa a atualização dos dotfiles (modo não interativo)

## Adicionando Novos Testes

1. Crie um novo script de teste no diretório `tests/`
2. Certifique-se de que o script seja executável (`chmod +x`)
3. Adicione o teste ao `run-tests.sh` se desejar que ele seja executado automaticamente

## Ambiente de Teste

Os testes são executados em um diretório temporário (`/tmp/dotfiles-test/`) para evitar modificar os arquivos do sistema do usuário.
