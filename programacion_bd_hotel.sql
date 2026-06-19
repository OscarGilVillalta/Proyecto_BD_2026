-- PROGRAMACION EN LA BASE DE DATOS

-- ================================================================================================
-- FUNCIONES

-- 1. Funcion para calcular cuanto ha gastado una estadia en servicios
create or replace function fn_total_servicios(
    p_id_estadia INT
)
returns NUMERIC(10,2)
language plpgsql
as
$$
declare
    v_total NUMERIC(10,2);
begin

    select coalesce(
        sum(s.Precio_Unitario),
        0
    )
    into v_total
    from HistorialServicios hs
    inner join Servicio s
        on hs.ID_Servicio = s.ID_Servicio
    where hs.ID_Estadia = p_id_estadia;

    return v_total;

end;
$$;

-- 2. Funcion para calcular cuanto cuestan las habitaciones utilizadas
create or replace function fn_total_habitaciones(
    p_id_estadia INT
)
returns NUMERIC(10,2)
language plpgsql
as
$$
declare
    v_total NUMERIC(10,2);
begin

    select coalesce(
        sum(Precio_Subtotal),
        0
    )
    into v_total
    from RegistroHabitaciones
    where ID_Estadia = p_id_estadia;

    return v_total;

end;
$$;

-- 3. Funcion para realizar las facturacion (invoca las dos funciones previamente declaradas)
create or replace function fn_total_factura(
    p_id_estadia INT
)
returns NUMERIC(10,2)
language plpgsql
as
$$
begin

    return
        fn_total_habitaciones(p_id_estadia)
        +
        fn_total_servicios(p_id_estadia);

end;
$$;

-- 4. Funcion para mostrar un resumen de la estadia
create or replace function fn_resumen_estadia(
    p_id_estadia INT
)
returns table(
    id_estadia INT,
    huesped VARCHAR(250),
    habitacion_total NUMERIC(10,2),
    servicios TEXT,
    servicios_total NUMERIC(10,2),
    total_factura NUMERIC(10,2)
)
language plpgsql
as
$$
begin

    return query

    select
        e.ID_Estadia,
        h.Nombre,

        fn_total_habitaciones(e.ID_Estadia),

        coalesce(
            string_agg(
                s.Nombre,
                ', '
            ),
            'Sin servicios'
        ),

        fn_total_servicios(e.ID_Estadia),

        fn_total_factura(e.ID_Estadia)

    from Estadia e

    inner join Reservacion r
        on e.ID_Reservacion = r.ID_Reservacion

    inner join Huesped h
        on r.ID_Huesped = h.ID_Huesped

    left join HistorialServicios hs
        on e.ID_Estadia = hs.ID_Estadia

    left join Servicio s
        on hs.ID_Servicio = s.ID_Servicio

    where e.ID_Estadia = p_id_estadia

    group by
        e.ID_Estadia,
        h.Nombre;

end;
$$;

-- 5. Funcion para obtener un resumen del huesped
create or replace function fn_resumen_huesped(
    p_id_huesped INT
)
returns table(
    huesped VARCHAR(250),
    reservaciones BIGINT,
    estadias BIGINT,
    total_gastado NUMERIC(10,2)
)
language plpgsql
as
$$
begin

    return query

    select
        h.Nombre,

        count(distinct r.ID_Reservacion),

        count(distinct e.ID_Estadia),

        coalesce(
            sum(f.Precio_Total),
            0
        )

    from Huesped h

    left join Reservacion r
        on h.ID_Huesped = r.ID_Huesped

    left join Estadia e
        on r.ID_Reservacion = e.ID_Reservacion

    left join Factura f
        on e.ID_Estadia = f.ID_Estadia

    where h.ID_Huesped = p_id_huesped

    group by h.Nombre;

end;
$$;

-- 6. Funcion para obtener un resumen del hotel
create or replace function fn_resumen_hotel(
    p_id_hotel INT
)
returns table(
    hotel VARCHAR(250),
    habitaciones BIGINT,
    empleados BIGINT,
    servicios BIGINT
)
language plpgsql
as
$$
begin

    return query

    select
        h.Nombre,

        (
            select count(*)
            from Habitacion ha
            where ha.ID_Hotel = h.ID_Hotel
        ),

        (
            select count(*)
            from Empleado e
            where e.ID_Hotel = h.ID_Hotel
        ),

        (
            select count(*)
            from Servicio
        )

    from Hotel h

    where h.ID_Hotel = p_id_hotel;

