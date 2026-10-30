# 🚀 Guía de Optimización de Consultas SQL (PostgreSQL)

Esta guía documenta los patrones más comunes para optimizar consultas SQL utilizando `EXPLAIN (ANALYZE, BUFFERS)` para medir y mejorar el rendimiento de la base de datos.

---

## 📌 Tabla de Contenidos
1. [Indexación Adecuada (B-Tree, Hash, GIN)](#1-indexación-adecuada)
2. [Evitar `SELECT *`](#2-evitar-select-)
3. [Uso Eficiente de `LIMIT`](#3-uso-eficiente-de-limit)
4. [Optimización de `JOIN`](#4-optimización-de-join)
5. [`EXPLAIN` vs `EXPLAIN (ANALYZE, BUFFERS)`](#5-explain-vs-explain-analyze-buffers)
6. [Filtros SARGables en `WHERE`](#6-filtros-sargables-en-where)
7. [`EXISTS` en lugar de `IN`](#7-exists-en-lugar-de-in)
8. [`GROUP BY` en lugar de `DISTINCT`](#8-group-by-en-lugar-de-distinct)
9. [Procedimientos Almacenados (`STORED PROCEDURES`)](#9-procedimientos-almacenados)
10. [`UNION ALL` en lugar de `UNION`](#10-union-all-en-lugar-de-union)

---

## 1. Indexación Adecuada

### ❌ No Optimizada (Sin Índice / Seq Scan)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, cliente_id, fecha_pedido, estado
FROM pedidos
WHERE fecha_pedido >= '2026-01-01 00:00:00';
```

### ⚡ Optimizada - Índice B-Tree (Rangos y Comparaciones)
```sql
-- Creación del índice
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);

-- Consulta
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, cliente_id, fecha_pedido, estado
FROM pedidos
WHERE fecha_pedido >= '2026-01-01 00:00:00';
```

### ⚡ Optimizada - Índice Hash (Igualdad Exacta)
```sql
-- Creación del índice
CREATE INDEX idx_cupones_codigo_hash ON cupones USING HASH (codigo);

-- Consulta
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id, porcentaje_descuento, fecha_fin
FROM cupones
WHERE codigo = 'DESCUENTO2026';
```

### ⚡ Optimizada - Índice GIN (Búsqueda por Texto/Trigramas)
```sql
-- Activar la extensión para patrones de texto
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Crear el índice GIN sobre la columna nombre
CREATE INDEX idx_productos_nombre_gin ON productos USING GIN (nombre gin_trgm_ops);

-- Consulta
EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio
FROM productos
WHERE nombre LIKE '%Laptop%';
```

---

## 2. Evitar `SELECT *`

### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clientes;
```

### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, email FROM clientes;
```

---

## 3. Uso Eficiente de `LIMIT`

### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos;
```

### ⚠️ Optimizada Parcialmente (Con LIMIT)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos
LIMIT 100;
```

### ⚡ Optimizada Completa (Campos Especificos + LIMIT)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, categoria, precio, stock FROM productos
LIMIT 100;
```

---

## 4. Optimización de `JOIN`

### Caso A: Proyección Innecesaria y Falta de Filtros
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM pedidos p
JOIN clientes c ON p.cliente_id = c.cliente_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
JOIN productos pr ON dp.producto_id = pr.producto_id;
```

#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.pedido_id, c.nombre AS cliente, pr.nombre AS producto, dp.cantidad
FROM pedidos p
JOIN clientes c ON p.cliente_id = c.cliente_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
JOIN productos pr ON dp.producto_id = pr.producto_id
WHERE p.estado = 'completado';
```

---

### Caso B: Verificación de Existencia en lugar de JOIN
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT c.cliente_id, c.nombre
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id;
```

#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.cliente_id, c.nombre
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cliente_id = c.cliente_id
);
```

---

## 5. `EXPLAIN` vs `EXPLAIN (ANALYZE, BUFFERS)`

### 🔍 Estimación teórica (No ejecuta la consulta)
```sql
EXPLAIN 
SELECT * FROM clientes;
```

### ⏱️ Ejecución real + Análisis de I/O de Memoria y Disco
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clientes;
```

---

## 6. Filtros SARGables en `WHERE`

### ❌ No Optimizada (Uso de Funciones anula el índice)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id, nombre, email 
FROM clientes
WHERE LOWER(email) = 'usuario@email.com';
```

### ⚡ Optimizada (Filtro Directo SARGable)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id, nombre, email 
FROM clientes
WHERE email = 'usuario@email.com';
```

---

## 7. `EXISTS` en lugar de `IN`

### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, email FROM clientes
WHERE cliente_id IN (
    SELECT cliente_id FROM pedidos
);
```

### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, c.email FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cliente_id = c.cliente_id
);
```

---

## 8. `GROUP BY` en lugar de `DISTINCT`

### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT cliente_id 
FROM pedidos;
```

### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id 
FROM pedidos 
GROUP BY cliente_id;
```

---

## 9. Procedimientos Almacenados (`STORED PROCEDURES`)

### ❌ No Optimizada (Múltiples solicitudes de red desde la aplicación)
```sql
-- 1. Consultar precio
EXPLAIN (ANALYZE, BUFFERS)
SELECT precio FROM productos WHERE producto_id = 1;

-- 2. Insertar pedido individualmente
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO pedidos (cliente_id, cupon_id) VALUES (1, NULL);
```

### ⚡ Optimizada (Encapsulación lógica en la Base de Datos)
```sql
-- Definición del Procedimiento Almacenado
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

-- Ejecución en un solo Round-Trip de red
CALL registrar_pedido(1, 1, 2);
```

---

## 10. `UNION ALL` en lugar de `UNION`

### ❌ No Optimizada (`UNION` ejecuta eliminación implícita de duplicados con Sort/Hash)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id FROM cupones
UNION 
SELECT cupon_id FROM pedidos;
```

### ⚡ Optimizada (`UNION ALL` combina los resultados directamente)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id FROM cupones
UNION ALL
SELECT cupon_id FROM pedidos;
```
