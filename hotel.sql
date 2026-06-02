CREATE TABLE
  Huesped (
    --! PK
    ID_Huesped INT GENERATED ALWAYS AS IDENTITY,
    Nombre VARCHAR(250) NOT NULL,
    DUI CHAR(9) NOT NULL,
    Correo VARCHAR(250) NOT NULL,
    Telefono CHAR(8) NOT NULL,
    --* Llave primaria de Huesped
    CONSTRAINT pk_Huesped_IDHuesped PRIMARY KEY (ID_Huesped),
    --* Campos UNICOS para huesped
    CONSTRAINT uq_Huesped_DUI UNIQUE (DUI),
    CONSTRAINT pk_Huesped_Correo UNIQUE (Correo),
    CONSTRAINT pk_Huesped_Telefono UNIQUE (Telefono),
    --* Verificar campos
    CONSTRAINT ck_Huesped_Correo CHECK (Correo LIKE '%gmail.com')
  );

CREATE TABLE
  Hotel (
    --! PK
    ID_Hotel INT GENERATED ALWAYS AS IDENTITY,
    Nombre VARCHAR(250) NOT NULL,
    Direccion VARCHAR(250) NOT NULL,
    Area NUMERIC(10, 2) NOT NULL,
    Estrellas INT DEFAULT 1,
    Hora_Apertura TIME NOT NULL,
    Hora_Cierre TIME NOT NULL,
    --* Llave primaria del Hotel
    CONSTRAINT pk_Hotel_IDHotel PRIMARY KEY (ID_Hotel),
    --* Verificar campos
    CONSTRAINT ck_Hotel_Estrellas CHECK (Estrellas BETWEEN 1 AND 5)
  );

--? Servicios (Tipo) : BIENESTAR (SPA, Masajes), DEPORTIVOS (Psicina, Gimnasio), 
--? HABITACION (Limpieza de Habitacion, Lavanderia), ALIMENTACION (Bar, Restaurante),
--? ENTRETENIMIENTO (Cine, Karaoke)
CREATE TABLE
  Servicio (
    --! PK
    ID_Servicio INT GENERATED ALWAYS AS IDENTITY,
    Zona VARCHAR(100) NOT NULL,
    Nombre VARCHAR(250) NOT NULL,
    Tipo VARCHAR(50) NOT NULL,
    Precio_Unitario NUMERIC(10, 2) NOT NULL,
    Descripcion VARCHAR(250) NOT NULL,
    --* Llave primaria del Servicio
    CONSTRAINT pk_Servicio_IDServicio PRIMARY KEY (ID_Servicio),
    --* Campos UNICOS para huesped
    CONSTRAINT uq_Servicio_Nombre UNIQUE (Nombre),
    --* Verificar campos
    CONSTRAINT uq_Servicio_PrecioUnitario BETWEEN 1 AND 1000,
    CONSTRAINT ck_Servicio_Tipo CHECK Servicio IN ('BIENESTAR', 'DEPORTIVOS', 'HABITACION', 'ALIMENTACION', 'ENTRETENIMIENTO')
  );

CREATE TABLE
  Reservacion (
    --! PK
    ID_Reservacion INT GENERATED ALWAYS AS IDENTITY,
    Estado VARCHAR(100) NOT NULL,
    Cantidad_personas INT NOT NULL,
    Fecha_inicio DATE NOT NULL,
    Fecha_fin DATE NOT NULL,
    Fecha_retiro DATE NOT NULL,
    ID_Huesped INT NOT NULL,
    PRIMARY KEY (ID_Reservacion),
    FOREIGN KEY (ID_Huesped) REFERENCES Huesped (ID_Huesped)
  );

CREATE TABLE
  Estadia (
    --! PK
    ID_Estadia INT GENERATED ALWAYS AS IDENTITY,
    Fecha_Entrada DATE NOT NULL,
    Fecha_Salida DATE NOT NULL,
    Hora_Entrada TIME NOT NULL,
    Hora_Salida TIME NOT NULL,
    ID_Reservacion INT NOT NULL,
    PRIMARY KEY (ID_Estadia),
    FOREIGN KEY (ID_Reservacion) REFERENCES Reservacion (ID_Reservacion)
  );

CREATE TABLE
  Factura (
    --! PK
    ID_Factura INT GENERATED ALWAYS AS IDENTITY,
    Fecha_factura DATE NOT NULL,
    Precio_total NUMERIC(10, 2) NOT NULL,
    ID_Estadia INT NOT NULL,
    PRIMARY KEY (ID_Factura),
    FOREIGN KEY (ID_Estadia) REFERENCES Estadia (ID_Estadia)
  );

