
--? Un correo siempre acaba con '@gmail.com'
--? El nombre como minimo tiene 3 caracteres y maximo 250
CREATE TABLE
  Huesped (
    --! ID_Huesped lo generea el Sistema 
    ID_Huesped ALWAYS GENERATED AS IDENTITY,
    Nombre VARCHAR(250) NOT NULL,
    DUI CHAR(9) NOT NULL,
    Correo VARCHAR(250) NOT NULL,
    Telefono CHAR(8) NOT NULL,
    --* Llave primaria de Huesped
    CONSTRAINT pk_Huespued_idHuesped PRIMARY KEY (ID_Huesped),
    --* Campos unicos de la tabla
    CONSTRAINT uq_Huesped_DUI UNIQUE (DUI),
    CONSTRAINT uq_Huesped_Correo UNIQUE (Correo),
    CONSTRAINT uq_Huesped_Telefono UNIQUE (Telefono),
    --* Verificar la integridad de los campos
    CONSTRAINT ck_Huesped_Nombre CHECK LENGTH (Nombre) BETWEEN 3 AND 250,
    CONSTRAINT ck_Huesped_Correo CHECK Correo LIKE '%@gmail.com'
  );

--? El campo Estado puede estar 'SIN RESERVAR' o 'RESERVADO'
--? El campo Cantidad_personas no puede ser negativo
--? El campo Fecha_inicio debe ser SIEMPRE mayor a Fecha_fin
CREATE TABLE
  Reservacion (
    --! ID_Reservacion lo generea el Sistema
    ID_Reservacion ALWAYS GENERATED AS IDENTITY,
    Estado VARCHAR(100) DEFAULT 'SIN RESERVAR',
    Cantidad_personas INT NOT NULL,
    Fecha_inicio DATE NOT NULL,
    Fecha_fin DATE NOT NULL,
    Fecha_reservacion DATE NOT NULL,
    ID_Huesped INT NOT NULL,
    --* Llave primaria
    CONSTRAINT pk_Reservacion_IDReservacion PRIMARY KEY (ID_Reservacion),
    --* Llave foranea relacionada con -> Huesped (ID)
    CONSTRAINT fk_Reservacion_IDHuespued FOREIGN KEY (ID_Huesped) REFERENCES Huesped (ID_Huesped)
      ON DELETE RESTRICT ON CASCADE UPDATE,
    --* Verificar la integridad de los campos
    CONSTRAINT ck_Reservacion_Estado CHECK (Estado IN ('RESERVADO')),
    CONSTRAINT ck_Reservacion_CantidadPersona CHECK Cantidad_personas > 0,
    CONSTRAINT ck_Reservacion_Fechas CHECK Fecha_fin > Fecha_inicio
  );

--? El campo Fecha_inicio debe ser MAYOR a Fecha_retiro
CREATE TABLE
  Estadia (
    --! ID_Estadia lo generea el Sistema
    ID_Estadia ALWAYS GENERATED AS IDENTITY,
    Fecha_inicio DATE NOT NULL,
    Fecha_retiro DATE NOT NULL,
    Hora_llegada DATE NOT NULL,
    Hora_retiro DATE NOT NULL,
    ID_Reservacion INT NOT NULL,
    --* Llave primaria
    PRIMARY KEY (ID_Estadia),
    --* Llave foranea relacionada con -> Reservacion (ID)
    FOREIGN KEY (ID_Reservacion) REFERENCES Reservacion (ID_Reservacion)
      ON DELETE RESTRICT ON CASCADE UPDATE,
    --* Verificar la integridad de los campos
    CONSTRAINT ck_Estadia_Fechas CHECK Fecha_retiro > Fecha_inicio
  );

CREATE TABLE
  Hotel (
    ID_Hotel INT NOT NULL,
    Nombre VARCHAR(250) NOT NULL,
    Direccion INT NOT NULL,
    Area NUMERIC(2) NOT NULL,
    Horario VARCHAR(250) NOT NULL,
    Estrellas INT NOT NULL,
    PRIMARY KEY (ID_Hotel),
    UNIQUE (Direccion)
  );

