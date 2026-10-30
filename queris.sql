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

optimizada

CREATE INDEX idx_cupones_codigo_hash ON cupones USING HASH (codigo);

EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id, porcentaje_descuento, fecha_fin
FROM cupones
WHERE codigo = 'DESCUENTO2026';

optimizada

-- Activar la extensión para patrones de texto
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- Crear el índice GIN sobre la columna nombre
CREATE INDEX idx_productos_nombre_gin ON productos USING GIN (nombre gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio
FROM productos
WHERE nombre LIKE '%Laptop%';

2 select * #

no optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clientes;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre,email FROM clientes;

3 limit #

no optimizada


EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos;

optimizada

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos
LIMIT 100;

optimizada+

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre,categoria,precio,stock FROM productos
LIMIT 100;  

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


5 explain o explain plan #

EXPLAIN 
SELECT * FROM clientes;

EXPLAIN ANALYZE
SELECT * FROM clientes;

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

9 store procedure #

no optimizada

-- 1. Consultar precio
EXPLAIN (ANALYZE, BUFFERS)
SELECT precio FROM productos WHERE producto_id = 1;
-- 2. Insertar pedido individualmente
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO pedidos (cliente_id, cupon_id) VALUES (1, NULL);

optimizada

-- Creación del procedimiento almacenado
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
    
    INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario)
    VALUES (v_pedido_id, p_producto_id, p_cantidad, v_precio);
END;
$$;

-- Ejecución y análisis de la llamada
EXPLAIN (ANALYZE, BUFFERS)  ??
CALL registrar_pedido(1, 1, 2);


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
