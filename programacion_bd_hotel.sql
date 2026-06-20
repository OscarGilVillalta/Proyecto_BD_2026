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

-- 3. Proceso almacenado para realizar el check-in de una estadia
create or replace procedure sp_realizar_checkin(
    p_id_reservacion INT
)
language plpgsql
as
$$
declare
    v_estado VARCHAR;
    v_id_estadia INT;
    v_precio NUMERIC(10,2);
    v_id_factura INT;
    v_id_registro INT;
    v_numero INT;
begin

    select Estado
    into v_estado
    from Reservacion
    where ID_Reservacion = p_id_reservacion;

    if exists (
        select 1 from Factura where ID_Estadia = v_id_estadia
    ) then
        raise notice 'La estadía % ya tiene una factura registrada', v_id_estadia;
        return;
    end if;

    if not found then
        raise exception 'La reservación no existe';
    end if;

    if v_estado <> 'PENDIENTE' then
        raise exception 'La reservación debe estar en estado PENDIENTE para realizar check-in';
    end if;

    select ID_Estadia into v_id_estadia
    from Estadia
    where ID_Reservacion = p_id_reservacion;

    if not found then
        raise exception 'No existe una estadía asociada a la reservación';
    end if;

    update Estadia
    set Fecha_Entrada = current_date,
        Hora_Entrada = make_time(
            extract(hour from current_time)::int,
            extract(minute from current_time)::int,
            0
        )
    where ID_Estadia = v_id_estadia;

    insert into Factura (Fecha_Factura, Precio_Total, ID_Estadia)
    values (current_date, fn_total_habitaciones(v_id_estadia), v_id_estadia)
    returning ID_Factura into v_id_factura;

    for v_id_registro, v_precio, v_numero in
        select rh.ID_Registro, h.Precio, rh.Numero
        from RegistroHabitaciones rh
        inner join Habitacion h on h.Numero = rh.Numero and h.ID_Hotel = rh.ID_Hotel
        where rh.ID_Estadia = v_id_estadia
    loop
        insert into Detalle (Precio_Subtotal, Cantidad, Descripcion, Precio_Unitario, ID_Factura, ID_Registro)
        values (v_precio, 1, 'Habitacion #' || v_numero, v_precio, v_id_factura, v_id_registro);
    end loop;

    raise notice 'Check-in realizado. Estadia %', v_id_estadia;

end;
$$;

-- 4. Proceso almacenado para realizar el check-out de una estadia
create or replace procedure sp_realizar_checkout(
    p_id_estadia INT
)
language plpgsql
as
$$
declare
    v_total NUMERIC(10,2);
    v_fecha_fin DATE;
    v_id_factura INT;
    v_id_historial INT;
    v_nombre_servicio VARCHAR(250);
    v_precio_servicio NUMERIC(10,2);
begin

    if not exists (
        select 1 from Estadia where ID_Estadia = p_id_estadia
    ) then
        raise exception 'La estadía no existe';
    end if;

    select ID_Factura into v_id_factura
    from Factura
    where ID_Estadia = p_id_estadia;

    if not found then
        raise exception 'La estadía no tiene una factura asociada';
    end if;

    for v_id_historial, v_precio_servicio, v_nombre_servicio in
        select hs.ID_HistorialServicios, s.Precio_Unitario, s.Nombre
        from HistorialServicios hs
        inner join Servicio s on s.ID_Servicio = hs.ID_Servicio
        where hs.ID_Estadia = p_id_estadia
          and not exists (
              select 1 from Detalle d
              where d.ID_HistorialServicios = hs.ID_HistorialServicios
                and d.ID_Factura = v_id_factura
          )
    loop
        insert into Detalle (Precio_Subtotal, Cantidad, Descripcion, Precio_Unitario, ID_Factura, ID_HistorialServicios)
        values (v_precio_servicio, 1, 'Servicio: ' || v_nombre_servicio, v_precio_servicio, v_id_factura, v_id_historial);
    end loop;

    v_total := fn_total_factura(p_id_estadia);

    update Factura
    set Precio_Total = v_total,
        Fecha_Factura = current_date
    where ID_Estadia = p_id_estadia;

    update Estadia
    set
        Fecha_Salida = current_date,
        Hora_Salida = make_time(
            extract(hour from current_time)::int,
            extract(minute from current_time)::int,
            0
        )
    where ID_Estadia = p_id_estadia;

    update Reservacion
    set Estado = 'COMPLETADA'
    where ID_Reservacion = (
        select ID_Reservacion from Estadia where ID_Estadia = p_id_estadia
    );

    raise notice 'Check-out realizado. Total a pagar: $%', v_total;

