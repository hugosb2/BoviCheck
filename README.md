# BoviCheck 🐄

![Python](https://img.shields.io/badge/Python-3.9%2B-blue?style=for-the-badge&logo=python)
![Flet](https://img.shields.io/badge/Flet-0.28.3-green?style=for-the-badge&logo=flet)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**BoviCheck** é um aplicativo de desktop e mobile multiplataforma, desenvolvido em Python com o framework Flet, projetado para ser o assistente definitivo de pecuaristas no cálculo e acompanhamento de índices zootécnicos essenciais para a gestão de rebanhos bovinos.

O aplicativo integra uma interface moderna e intuitiva com a poderosa assistência da IA do Google Gemini, fornecendo não apenas cálculos precisos, mas também insights e sugestões para otimizar a produção.

## ✨ Funcionalidades

O BoviCheck oferece um conjunto robusto de ferramentas para a gestão zootécnica:

* **Painel de Controle (Dashboard):** Uma visão geral e resumida com os resultados mais recentes de todos os índices calculados.
* **Cálculo de Índices Zootécnicos:**
    * Taxa de Natalidade
    * Taxa de Desmame
    * Ganho Médio Diário (GMD)
    * Peso ao Desmame Ajustado (P205)
    * Taxa de Mortalidade
    * E muitos outros.
* **Histórico Detalhado:**
    * Visualize o histórico de todos os cálculos para cada índice.
    * Gráficos de barra para acompanhamento visual do progresso.
    * Edite ou exclua medições individuais.
* **Assistente com IA (Google Gemini):**
    * **Chat Inteligente:** Converse com a IA para tirar dúvidas e pedir análises sobre os dados inseridos.
    * **Sugestões Contextuais:** Receba dicas e análises geradas pela IA diretamente no Dashboard e nas telas de histórico dos índices.
* **Gerenciamento de Dados:**
    * **Backup e Restauração:** Crie backups de segurança de todos os seus dados em um único arquivo `.json` e restaure-os a qualquer momento.
    * **Exportação para Planilha:** Exporte os dados selecionados para um arquivo Excel (`.xlsx`) para análises externas.
    * **Exclusão Segura:** Opções para apagar o histórico de um índice específico ou todos os dados do aplicativo.
* **Personalização Completa:**
    * **Modo de Tema:** Escolha entre os modos Claro, Escuro ou o padrão do sistema.
    * **Cores do Tema:** Personalize a cor primária do aplicativo com uma vasta paleta de opções para criar um visual que mais lhe agrada.

## 🛠️ Tecnologias Utilizadas

Este projeto foi construído utilizando as seguintes tecnologias:

* **Python 3.9+**
* **Flet:** Framework principal para a construção da interface gráfica.
* **Requests:** Para realizar as chamadas à API do Google Gemini.
* **OpenPyXL:** Para a funcionalidade de exportação para planilhas Excel.
* **python-dotenv:** Para o gerenciamento seguro de chaves de API.

## 🚀 Instalação e Execução

Para executar o BoviCheck em seu ambiente de desenvolvimento local, siga os passos abaixo.

**1. Clone o Repositório**
```bash
git clone [https://github.com/seu-usuario/BoviCheck.git](https://github.com/seu-usuario/BoviCheck.git)
cd BoviCheck
```

**2. Crie e Ative um Ambiente Virtual** (Recomendado)
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate
```

**3. Instale as Dependências**
O projeto utiliza um `pyproject.toml` para gerenciar as dependências. Instale-as com o pip:
```bash
pip install .
```

**4. Configure as Variáveis de Ambiente**
Para usar as funcionalidades de IA, você precisa de uma chave de API do Google Gemini.

* Crie um arquivo chamado `.env` na raiz do projeto.
* Adicione sua chave de API a este arquivo:
    ```
    GEMINI_API_KEY=SUA_CHAVE_DE_API_AQUI
    ```

**5. Execute o Aplicativo**
```bash
python src/main.py
```

## 📂 Estrutura do Projeto

O código está organizado seguindo a arquitetura **MVC (Model-View-Controller)** para garantir a separação de responsabilidades e a manutenibilidade:

* `src/main.py`: Ponto de entrada da aplicação.
* `src/controllers/`: Contém a lógica de controle que conecta os Models e as Views.
* `src/models/`: Contém a lógica de negócio, as estruturas de dados (`AppState`) e a comunicação com serviços externos (cálculos, persistência, API).
* `src/views/`: Responsável por construir e apresentar todos os componentes visuais da interface.
* `src/utils/`: Funções auxiliares e utilitários.
* `assets/`: Ícones e outras mídias.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Contato

Hugo Barros – [hugobs4987@gmail.com](mailto:hugobs4987@gmail.com)

Link do Projeto: [https://github.com/seu-usuario/BoviCheck](https://github.com/seu-usuario/BoviCheck)