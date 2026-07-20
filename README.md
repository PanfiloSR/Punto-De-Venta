# Inventario App

Sistema de gestión de inventario compuesto por una **API REST en Node.js/Express** con base de datos **MongoDB**, y una **aplicación móvil en Flutter** que consume dicha API, con autenticación mediante **Firebase Authentication** (JWT).

## 📋 Descripción

La aplicación permite a un usuario autenticado gestionar el inventario de productos de un negocio: consultar, crear, editar, eliminar y registrar ventas (con descuento automático de stock). Todas las peticiones al backend van protegidas por un token JWT emitido por Firebase.

## 🏗️ Arquitectura

```
├── backend/     API REST (Node.js + Express + Mongoose)
└── frontend/    App móvil multiplataforma (Flutter)
```

- **Backend**: expone endpoints REST sobre MongoDB, protegidos con un middleware que valida el header `Authorization: Bearer <token>`.
- **Frontend**: app Flutter que autentica al usuario con Firebase, obtiene el JWT y lo adjunta en cada request al backend mediante `ApiService`.

## 🚀 Tecnologías

**Backend**
- Node.js
- Express 5
- Mongoose 9 (MongoDB)
- CORS

**Frontend**
- Flutter (Android, iOS, Web, Linux, macOS, Windows)
- Firebase Core / Firebase Auth
- `http` para consumo de la API

## ✨ Funcionalidades

- 🔐 **Autenticación** con correo y contraseña vía Firebase, generando un JWT que se usa para autorizar cada petición al backend.
- 📦 **Módulo de productos (CRUD completo)**:
  - Consultar todos los productos
  - Crear un nuevo producto
  - Modificar un producto existente
  - Eliminar un producto
- 💰 **Venta de productos**: descuenta la cantidad vendida del stock, validando que exista inventario suficiente.
- 👥 **Módulo de usuarios** (pantalla en el frontend para administrar usuarios y roles).
- 🛡️ Middleware de validación de JWT en todas las rutas de productos.

## 📡 Endpoints del backend

| Método | Ruta                       | Descripción                              | Auth |
|--------|----------------------------|-------------------------------------------|------|
| GET    | `/`                        | Estado del servidor y de la conexión a BD | No   |
| GET    | `/productos`                | Lista todos los productos                | Sí   |
| POST   | `/productos`                | Crea un nuevo producto                   | Sí   |
| PUT    | `/productos/:id`            | Actualiza un producto                    | Sí   |
| PATCH  | `/productos/:id/vender`     | Registra una venta y descuenta stock     | Sí   |
| DELETE | `/productos/:id`            | Elimina un producto                      | Sí   |

Las rutas protegidas requieren el header:
```
Authorization: Bearer <token_jwt_de_firebase>
```

### Modelo de producto

```js
{
  name: String,          // requerido
  brand: String,          // requerido
  description: String,
  sale_price: Number,     // default 0
  purchase_price: Number, // default 0
  stock: Number,           // default 0
  image_url: String,
  category_id: Number,     // default 1
  provider_id: Number      // default 1
}
```

## ⚙️ Instalación y ejecución

### Backend

```bash
cd backend
npm install
```

Asegúrate de tener MongoDB corriendo localmente (por defecto se conecta a `mongodb://localhost:27017/examen`).

```bash
node server.js
```

El servidor quedará disponible en `http://localhost:3000`.

### Frontend

```bash
cd frontend
flutter pub get
```

Configura tu propio proyecto de Firebase (agrega tu `google-services.json` en `android/app/` y el archivo de configuración correspondiente para iOS/otras plataformas).

En `lib/services/api_service.dart`, ajusta la URL base del backend según el entorno:
- Web (Chrome): `http://localhost:3000`
- Dispositivo físico/emulador: la IP local de tu máquina, por ejemplo `http://10.0.107.181:3000`

Ejecuta la app:

```bash
flutter run
```

## 📁 Estructura del proyecto

```
backend/
  server.js          # API REST y modelo de datos
  package.json

frontend/
  lib/
    main.dart              # Punto de entrada, inicializa Firebase
    login_screen.dart       # Autenticación con Firebase
    productos_screen.dart   # CRUD de productos y ventas
    usuarios_screen.dart    # Gestión de usuarios
    services/
      api_service.dart      # Cliente HTTP hacia el backend, maneja el JWT
  android/ ios/ web/ linux/ macos/ windows/   # Proyectos nativos por plataforma
```

## 🔒 Seguridad

- El backend rechaza con `401` cualquier petición a `/productos` que no incluya un token JWT válido en el header `Authorization`.
- El frontend obtiene el token con `FirebaseAuth` tras el login y lo guarda en `ApiService` para adjuntarlo automáticamente en cada solicitud posterior.

## 📝 Notas

- Este proyecto fue desarrollado como parte de una evaluación académica (examen parcial), por lo que algunas validaciones (como el listado de usuarios) están simuladas/mockeadas en el frontend.
