-- 1. Llenar la tabla CLIENTES (30,000 registros)
INSERT INTO clientes (nombre, email, fecha_registro)
SELECT 
    (ARRAY['Carlos', 'Ana', 'Luis', 'María', 'Jorge', 'Sofia', 'Pedro', 'Elena', 'Diego', 'Lucía', 'Mateo', 'Valeria', 'Javier', 'Camila'])[FLOOR(RANDOM() * 14 + 1)] || ' ' ||
    (ARRAY['Gómez', 'Pérez', 'López', 'Rodríguez', 'Fernández', 'García', 'Martínez', 'Sánchez', 'Romero', 'Torres'])[FLOOR(RANDOM() * 10 + 1)] AS nombre,
    'cliente_' || i || '_' || MD5(RANDOM()::text || i::text) || '@email.com' AS email,
    NOW() - (RANDOM() * INTERVAL '730 days') AS fecha_registro
FROM generate_series(1, 30000) AS i;


-- 2. Llenar la tabla PRODUCTOS (30,000 registros)
INSERT INTO productos (nombre, categoria, precio, stock)
SELECT 
    (ARRAY['Teclado', 'Mouse', 'Monitor', 'Laptop', 'Audífonos', 'Silla Gamer', 'Escritorio', 'Micrófono', 'Cámara Web', 'Router', 'Disco SSD', 'Memoria RAM'])[FLOOR(RANDOM() * 12 + 1)] || ' ' ||
    (ARRAY['Pro', 'Ultra', 'Basic', 'Gaming', 'Max', 'Plus', 'Eco', 'Slim'])[FLOOR(RANDOM() * 8 + 1)] || ' ' || i AS nombre,
    (ARRAY['Electrónica', 'Accesorios', 'Computadoras', 'Oficina', 'Audio'])[FLOOR(RANDOM() * 5 + 1)] AS categoria,
    ROUND((5.00 + RANDOM() * 1495.00)::numeric, 2) AS precio,
    FLOOR(RANDOM() * 500)::int AS stock
FROM generate_series(1, 30000) AS i;


-- 3. Llenar la tabla CUPONES (30,000 registros)
INSERT INTO cupones (codigo, porcentaje_descuento, fecha_inicio, fecha_fin)
SELECT 
    'CUPON_' || i || '_' || UPPER(SUBSTRING(MD5(i::text) FROM 1 FOR 6)) AS codigo,
    ROUND((5.00 + RANDOM() * 45.00)::numeric, 2) AS porcentaje_descuento,
    f_inicio AS fecha_inicio,
    f_inicio + (INTERVAL '1 day' * FLOOR(1 + RANDOM() * 30)) AS fecha_fin
FROM (
    SELECT 
        i,
        NOW() - (RANDOM() * INTERVAL '365 days') AS f_inicio
    FROM generate_series(1, 30000) AS i
) sub;


-- 4. Llenar la tabla PEDIDOS (30,000 registros)
INSERT INTO pedidos (cliente_id, cupon_id, fecha_pedido, estado)
SELECT 
    FLOOR(1 + RANDOM() * 30000)::int AS cliente_id,
    -- ~30% de probabilidad de tener un cupón asignado
    CASE WHEN RANDOM() < 0.30 THEN FLOOR(1 + RANDOM() * 30000)::int ELSE NULL END AS cupon_id,
    NOW() - (RANDOM() * INTERVAL '365 days') AS fecha_pedido,
    (ARRAY['pendiente', 'completado', 'cancelado'])[
        CASE 
            WHEN r < 0.15 THEN 1 -- 15% pendientes
            WHEN r < 0.85 THEN 2 -- 70% completados
            ELSE 3               -- 15% cancelados
        END
    ] AS estado
FROM (
    SELECT RANDOM() AS r FROM generate_series(1, 30000)
) sub;


-- 5. Llenar la tabla DETALLE_PEDIDOS (30,000 registros)
-- Asigna exactamente 1 producto a cada uno de los 30,000 pedidos para cumplir la restricción UNIQUE (pedido_id, producto_id)
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario)
SELECT 
    i AS pedido_id,
    FLOOR(1 + RANDOM() * 30000)::int AS producto_id,
    FLOOR(1 + RANDOM() * 5)::int AS cantidad,
    ROUND((10.00 + RANDOM() * 490.00)::numeric, 2) AS precio_unitario
FROM generate_series(1, 30000) AS i;