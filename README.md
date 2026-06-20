# 🏨 Sistema de Gestión Hotelera

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-336791?style=for-the-badge&logo=postgresql&logoColor=white)

Proyecto de **Base de Datos para la Gestión Hotelera**, desarrollado en **PostgreSQL**, que permite administrar reservas, estadías, habitaciones, facturación, servicios y nómina de empleados mediante procedimientos almacenados, funciones y triggers.

---

## ✨ Características principales

- 📅 Gestión de reservaciones y estadías
- 🛏️ Control de habitaciones y disponibilidad
- 🧾 Facturación automática
- 🍽️ Registro de servicios consumidos
- 👥 Administración de huéspedes
- 💼 Gestión de empleados y nómina
- ⚡ Implementación de funciones, procedimientos almacenados y triggers
- 📊 Modelo relacional normalizado y documentación técnica

---

## 📂 Estructura del proyecto

### 📄 `hotel.sql`
Contiene el esquema completo de la base de datos:

#### Tablas principales
- **Hotel**
- **Huesped**
- **Servicio**

#### Gestión de reservas y facturación
- **Reservacion**
- **Estadia**
- **Factura**

#### Habitaciones
- **Habitacion**

| Tipo | Precio por noche |
|--------|--------|
| INDIVIDUAL | $15 |
| DOBLE | $30 |
| FAMILIAR | $20 |
| SUITE | $50 |

#### Gestión de empleados
- **Empleado**
- **PagoNomina**

#### Registros operativos
- **RegistroHabitaciones**
- **HistorialServicios**
- **Detalle**

Incluye:
- Llaves primarias
- Llaves foráneas
- Restricciones (`CHECK`)
- Restricciones de integridad referencial

---

### 📄 `hotel_dml.sql`

Archivo con datos de prueba para simulación y validación del sistema.

**Contenido generado:**
- 🏨 100 hoteles
- 👤 Más de 200 huéspedes
- 🛎️ 100 servicios
- 🛏️ 400 habitaciones
- 📅 300 reservaciones
- 🏷️ 785 estadías
- 🧾 Facturas y detalles asociados

Más de **8,000 registros** en total.

---

### 📄 `programacion_bd_hotel.sql`

Implementación de la lógica de negocio.

#### 🔹 Funciones
- `fn_total_habitaciones`
- `fn_total_servicios`
- `fn_total_factura`
- `fn_resumen_estadia`
- `fn_resumen_huesped`
- `fn_resumen_hotel`

#### 🔹 Procedimientos almacenados
- `sp_realizar_checkin`
- `sp_realizar_checkout`
- `sp_registrar_servicio`
- `sp_registrar_pago_nomina`

#### 🔹 Triggers
- Validación de disponibilidad de habitaciones
- Validación de empleado por hotel
- Restricción de factura única por estadía

Incluye ejemplos de uso y pruebas.

---

### 📄 `FUNCIONES.sql`

Versión alternativa de funciones y procedimientos con:

- Validaciones adicionales
- Manejo de errores mejorado
- Casos de prueba organizados
- Ejemplos de ejecución

---

## 📊 Diagramas

### Modelo Entidad-Relación
- `DIAGRAMAS/Diagrama_Entidad_Relacion.png`

### Modelo Relacional Normalizado
- `DIAGRAMAS/Diagrama_Relacional_Normalizado.png`

---

## 📘 Documentación

- `Documento Tecnico.pdf`

Contiene:
- Descripción del sistema
- Diseño de la base de datos
- Reglas de negocio
- Explicación de funciones y procedimientos
- Evidencias de pruebas

---

## 🛠️ Tecnologías utilizadas

- PostgreSQL
- PL/pgSQL
- SQL DDL
- SQL DML
- Triggers
- Procedimientos almacenados
- Funciones

---

## 🚀 Objetivo del proyecto

Desarrollar una solución integral para la administración de hoteles, aplicando conceptos de:

- Diseño de bases de datos relacionales
- Normalización
- Programación en bases de datos
- Automatización mediante triggers
- Gestión transaccional y reglas de negocio

---

### 👨‍💻 Autor

Proyecto académico desarrollado como práctica avanzada de **Bases de Datos en PostgreSQL** hecho por el equipo E.