--? Habitacion (Tipo) : INDIVIDUAL (15$ la noche), DOBLE (30$ la noche), 
--? FAMILIAR (20$ la noche), SUITE(50$ la noche)
CREATE TABLE
  Habitacion (
    --! PK
    Numero INT NOT NULL,
    Tamaño NUMERIC(10, 2) NOT NULL,
    Camas INT NOT NULL,
    Baños INT NOT NULL,
    Tipo VARCHAR(250) NOT NULL,
    Precio NUMERIC(10, 2) NOT NULL,
    ID_Hotel INT NOT NULL,
    --* Llave primaria del Servicio
    PRIMARY KEY (Numero, ID_Hotel),
    --* Llave foranea Habitacion -> Hotel (ID)
    FOREIGN KEY (ID_Hotel) REFERENCES Hotel (ID_Hotel)
      ON DELETE RESTRICT ON CASCADE UPDATE,
    --* Verificar campos
    CONSTRAINT ck_Habitacion_Tipo CHECK Habitacion IN ('INDIVIDUAL', 'DOBLE', 'FAMILIAR', 'SUITE')
  );

CREATE TABLE
  Empleado (
    --! PK
    ID_Empleado INT GENERATED ALWAYS AS IDENTITY,
    Nombre VARCHAR(250) NOT NULL,
    Correo VARCHAR(250) NOT NULL,
    Hora_Entrada TIME NOT NULL,
    Hora_Salida TIME NOT NULL,
    ID_Hotel INT NOT NULL,
    ID_Supervisor INT NOT NULL,
    PRIMARY KEY (ID_Empleado),
    FOREIGN KEY (ID_Hotel) REFERENCES Hotel (ID_Hotel),
    FOREIGN KEY (ID_Supervisor) REFERENCES Empleado (ID_Empleado) UNIQUE (Correo)
  );

CREATE TABLE
  PagoNomina (
    --! PK
    ID_Salario INT GENERATED ALWAYS AS IDENTITY,
    Monto NUMERIC(10, 2) NOT NULL,
    Fecha_Pago DATE NOT NULL,
    Metodo_Pago VARCHAR(50) NOT NULL,
    IVA NUMERIC(2) NOT NULL,
    Lugar VARCHAR(100) NOT NULL,
    ID_Empleado INT NOT NULL,
    PRIMARY KEY (ID_Salario, ID_Empleado),
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado (ID_Empleado)
  );

CREATE TABLE
  HistorialServicios (
    --! PK
    ID_HistorialServicios INT GENERATED ALWAYS AS IDENTITY,
    Fecha_servicio DATE NOT NULL,
    ID_Estadia INT NOT NULL,
    ID_Servicio INT NOT NULL,
    ID_Empleado INT NOT NULL,
    PRIMARY KEY (ID_HistorialServicios),
    FOREIGN KEY (ID_Estadia) REFERENCES Estadia (ID_Estadia),
    FOREIGN KEY (ID_Servicio) REFERENCES Servicio (ID_Servicio),
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado (ID_Empleado)
  );

CREATE TABLE
  Detalle (
    --! PK
    ID_Detalle INT GENERATED ALWAYS AS IDENTITY,
    Precio_Subtotal NUMERIC(10, 2) NOT NULL,
    Cantidad INT NOT NULL,
    Descripcion VARCHAR(250) NOT NULL,
    Precio_Unitario NUMERIC(10, 2) NOT NULL,
    ID_Factura INT NOT NULL,
    ID_HistorialServicios INT NOT NULL,
    PRIMARY KEY (ID_Detalle, ID_Factura),
    FOREIGN KEY (ID_Factura) REFERENCES Factura (ID_Factura),
    FOREIGN KEY (ID_HistorialServicios) REFERENCES HistorialServicios (ID_HistorialServicios)
  );

CREATE TABLE
  RegistroHabitaciones (
    Precio_Subtotal NUMERIC(10, 2) NOT NULL,
    ID_Estadia INT NOT NULL,
    Numero INT NOT NULL,
    ID_Hotel INT NOT NULL,
    PRIMARY KEY (ID_Estadia, Numero, ID_Hotel),
    FOREIGN KEY (ID_Estadia) REFERENCES Estadia (ID_Estadia),
    FOREIGN KEY (Numero, ID_Hotel) REFERENCES Habitacion (Numero,)
  );