CREATE TABLE
  Habitacion (
    Numero INT NOT NULL,
    Tipo VARCHAR(250) NOT NULL,
    Tamaño VARCHAR(250) NOT NULL,
    Camas INT NOT NULL,
    Baños INT NOT NULL,
    ID_Hotel INT NOT NULL,
    PRIMARY KEY (Numero),
    FOREIGN KEY (ID_Hotel) REFERENCES Hotel (ID_Hotel)
  );

CREATE TABLE
  Estadia_Habitacion (
    ID_Estadia INT NOT NULL,
    ID_Habitacion INT NOT NULL,
    PRIMARY KEY (ID_Estadia, ID_Habitacion),
    FOREIGN KEY (ID_Estadia) REFERENCES Estadia (ID_Estadia),
    FOREIGN KEY (ID_Habitacion) REFERENCES Habitacion (Numero)
  );

CREATE TABLE
  Servicio (
    ID_Servicio INT NOT NULL,
    Nombre VARCHAR(250) NOT NULL,
    Tipo VARCHAR(250) NOT NULL,
    Zona VARCHAR(250) NOT NULL,
    PRIMARY KEY (ID_Servicio)
  );

CREATE TABLE
  Estadia_Servicio (
    ID_Servicio INT NOT NULL,
    ID_Estadia INT NOT NULL,
    PRIMARY KEY (ID_Servicio, ID_Estadia),
    FOREIGN KEY (ID_Servicio) REFERENCES Servicio (ID_Servicio),
    FOREIGN KEY (ID_Estadia) REFERENCES Estadia (ID_Estadia)
  );

CREATE TABLE
  Factura (
    ID_Factura INT NOT NULL,
    Fecha_factura DATE NOT NULL,
    Precio_total NUMERIC NOT NULL,
    ID_Estadia INT NOT NULL,
    PRIMARY KEY (ID_Factura),
    FOREIGN KEY (ID_Estadia) REFERENCES Estadia (ID_Estadia)
  );

CREATE TABLE
  Detalle (
    ID_Detalle INT NOT NULL,
    Descripcion VARCHAR(250) NOT NULL,
    Cantidad INT NOT NULL,
    Precio NUMERIC NOT NULL,
    ID_Factura INT NOT NULL,
    ID_Habitacion INT NOT NULL,
    ID_Hotel INT NOT NULL,
    PRIMARY KEY (ID_Detalle),
    FOREIGN KEY (ID_Factura) REFERENCES Factura (ID_Factura),
    FOREIGN KEY (ID_Habitacion) REFERENCES Habitacion (Numero),
    FOREIGN KEY (ID_Hotel) REFERENCES Hotel (ID_Hotel)
  );

CREATE TABLE
  Empleado (
    ID_Empleado INT NOT NULL,
    Nombre VARCHAR(250) NOT NULL,
    Correo VARCHAR(250) NOT NULL,
    Horario VARCHAR(250) NOT NULL,
    ID_Hotel INT NOT NULL,
    PRIMARY KEY (ID_Empleado),
    FOREIGN KEY (ID_Hotel) REFERENCES Hotel (ID_Hotel)
  );

CREATE TABLE
  Supervisor (
    Departamento VARCHAR(250) NOT NULL,
    Presupuesto NUMERIC NOT NULL,
    ID_Empleado INT NOT NULL,
    PRIMARY KEY (ID_Empleado),
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado (ID_Empleado)
  );

CREATE TABLE
  Operativo (
    Cargo VARCHAR(250) NOT NULL,
    ID_Empleado INT NOT NULL,
    ID_Supervisor INT NOT NULL,
    ID_Servicio INT NOT NULL,
    PRIMARY KEY (ID_Empleado),
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado (ID_Empleado),
    FOREIGN KEY (ID_Supervisor) REFERENCES Supervisor (),
    FOREIGN KEY (ID_Servicio) REFERENCES Servicio (ID_Servicio)
  );

CREATE TABLE
  PagoNomina (
    ID_Salario INT NOT NULL,
    Monto NUMERIC NOT NULL,
    Fecha_pago DATE NOT NULL,
    Metodo_pago VARCHAR(250) NOT NULL,
    IVA NUMERIC NOT NULL,
    Lugar VARCHAR(250) NOT NULL,
    ID_Empleado INT NOT NULL,
    PRIMARY KEY (ID_Salario),
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado (ID_Empleado)
  );