end;
$$;

-- ================================================================================================
-- PROCESOS ALMACENADOS

-- 1. Proceso almacenado que le registra un servicio a una estadia, asociando esta con un empleado
create or replace procedure sp_registrar_servicio(
    p_id_estadia INT,
    p_id_servicio INT,
    p_id_empleado INT
)
language plpgsql
as
$$
begin

    if not exists(
        select 1
        from Estadia
        where ID_Estadia = p_id_estadia
    )
    then
        raise exception
        'La estadía no existe';
    end if;

    insert into HistorialServicios(
        Fecha_Servicio,
        ID_Estadia,
        ID_Servicio,
        ID_Empleado
    )
    values(
        current_date,
        p_id_estadia,
        p_id_servicio,
        p_id_empleado
    );

end;
$$;

-- 2. Proceso almacenado para realizar el check-out de una estadia
create or replace procedure sp_realizar_checkout(
    p_id_estadia INT
)
language plpgsql
as
$$
declare
    v_total NUMERIC(10,2);
    v_fecha_fin DATE;
begin

    v_total :=
        fn_total_factura(p_id_estadia);

    select Fecha_Entrada into v_fecha_fin
    from estadia;

    update factura 
    set precio_total = v_total, fecha_factura = v_fecha_fin
    where id_estadia = p_id_estadia;

    update Estadia
    set
        Fecha_Salida = v_fecha_fin,
        Hora_Salida = make_time(
            extract(hour from current_time)::int,
            extract(minute from current_time)::int,
            0
        )
    where ID_Estadia = p_id_estadia;

end;
$$;

-- 3 xddd
create or replace procedure sp_realizar_checkout(
    p_id_reservacion INT
)
language plpgsql
as
$$
declare
    v_estado VARCHAR;
    v_fecha_incio DATE;
    v_precio_inicial NUMERIC(10,2);
begin

    -- si el estado es igual 'PENDIENTE' puede seguir
    select fecha_inicio into v_fecha_incio from reservacion;
    -- Se creara una estadia donde su fecha de fin aun no esta decidida
    insert estadia into (fecha_entrada, hora_entrada, id_reservacion) 
        values 
    (v_fecha_incio, current_time, p_id_reservacion);
    -- Habitacion que va a ocupar
    -- Se creara una nueva factura relacionada con el id estadia
    insert into factura (fecha_factura, precio_total, id_estadia)
        values
    (v_fecha_inicio, , )
end;
$$;

-- 4 xdddd
-- Crear una factura al momento de hacer check-in (Genera una estadia y las habitaciones que a reservado)
create or replace procedure sp_realizar_checkout(
    p_id_estadia INT
)
language plpgsql
as
$$
declare
    v_total NUMERIC(10,2);
begin
    -- Al momento de reservar se crea una estadia por defecto pendiente
    -- Si la reservacion es pendiente generar una estadia con datos null
    -- Luego asocias las habitaciones a la estadia generada
    -- Por ultimo generar una factura con el id estadia
end;
$$;

-- 3. Proceso almacenado que permite realizar un pago de nomina
-- 3. Proceso almacenado para registrar un pago de nómina
create or replace procedure sp_registrar_pago_nomina(
    p_monto NUMERIC(10,2),
    p_metodo_pago VARCHAR(50),
    p_iva NUMERIC(5,2),
    p_id_empleado INT
)
language plpgsql
as
$$
begin

    insert into PagoNomina(
        Monto,
        Fecha_Pago,
        Metodo_Pago,
        IVA,
        ID_Empleado
    )
    values(
        p_monto,
        current_date,
        p_metodo_pago,
        p_iva,
        p_id_empleado
    );

end;
$$;

-- ================================================================================================
-- TRIGGERS

-- 1. Trigger que evita habitaciones ocupadas

-- Funcion
create or replace function fn_validar_disponibilidad_habitacion()
returns trigger
language plpgsql
as
$$
declare
    v_inicio DATE;
    v_fin DATE;
