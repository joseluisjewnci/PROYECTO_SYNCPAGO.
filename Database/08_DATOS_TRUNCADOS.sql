-- 1. Limpiar las tablas dependientes y reiniciar las secuencias en PostgreSQL
TRUNCATE TABLE usuarios RESTART IDENTITY CASCADE;

-- 2. Bloque anónimo para insertar usuarios con IDs que inician desde 1
DO $$
DECLARE
    u_record RECORD;
    
    t_arriendo tipo_gasto.id_tipo%TYPE;
    t_servicios tipo_gasto.id_tipo%TYPE;
    t_mercado tipo_gasto.id_tipo%TYPE;
    t_transporte tipo_gasto.id_tipo%TYPE;
    t_entretenimiento tipo_gasto.id_tipo%TYPE;
    
    t_cat_id tipo_gasto.id_tipo%TYPE;
    i INT;
    j INT;
    v_fecha TIMESTAMP;
    v_precio NUMERIC(12,2);
    v_estado VARCHAR(20);

    -- Nombres reales para la semilla de SyncPago
    nombres TEXT[] := ARRAY[
        'Carlos Alberto', 'María Fernanda', 'Juan David', 'Ana Sofía', 'Alejandro',
        'Valentina', 'Andrés Felipe', 'Camila', 'Santiago', 'Daniela',
        'Mateo', 'Laura Victoria', 'Sebastian', 'Mariana', 'Diego Armando',
        'Gabriela', 'Nicolas', 'Natalia', 'Julian Esteban', 'Paula Andrea',
        'Samuel', 'Isabella', 'Cristian Camilo', 'Vanessa', 'Javier Eduardo'
    ];
    
    apellidos TEXT[] := ARRAY[
        'Gómez Rodríguez', 'Martínez López', 'Rodríguez Silva', 'Hernández Pérez', 'García Morales',
        'López Ramírez', 'González Castro', 'Pérez Torres', 'Sánchez Vargas', 'Ramírez Mendoza',
        'Torres Rojas', 'Díaz Guerrero', 'Vargas Ortiz', 'Castro Jiménez', 'Morales Moreno',
        'Herrera Medina', 'Jiménez Castillo', 'Rojas Romero', 'Medina Álvarez', 'Silva Salazar',
        'Vásquez Guzmán', 'Vargas Suárez', 'Ríos Franco', 'Mendoza Cardona', 'Espinosa Mejía'
    ];

    v_nombre_completo TEXT;
    v_correo TEXT;
BEGIN
    -- Insertar 25 Usuarios comenzando automáticamente con id_usuario = 1
    FOR i IN 1..25 LOOP
        v_nombre_completo := nombres[i] || ' ' || apellidos[i];
        
        v_correo := LOWER(
            REPLACE(SPLIT_PART(nombres[i], ' ', 1), 'á', 'a') || '.' || 
            REPLACE(SPLIT_PART(apellidos[i], ' ', 1), 'á', 'a') || i || '@email.com'
        );
        v_correo := TRANSLATE(v_correo, 'éíóúñ', 'eioun');

        INSERT INTO usuarios (nombre, correo, contrasena, telefono) 
        VALUES (
            v_nombre_completo, 
            v_correo,
            '123456',
            '300' || LPAD((1000000 + i * 12345)::text, 7, '0')
        );
    END LOOP;

    -- Recorrer usuarios ordenados por id_usuario ascendente
    FOR u_record IN SELECT id_usuario FROM usuarios ORDER BY id_usuario ASC LOOP
        
        -- Categorías para cada usuario usando las clases permitidas ('vital', 'varios', 'entretenimiento')
        INSERT INTO tipo_gasto (id_usuario, clase, detalle) VALUES (u_record.id_usuario, 'vital', 'Arriendo/Hipoteca') RETURNING id_tipo INTO t_arriendo;
        INSERT INTO tipo_gasto (id_usuario, clase, detalle) VALUES (u_record.id_usuario, 'vital', 'Servicios Públicos') RETURNING id_tipo INTO t_servicios;
        INSERT INTO tipo_gasto (id_usuario, clase, detalle) VALUES (u_record.id_usuario, 'vital', 'Mercado y Víveres') RETURNING id_tipo INTO t_mercado;
        INSERT INTO tipo_gasto (id_usuario, clase, detalle) VALUES (u_record.id_usuario, 'varios', 'Transporte / Gasolina') RETURNING id_tipo INTO t_transporte;
        INSERT INTO tipo_gasto (id_usuario, clase, detalle) VALUES (u_record.id_usuario, 'entretenimiento', 'Suscripciones y Salidas') RETURNING id_tipo INTO t_entretenimiento;

        -- Finanzas para Agosto y Septiembre de 2026
        INSERT INTO finanzas (id_usuario, fecha, entrada_dinero, presupuesto_gastos)
        VALUES 
            (u_record.id_usuario, '2026-08-01', 3500000.00, 2200000.00),
            (u_record.id_usuario, '2026-09-01', 3500000.00, 2200000.00);

        -- Generar 15 gastos por usuario
        FOR j IN 1..15 LOOP
            
            v_fecha := '2026-08-01 08:00:00'::timestamp + (random() * (interval '60 days'));
            
            CASE (j % 5)
                WHEN 0 THEN 
                    v_precio := (800000 + (random() * 200000))::NUMERIC(12,2);
                    t_cat_id := t_arriendo;
                WHEN 1 THEN 
                    v_precio := (120000 + (random() * 80000))::NUMERIC(12,2);
                    t_cat_id := t_servicios;
                WHEN 2 THEN 
                    v_precio := (250000 + (random() * 150000))::NUMERIC(12,2);
                    t_cat_id := t_mercado;
                WHEN 3 THEN 
                    v_precio := (50000 + (random() * 50000))::NUMERIC(12,2);
                    t_cat_id := t_transporte;
                ELSE 
                    v_precio := (30000 + (random() * 70000))::NUMERIC(12,2);
                    t_cat_id := t_entretenimiento;
            END CASE;

            IF v_fecha < '2026-09-01 00:00:00' THEN
                v_estado := 'pagado';
            ELSE
                v_estado := CASE WHEN random() > 0.4 THEN 'pendiente' ELSE 'pagado' END;
            END IF;

            INSERT INTO gasto (id_tipo, fecha_vencimiento, precio, estado)
            VALUES (t_cat_id, v_fecha, v_precio, v_estado);
            
        END LOOP;
    END LOOP;
END $$;