end;
$$;

-- 5. Proceso almacenado que permite realizar un pago de nomina
-- 5. Proceso almacenado para registrar un pago de nómina
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

    if not found then
        raise exception 'La estadía con ID % no existe', NEW.ID_Estadia;
    end if;

    if v_inicio is null or v_fin is null then
        return NEW;
    end if;     

    if exists (
        select 1
        from RegistroHabitaciones rh
        inner join Estadia e on e.ID_Estadia = rh.ID_Estadia
        where rh.Numero = NEW.Numero
          and rh.ID_Hotel = NEW.ID_Hotel
          and rh.ID_Registro is distinct from NEW.ID_Registro
          and v_inicio <= e.Fecha_Salida
          and v_fin >= e.Fecha_Entrada
    ) then
        raise exception 'La habitación % del hotel % ya está ocupada del % al %',
            NEW.Numero, NEW.ID_Hotel, v_inicio, v_fin;
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

/*
-- ================================================================================================
-- EJEMPLOS DE USO (ejecutar en orden, después de haber insertado los datos de hotel_dml.sql)
-- ================================================================================================

-- =============================================
-- EJEMPLOS DE FUNCIONES Y PROCEDIMIENTOS
-- =============================================

-- 1. Realizar check-in (crea factura con el total de habitaciones)
select * from reservacion where estado = 'PENDIENTE' limit 1;
select * from Estadia where ID_Reservacion = 1;
select * from Factura where ID_Estadia = 741;
call sp_realizar_checkin(1);

-- 2. Verificar la factura generada
select * from Estadia where ID_Reservacion = 1;
select * from Factura where ID_Estadia = 741;

-- 3. Verificar las habitaciones asignadas a la estadia
select * from RegistroHabitaciones where ID_Estadia = 741;

-- 4. Registrar un servicio a la estadia (estadia, servicio, empleado)
select * from historialservicios where id_estadia = 741;
call sp_registrar_servicio(741, 2, 101);

-- 5. Verificar el servicio registrado
select * from HistorialServicios where ID_Estadia = 741;

-- 6. Calcular total gastado en servicios de la estadia
select fn_total_servicios(741) as total_servicios;

-- 7. Calcular total gastado en habitaciones de la estadia
select fn_total_habitaciones(741) as total_habitaciones;

-- 8. Calcular total general de la factura (habitaciones + servicios)
select fn_total_factura(741) as total_factura;

-- 9. Resumen completo de la estadia
select * from fn_resumen_estadia(741);

-- 10. Realizar check-out (calcula total final y actualiza factura)
select * from factura where id_estadia = 741;
select * from detalle where id_factura = 573;
call sp_realizar_checkout(741);

select * from detalle where id_factura = 573;

-- 11. Verificar factura con el total final
select * from Factura where ID_Estadia = 741;

-- 12. Verificar la estadaa con fecha y hora de salida
select * from Estadia where ID_Estadia = 741;

-- 13. Resumen del huesped (reservaciones, estadías, total gastado)
select * from huesped where nombre = 'Madelin Windas';
select * from fn_resumen_huesped(10);
select * from reservacion where id_huesped = 10;

-- 14. Resumen del hotel (id_hotel)
select * from fn_resumen_hotel(1);

-- 15. Registrar un pago de nomina para el empleado 1
call sp_registrar_pago_nomina(850.00, 'TRANSFERENCIA', 13.00, 1);

-- 16. Verificar el pago registrado
select * from PagoNomina where ID_Empleado = 1;

-- =============================================
-- EJEMPLOS DE TRIGGERS (casos de error)
-- =============================================

-- 17. Intentar registrar una habitación ya ocupada (debe lanzar error)
-- insert into RegistroHabitaciones (Precio_Subtotal, ID_Estadia, Numero, ID_Hotel)
-- values (30.00, 2, 11, 1);

-- 18. Intentar registrar servicio con empleado de otro hotel (debe lanzar error)
-- call sp_registrar_servicio(1, 1, 3);

-- 19. Intentar crear una segunda factura para la misma estadía (debe lanzar error)
-- call sp_realizar_checkin(1);
*/