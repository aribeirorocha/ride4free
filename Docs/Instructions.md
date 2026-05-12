# Ride4Free — Como Correr o Projeto

Este guia descreve os passos necessários para configurar o ambiente de desenvolvimento e executar a aplicação **Ride4Free** (Frontend e Backend) utilizando o emulador do Android Studio.

## 📋 Pré-requisitos
* **Git**: Para clonar o repositório.
* **Flutter SDK**: Versão estável.
* **Python 3.10+**: Para o backend FastAPI.
* **Android Studio**: Para gerir a Virtual Machine (AVD).

---

## 🛠️ Passo 1: Configurar a Virtual Machine (Android Studio)
A aplicação necessita de um emulador para ser executada.
1. Abra o **Android Studio**.
2. Clique nos **Três Pontos**
3. Vá a **Virtual Device Manager**.
4. Clique em **Create Device** e escolha um dispositivo (ex: Pixel 7).
5. Selecione uma imagem de sistema (recomendado **API 33** ou superior).
6. Finalize e clique no botão **Play (▶)** para iniciar a Virtual Machine. 
   * *Nota: Mantenha o emulador aberto durante todo o processo.*

---

## ⚙️ Passo 2: Configurar o Backend (Python FastAPI)
Abra um terminal na pasta raiz do projeto:

## Backend (API)

Abrir uma janela de terminal.

```bash
cd backend

python3 -m venv venv

source venv/bin/activate        # Windows: venv\Scripts\activate

pip install -r requirements.txt

uvicorn main:app --reload
```


Deixar janela aberta
---

## 2. App Flutter

Abrir uma nova janela de terminal.

```bash
cd app_test

flutter pub get

flutter devices

flutter run          # ou -d android / -d ios
```

---

## 3. Primeira Utilização

1. Abre a app
2. Entra com os teus dados da faculdade
3. Já podes oferecer ou procurar boleias

> O backend tem de estar a correr antes de abrir a app.