begin

    select
        Fecha_Entrada,
        Fecha_Salida
    into
        v_inicio,
        v_fin
    from Estadia
    where ID_Estadia = NEW.ID_Estadia;

    if exists (
        select 1
        from RegistroHabitaciones rh
        inner join Estadia e
            on e.ID_Estadia = rh.ID_Estadia
        where rh.Numero = NEW.Numero
          and rh.ID_Hotel = NEW.ID_Hotel
          and v_inicio <= e.Fecha_Salida
          and v_fin >= e.Fecha_Entrada
    )
    then
        raise exception
        'La habitación ya está ocupada';
    end if;

    return NEW;

end;
$$;

-- Trigger
create trigger trg_validar_disponibilidad_habitacion
before insert
on RegistroHabitaciones
for each row
execute function fn_validar_disponibilidad_habitacion();

-- 2. Trigger que valida que un empleado registre servivicios solamente en su hotel

-- Funcion
create or replace function fn_validar_empleado_hotel()
returns trigger
language plpgsql
as
$$
declare
    v_hotel_empleado INT;
    v_hotel_estadia INT;
begin

    select ID_Hotel
    into v_hotel_empleado
    from Empleado
    where ID_Empleado = NEW.ID_Empleado;

    select rh.ID_Hotel
    into v_hotel_estadia
    from RegistroHabitaciones rh
    where rh.ID_Estadia = NEW.ID_Estadia
    limit 1;

    if v_hotel_empleado <> v_hotel_estadia then
        raise exception
        'El empleado pertenece a otro hotel';
    end if;

    return NEW;

end;
$$;

-- Trigger
create trigger trg_validar_empleado_hotel
before insert
on HistorialServicios
for each row
execute function fn_validar_empleado_hotel();

-- 3. Trigger que se asegura que haya una factura unica
-- Funcion
create or replace function fn_validar_factura_unica()
returns trigger
language plpgsql
as
$$
begin

    if exists(
        select 1
        from Factura
        where ID_Estadia = NEW.ID_Estadia
    )
    then
        raise exception
        'La estadía ya posee una factura';
    end if;

    return NEW;

end;
$$;

-- Trigger
create trigger trg_validar_factura_unica
before insert
on Factura
for each row
execute function fn_validar_factura_unica();

-- ================================================================================================
-- USOS

-- Funciones
-- Total gastado en servicios durante una estadia
select * from fn_total_servicios(1);

-- Total gastado en habitaciones durante una estadia
select * from fn_total_habitaciones(1);

-- Total general de la factura (habitaciones + servicios)
select * from fn_total_factura(5);

-- Reporte completo de una estadia
select * from fn_resumen_estadia(1);

-- Resumen del huesped
select * from fn_resumen_huesped(2);

-- Resumen del hotel
select * from fn_resumen_hotel(1);

-- Procesos almacenados
-- Registrar un servicio consumido
call sp_registrar_servicio(
    1,  -- ID_Estadia
    2,  -- ID_Servicio
    1   -- ID_Empleado
);

-- Verificacion
select * from HistorialServicios where ID_Estadia = 1;

-- Realizar un check-out de una estadia
call sp_realizar_checkout(5);

update factura set precio_total = 0.1 where id_estadia = 5;

-- Verificacion de la factura que se genero
select * from Factura where ID_Estadia = 5;
-- Verificar la actualizacion de la estadia
select
    ID_Estadia,
    Fecha_Salida,
    Hora_Salida
from Estadia
where ID_Estadia = 1;

-- Registrar un pago de nomina
call sp_registrar_pago_nomina(
    850.00,
    'TRANSFERENCIA',
    13.00,
    1
);

-- Verificacion
select * from PagoNomina where ID_Empleado = 1;

-- Triggers

-- Intentar registrar una habitacion ocupada
insert into RegistroHabitaciones(
    Precio_Subtotal,
    ID_Estadia,
    Numero,
    ID_Hotel
)
values (
    30.00,
    2,
    11,
    1
);

-- Intentar registrar un servicio con un empleado de otro hotel
call sp_registrar_servicio(
    1,  -- Estadiaa del Hotel A
    2,  -- Servicio
    5   -- Empleado del Hotel B
);

-- Verificacion del Trigger que se asegura que hayan facturas unicas
call sp_realizar_checkout(13);
