# GuerreroBarberApp

Aplicación móvil desarrollada en Flutter para la gestión de una barbería, con funcionalidades tanto para administradores como para clientes. Permite la administración de citas, clientes y notificaciones, integrando servicios de Firebase y otras herramientas modernas.

## Características principales

- **Gestión de clientes:** Visualización y administración de la lista de clientes registrados.
- **Citas pendientes:** Panel para aprobar o rechazar citas solicitadas por los clientes, con notificaciones automáticas.
- **Calendario de citas:** Visualización de todas las citas agendadas en un calendario interactivo.
- **Historial y configuración:** Acceso al historial de clientes y ajustes del administrador.
- **Notificaciones push:** Integración con Firebase Messaging para notificar a los usuarios sobre el estado de sus citas.
- **Autenticación y almacenamiento:** Uso de Firebase Auth y Firebase Storage para la gestión de usuarios y archivos.
- **Soporte para múltiples servicios:** Permite agregar y gestionar diferentes servicios ofrecidos por la barbería.

## Tecnologías y paquetes utilizados

- **Flutter**
- **Firebase** (Core, Auth, Firestore, Storage, Messaging)
- **Google Sign-In**
- **Table Calendar**
- **Notificaciones locales**
- **Gestión de permisos**
- **Supabase**
- **Manejo de imágenes y archivos**
- **Preferencias compartidas**
- **Conectividad y manejo de red**
- **Mapas y localización**
- **JWT y utilidades criptográficas**

## Estructura del proyecto

- `lib/screens/admin/`: Pantallas y funcionalidades para el administrador (panel, citas, clientes, calendario, historial, configuración).
- `lib/models/`: Modelos de datos.
- `lib/services/`: Servicios para notificaciones, autenticación, etc.
- `lib/theme/`: Temas de la aplicación, tanto claro como oscuro.
- `lib/widgets/`: Componentes reutilizables.
- `assets/`: Recursos gráficos y multimedia.

