# 🚀 Guía de Optimización de Consultas SQL (PostgreSQL)

Esta guía documenta los patrones más comunes para optimizar consultas SQL utilizando `EXPLAIN (ANALYZE, BUFFERS)` para medir y mejorar el rendimiento de la base de datos. Está estructurada para copiar y pegar rápidamente el código optimizado.

---

## 📌 Tabla de Contenidos
1. [Indexación Adecuada](#1-indexación-adecuada)
2. [Evitar `SELECT *`](#2-evitar-select-)
3. [Uso Eficiente de `LIMIT`](#3-uso-eficiente-de-limit)
4. [Optimización de `JOIN`](#4-optimización-de-join)
5. [`EXPLAIN` vs `EXPLAIN (ANALYZE, BUFFERS)`](#5-explain-vs-explain-analyze-buffers)
6. [Filtros SARGables en `WHERE`](#6-filtros-sargables-en-where)
7. [`EXISTS` en lugar de `IN`](#7-exists-en-lugar-de-in)
8. [`GROUP BY` en lugar de `DISTINCT`](#8-group-by-en-lugar-de-distinct)
9. [Procedimientos Almacenados (`STORED PROCEDURES`)](#9-procedimientos-almacenados)
10. [`UNION ALL` en lugar de `UNION`](#10-union-all-en-lugar-de-union)
11. [Evitar el `DISTINCT`](#11-evitar-el-distinct)

---

## 1. Indexación Adecuada

### Caso 1.1: Búsqueda por Rango de Fechas (Índice B-Tree)
#### ❌ No Optimizada (Seq Scan)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, cliente_id, fecha_pedido, estado
FROM pedidos
WHERE fecha_pedido >= '2026-01-01 00:00:00';
```
#### ⚡ Optimizada (Index Scan / Index Only Scan)
```sql
-- Creación del índice
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);

-- Consulta
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, cliente_id, fecha_pedido, estado
FROM pedidos
WHERE fecha_pedido >= '2026-01-01 00:00:00';
```

### Caso 1.2: Búsqueda por Igualdad Exacta (Índice Hash)
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id, porcentaje_descuento, fecha_fin
FROM cupones
WHERE codigo = 'DESCUENTO2026';
```
#### ⚡ Optimizada (Hash Index para '=' directo)
```sql
-- Creación del índice
CREATE INDEX idx_cupones_codigo_hash ON cupones USING HASH (codigo);

-- Consulta
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id, porcentaje_descuento, fecha_fin
FROM cupones
WHERE codigo = 'DESCUENTO2026';
```

### Caso 1.3: Búsqueda de Texto Parcial (Índice GIN / Trigramas)
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, precio
FROM productos
WHERE nombre LIKE '%Laptop%';
```
#### ⚡ Optimizada
```sql
-- Activar la extensión para patrones de texto
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Crear el índice GIN sobre la columna nombre
CREATE INDEX idx_productos_nombre_gin ON productos USING GIN (nombre gin_trgm_ops);

-- Consulta
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, precio
FROM productos
WHERE nombre LIKE '%Laptop%';
```

---

## 2. Evitar `SELECT *`

### Caso 2.1: Consulta Simple de Clientes
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clientes;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, email FROM clientes;
```

### Caso 2.2: Consulta de Productos Filtrados
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM productos 
WHERE precio > 100;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio 
FROM productos 
WHERE precio > 100;
```

### Caso 2.3: Consulta a Tabla Transaccional (Detalles)
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM detalle_pedidos;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, producto_id, cantidad, precio_unitario 
FROM detalle_pedidos;
```

---

## 3. Uso Eficiente de `LIMIT`

### Caso 3.1: Escaneo Completo sin Restricción
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos
LIMIT 100;
```

### Caso 3.2: Selección Especifica con Límite
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, categoria, precio, stock FROM productos
LIMIT 100;
```

### Caso 3.3: Paginación Ordenada de Grandes Lotes
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM pedidos 
ORDER BY fecha_pedido DESC;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, fecha_pedido, estado FROM pedidos 
ORDER BY fecha_pedido DESC 
LIMIT 50 OFFSET 0;
```

---

## 4. Optimización de `JOIN`

### Caso 4.1: Proyección Innecesaria y Falta de Filtros
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

### Caso 4.2: Verificación de Existencia mediante JOIN con DISTINCT
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

### Caso 4.3: Subconsultas en JOIN vs Filtros Directos
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, p.pedido_id
FROM clientes c
LEFT JOIN (SELECT * FROM pedidos WHERE estado = 'completado') p 
  ON c.cliente_id = p.cliente_id;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, p.pedido_id
FROM clientes c
LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id AND p.estado = 'completado';
```

---

## 5. `EXPLAIN` vs `EXPLAIN (ANALYZE, BUFFERS)`

### Caso 5.1: Análisis de Costo Estático vs Tiempo Real
#### ❌ Solo Estimación Teórica
```sql
EXPLAIN 
SELECT * FROM clientes;
```
#### ⚡ Análisis Real con Uso de Caché/Buffer
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clientes;
```

### Caso 5.2: Diagnóstico Detallado de Filtros
#### ❌ Solo Plan
```sql
EXPLAIN 
SELECT * FROM productos WHERE precio > 500;
```
#### ⚡ Plan + Ejecución + Nombres de Tablas/Columnas
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM productos WHERE precio > 500;
```

### Caso 5.3: Medición de Subconsultas Complejas
#### ❌ Solo Plan
```sql
EXPLAIN 
SELECT nombre FROM clientes WHERE cliente_id IN (SELECT cliente_id FROM pedidos);
```
#### ⚡ Medición de Tiempos Reales de la Subconsulta
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre FROM clientes WHERE cliente_id IN (SELECT cliente_id FROM pedidos);
```

---

## 6. Filtros SARGables en `WHERE`

### Caso 6.1: Funciones de Texto sobre Columnas (Invalida Índices)
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id, nombre, email 
FROM clientes
WHERE LOWER(email) = 'usuario@email.com';
```
#### ⚡ Optimizada (SARGable)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id, nombre, email 
FROM clientes
WHERE email = 'usuario@email.com';
```

### Caso 6.2: Operaciones Matemáticas sobre Columnas
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio
FROM productos
WHERE precio * 0.9 < 100;
```
#### ⚡ Optimizada (Constante despejada)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT producto_id, nombre, precio
FROM productos
WHERE precio < 100 / 0.9;
```

### Caso 6.3: Comodines Wildcard al Inicio del String
#### ❌ No Optimizada (Invalida B-Tree)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT codigo, porcentaje_descuento
FROM cupones
WHERE codigo LIKE '%DESCUENTO';
```
#### ⚡ Optimizada (Permite búsqueda por prefijo)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT codigo, porcentaje_descuento
FROM cupones
WHERE codigo LIKE 'DESCUENTO%';
```

---

## 7. `EXISTS` en lugar de `IN`

### Caso 7.1: Filtrar Clientes con Registro de Pedidos
#### ❌ No Optimizada (`IN` evalúa toda la subconsulta)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre, email FROM clientes
WHERE cliente_id IN (
    SELECT cliente_id FROM pedidos
);
```
#### ⚡ Optimizada (`EXISTS` se detiene en la primera coincidencia)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nombre, c.email FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cliente_id = c.cliente_id
);
```

### Caso 7.2: Exclusión de Registros (`NOT IN` vs `NOT EXISTS`)
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre FROM productos
WHERE producto_id NOT IN (
    SELECT producto_id FROM detalle_pedidos WHERE producto_id IS NOT NULL
);
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.nombre FROM productos p
WHERE NOT EXISTS (
    SELECT 1 FROM detalle_pedidos dp WHERE dp.producto_id = p.producto_id
);
```

### Caso 7.3: Verificación con Condiciones Adicionales
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id, codigo FROM cupones
WHERE cupon_id IN (
    SELECT cupon_id FROM pedidos WHERE estado = 'completado'
);
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.cupon_id, c.codigo FROM cupones c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cupon_id = c.cupon_id AND p.estado = 'completado'
);
```

---

## 8. `GROUP BY` en lugar de `DISTINCT`

### Caso 8.1: Obtención de IDs Únicos
#### ❌ No Optimizada (Sort / Unique Hash adicional)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT cliente_id 
FROM pedidos;
```
#### ⚡ Optimizada (Agrupamiento nativo)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id 
FROM pedidos 
GROUP BY cliente_id;
```

### Caso 8.2: Combinaciones Únicas de Múltiples Columnas
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT cliente_id, estado 
FROM pedidos;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente_id, estado 
FROM pedidos 
GROUP BY cliente_id, estado;
```

### Caso 8.3: Eliminación de Duplicados en Consultas Relacionadas
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT c.cliente_id, c.email
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.cliente_id, c.email
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id
GROUP BY c.cliente_id, c.email;
```

---

## 9. Procedimientos Almacenados (`STORED PROCEDURES`)

### Caso 9.1: Proceso Transaccional de Pedidos
#### ❌ No Optimizada (Múltiples ida y vuelta de red)
```sql
-- 1. Consultar precio
EXPLAIN (ANALYZE, BUFFERS)
SELECT precio FROM productos WHERE producto_id = 1;

-- 2. Insertar pedido individualmente
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO pedidos (cliente_id) VALUES (1);
```
#### ⚡ Optimizada (Encapsulado en el motor)
```sql
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

-- Ejecución
CALL registrar_pedido(1, 1, 2);
```

### Caso 9.2: Actualización de Inventario
#### ❌ No Optimizada
```sql
-- Consultas independientes consecutivas desde el cliente
UPDATE productos SET stock = stock - 1 WHERE producto_id = 10;
UPDATE productos SET stock = stock - 2 WHERE producto_id = 12;
```
#### ⚡ Optimizada
```sql
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
```

### Caso 9.3: Registro Unificado de Clientes y Preferencias
#### ❌ No Optimizada
```sql
INSERT INTO clientes (nombre, email) VALUES ('Juan', 'juan@email.com');
-- El cliente obtiene el ID manualmente y ejecuta otra consulta:
INSERT INTO preferencias (cliente_id, tema) VALUES (1, 'dark');
```
#### ⚡ Optimizada
```sql
CREATE OR REPLACE PROCEDURE registrar_cliente_con_preferencia(
    p_nombre VARCHAR,
    p_email VARCHAR,
    p_tema VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cliente_id INT;
BEGIN
    INSERT INTO clientes (nombre, email) 
    VALUES (p_nombre, p_email)
    RETURNING cliente_id INTO v_cliente_id;
    
    INSERT INTO preferencias (cliente_id, tema) 
    VALUES (v_cliente_id, p_tema);
END;
$$;

CALL registrar_cliente_con_preferencia('Juan', 'juan@email.com', 'dark');
```

---

## 10. `UNION ALL` en lugar de `UNION`

### Caso 10.1: Concatenación de IDs de Cupones y Pedidos
#### ❌ No Optimizada (`UNION` ejecuta una deduplicación implícita costosa)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id FROM cupones
UNION 
SELECT cupon_id FROM pedidos;
```
#### ⚡ Optimizada (`UNION ALL` simplemente concatena los resultados)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cupon_id FROM cupones
UNION ALL
SELECT cupon_id FROM pedidos;
```

### Caso 10.2: Consolidación de Correos Electrónicos
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT email FROM clientes
UNION
SELECT email FROM proveedores;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT email FROM clientes
UNION ALL
SELECT email FROM proveedores;
```

### Caso 10.3: Consolidación de Históricos por Tablas Anuales
#### ❌ No Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, fecha_pedido FROM pedidos_2025
UNION
SELECT pedido_id, fecha_pedido FROM pedidos_2026;
```
#### ⚡ Optimizada
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT pedido_id, fecha_pedido FROM pedidos_2025
UNION ALL
SELECT pedido_id, fecha_pedido FROM pedidos_2026;
```

---

## 11. Evitar el `DISTINCT`

### Caso 11.1: Clientes con al menos un pedido completado

#### ❌ No Optimizada (`JOIN` multiplica filas y `DISTINCT` fuerza un ordenamiento/hash costoso)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT c.cliente_id, c.nombre, c.email
FROM clientes c
INNER JOIN pedidos p ON c.cliente_id = p.cliente_id
WHERE p.estado = 'completado';

```

#### ⚡ Optimizada (`EXISTS` detiene la búsqueda al encontrar la primera coincidencia)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.cliente_id, c.nombre, c.email
FROM clientes c
WHERE EXISTS (
    SELECT 1 
    FROM pedidos p 
    WHERE p.cliente_id = c.cliente_id 
      AND p.estado = 'completado'
);

```

### Caso 11.2: Total de unidades vendidas por producto

#### ❌ No Optimizada (`DISTINCT` elimina duplicados después de calcular la ventana sobre todas las filas)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT 
    pr.producto_id, 
    pr.nombre, 
    SUM(dp.cantidad) OVER (PARTITION BY pr.producto_id) AS total_vendido
FROM productos pr
INNER JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id;

```

#### ⚡ Optimizada (`GROUP BY` agrupa nativamente antes de calcular la agregación)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    pr.producto_id, 
    pr.nombre, 
    SUM(dp.cantidad) AS total_vendido
FROM productos pr
INNER JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id
GROUP BY pr.producto_id, pr.nombre;

```

### Caso 11.3: Cupones utilizados al menos una vez

#### ❌ No Optimizada (`JOIN` masivo contra pedidos para luego deduplicar)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT cp.cupon_id, cp.codigo, cp.porcentaje_descuento
FROM cupones cp
INNER JOIN pedidos p ON cp.cupon_id = p.cupon_id;

```

#### ⚡ Optimizada (Subconsulta con `IN` evalúa solo las llaves foráneas no nulas)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT cp.cupon_id, cp.codigo, cp.porcentaje_descuento
FROM cupones cp
WHERE cp.cupon_id IN (
    SELECT p.cupon_id 
    FROM pedidos p 
    WHERE p.cupon_id IS NOT NULL
);

```