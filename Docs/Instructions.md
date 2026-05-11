# Ride4Free — Como Correr o Projeto

## Pré-requisitos

- Python 3.10+
- Flutter SDK 3.x

---

## 1. Backend (API)

```bash
cd backend

python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\Activate.ps1

pip install -r requirements.txt

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

A API fica disponível em **http://localhost:8000**.  
Documentação interativa: **http://localhost:8000/docs**

---

## 2. App Flutter

```bash
cd app_test

flutter pub get
flutter run -d chrome           # ou -d android / -d ios
```

---

## 3. Primeira Utilização

1. Abre a app
2. Vai ao separador **Perfil** (ícone de pessoa) e cria uma conta
3. Já podes oferecer ou procurar boleias

> O backend tem de estar a correr antes de abrir a app.
