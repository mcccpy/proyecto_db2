--Comando para ver datos
--EXPLAIN (ANALYZE, BUFFERS)




1 indexacion adecuada 1 2 3 #

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, cliente_id, fecha_pedido, estado
FROM pedidos
WHERE fecha_pedido >= '2026-01-01 00:00:00';

optimizada

CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);

EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, cliente_id, fecha_pedido, estado
FROM pedidos
WHERE fecha_pedido >= '2026-01-01 00:00:00';

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id, porcentaje_descuento, fecha_fin
FROM cupones
WHERE codigo = 'DESCUENTO2026';

optimizada

CREATE INDEX idx_cupones_codigo_hash ON cupones USING HASH (codigo);

EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id, porcentaje_descuento, fecha_fin
FROM cupones
WHERE codigo = 'DESCUENTO2026';

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT  nombre, precio
FROM productos
WHERE nombre LIKE '%Laptop%';

optimizada

-- Activar la extensión para patrones de texto
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- Crear el índice GIN sobre la columna nombre
CREATE INDEX idx_productos_nombre_gin ON productos USING GIN (nombre gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT  nombre, precio
FROM productos
WHERE nombre LIKE '%Laptop%';

2 select * #

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clientes;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre,email FROM clientes;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM productos 
WHERE precio > 100;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio 
FROM productos 
WHERE precio > 100;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM detalle_pedidos 
WHERE pedido_id = 1;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, cantidad, precio_unitario 
FROM detalle_pedidos 
WHERE pedido_id = 1;

3 limit #

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos
LIMIT 100;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, fecha_pedido 
FROM pedidos 
ORDER BY fecha_pedido DESC;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, fecha_pedido 
FROM pedidos 
ORDER BY fecha_pedido DESC 
LIMIT 10;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio 
FROM productos 
ORDER BY producto_id;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio 
FROM productos 
ORDER BY producto_id 
LIMIT 20 OFFSET 0;

4 join

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM pedidos p
JOIN clientes c ON p.cliente_id = c.cliente_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
JOIN productos pr ON dp.producto_id = pr.producto_id;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.pedido_id, c.nombre AS cliente, pr.nombre AS producto, dp.cantidad
FROM pedidos p
JOIN clientes c ON p.cliente_id = c.cliente_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
JOIN productos pr ON dp.producto_id = pr.producto_id
WHERE p.estado = 'completado';


no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT c.cliente_id, c.nombre
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.cliente_id, c.nombre
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cliente_id = c.cliente_id
);

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, co.codigo 
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id
JOIN cupones co ON p.cupon_id = co.cupon_id
WHERE p.cupon_id IS NOT NULL;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, co.codigo 
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id AND p.cupon_id IS NOT NULL
JOIN cupones co ON p.cupon_id = co.cupon_id;

5 explain o explain plan #

EXPLAIN 
SELECT * FROM clientes;

EXPLAIN ANALYZE
SELECT * FROM clientes;

EXPLAIN 
SELECT producto_id, SUM(cantidad) FROM detalle_pedidos GROUP BY producto_id;

EXPLAIN (ANALYZE, BUFFERS) 
SELECT producto_id, SUM(cantidad) FROM detalle_pedidos GROUP BY producto_id;

EXPLAIN 
SELECT * FROM pedidos WHERE fecha_pedido > '2026-01-01';

EXPLAIN (ANALYZE, VERBOSE) 
SELECT pedido_id, cliente_id, fecha_pedido FROM pedidos WHERE fecha_pedido > '2026-01-01';

6 where + filtro

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id, nombre, email 
FROM clientes
WHERE LOWER(email) = 'usuario@email.com';

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id, nombre, email 
FROM clientes
WHERE email = 'usuario@email.com';

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, fecha_pedido 
FROM pedidos 
WHERE EXTRACT(YEAR FROM fecha_pedido) = 2026;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, fecha_pedido 
FROM pedidos 
WHERE fecha_pedido >= '2026-01-01 00:00:00' AND fecha_pedido <= '2026-12-31 23:59:59';

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio 
FROM productos 
WHERE precio * 1.15 > 100;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio 
FROM productos 
WHERE precio > (100 / 1.15);

7 exists en lugar de in #

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, email FROM clientes
WHERE cliente_id IN (
    SELECT cliente_id FROM pedidos
);

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, c.email FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cliente_id = c.cliente_id
);

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre 
FROM productos 
WHERE producto_id IN (SELECT producto_id FROM detalle_pedidos);

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT pr.producto_id, pr.nombre 
FROM productos pr
WHERE EXISTS (
    SELECT 1 
    FROM detalle_pedidos dp 
    WHERE dp.producto_id = pr.producto_id
);

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre 
FROM productos 
WHERE producto_id IN (SELECT producto_id FROM detalle_pedidos);

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT pr.producto_id, pr.nombre 
FROM productos pr
WHERE EXISTS (
    SELECT 1 
    FROM detalle_pedidos dp 
    WHERE dp.producto_id = pr.producto_id
);

