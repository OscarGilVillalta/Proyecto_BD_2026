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
begin

    v_total :=
        fn_total_factura(p_id_estadia);

    insert into Factura(
        Fecha_Factura,
        Precio_Total,
        ID_Estadia
    )
    values(
        current_date,
        v_total,
        p_id_estadia
    );

    update Estadia
    set
        Fecha_Salida = current_date,
        Hora_Salida = make_time(
            extract(hour from current_time)::int,
            extract(minute from current_time)::int,
            0
        )
    where ID_Estadia = p_id_estadia;

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

-- Trigger que valida que un empleado registre servivicios solamente en su hotel

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

create trigger trg_validar_empleado_hotel
before insert
on HistorialServicios
for each row
execute function fn_validar_empleado_hotel();

-- ================================================================================================
-- USOS

-- Funciones
-- Total gastado en servicios durante una estadia
select * from fn_total_servicios(1);

-- Total gastado en habitaciones durante una estadia
select * from fn_total_habitaciones(1);

-- Total general de la factura (habitaciones + servicios)
select * from fn_total_factura(1);

-- Reporte completo de una estadia
select * from fn_resumen_estadia(1);

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
call sp_realizar_checkout(1);

-- Verificacion de la factura que se genero
select * from Factura where ID_Estadia = 1;

-- Verificar la actualizacion de la estadia
select
    ID_Estadia,
    Fecha_Salida,
    Hora_Salida
from Estadia
where ID_Estadia = 1;

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