8 group by en lugar de distinct #

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT cliente_id 
FROM pedidos;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id 
FROM pedidos 
GROUP BY cliente_id;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT categoria 
FROM productos;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT categoria 
FROM productos 
GROUP BY categoria;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT producto_id 
FROM detalle_pedidos;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id 
FROM detalle_pedidos 
GROUP BY producto_id;

9 store procedure #

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT precio FROM productos WHERE producto_id = 1;
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO pedidos (cliente_id, cupon_id) VALUES (1, NULL);

optimizada

CREATE OR REPLACE PROCEDURE registrar_pedido(
    p_cliente_id INT,
    p_producto_id INT,
    p_cantidad INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_precio NUMERIC(10,2);
    v_pedido_id INT;
BEGIN
    SELECT precio INTO v_precio FROM productos WHERE producto_id = p_producto_id;
    
    INSERT INTO pedidos (cliente_id) VALUES (p_cliente_id) 
    RETURNING pedido_id INTO v_pedido_id;

END;
$$;

CALL registrar_pedido(1, 1, 2);

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
UPDATE productos SET stock = stock - 1 WHERE producto_id = 10;
EXPLAIN (ANALYZE, BUFFERS)
UPDATE productos SET stock = stock - 2 WHERE producto_id = 12;

optimizada

CREATE OR REPLACE PROCEDURE descontar_stock(
    p_producto_id INT,
    p_cantidad INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE productos 
    SET stock = stock - p_cantidad 
    WHERE producto_id = p_producto_id;
END;
$$;

CALL descontar_stock(10, 1);

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO clientes (nombre, email) VALUES ('Juan', 'juan@email.com');
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO productos (precio, nombre,categoria) VALUES (20, 'producto','nose');

optimizada

CREATE OR REPLACE PROCEDURE insertar_datos(
    p_nombre_cliente VARCHAR,
    p_email VARCHAR,
    p_precio NUMERIC,
    p_nombre_producto VARCHAR,
    p_categoria VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO clientes (nombre, email)
    VALUES (p_nombre_cliente, p_email);

    INSERT INTO productos (precio, nombre, categoria)
    VALUES (p_precio, p_nombre_producto, p_categoria);
END;
$$;

CALL insertar_datos(
    'Juan',
    'juan@email.com',
    20,
    'producto',
    'nose'
);



10 union all en lugar de union#

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id FROM cupones
UNION 
SELECT cupon_id FROM pedidos;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id FROM cupones
UNION ALL
SELECT cupon_id FROM pedidos;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, email FROM clientes WHERE fecha_registro < '2026-03-01'
UNION
SELECT nombre, email FROM clientes WHERE fecha_registro >= '2026-03-01';

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, email FROM clientes WHERE fecha_registro < '2026-03-01'
UNION ALL
SELECT nombre, email FROM clientes WHERE fecha_registro >= '2026-03-01';

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id AS id_relacionado, 'Pedido Realizado' AS tipo_evento, fecha_pedido AS fecha FROM pedidos
UNION
SELECT cupon_id AS id_relacionado, 'Cupón Creado' AS tipo_evento, fecha_inicio AS fecha FROM cupones;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id AS id_relacionado, 'Pedido Realizado' AS tipo_evento, fecha_pedido AS fecha FROM pedidos
UNION ALL
SELECT cupon_id AS id_relacionado, 'Cupón Creado' AS tipo_evento, fecha_inicio AS fecha FROM cupones;

11 evitar el DISTINCT

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT c.cliente_id, c.nombre, c.email
FROM clientes c
INNER JOIN pedidos p ON c.cliente_id = p.cliente_id
WHERE p.estado = 'completado';

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.cliente_id, c.nombre, c.email
FROM clientes c
WHERE EXISTS (
    SELECT 1 
    FROM pedidos p 
    WHERE p.cliente_id = c.cliente_id 
      AND p.estado = 'completado'
);

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT 
    pr.producto_id, 
    pr.nombre, 
    SUM(dp.cantidad) OVER (PARTITION BY pr.producto_id) AS total_vendido
FROM productos pr
INNER JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    pr.producto_id, 
    pr.nombre, 
    SUM(dp.cantidad) AS total_vendido
FROM productos pr
INNER JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id
GROUP BY pr.producto_id, pr.nombre;

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT cp.cupon_id, cp.codigo, cp.porcentaje_descuento
FROM cupones cp
INNER JOIN pedidos p ON cp.cupon_id = p.cupon_id;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT cp.cupon_id, cp.codigo, cp.porcentaje_descuento
FROM cupones cp
WHERE cp.cupon_id IN (
    SELECT p.cupon_id 
    FROM pedidos p 
    WHERE p.cupon_id IS NOT NULL
);