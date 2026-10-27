-- Creación de la base de datos (ejecutar por separado si es necesario)
-- CREATE DATABASE ecommerce_db;

-- 1. Tabla: clientes
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla: productos
CREATE TABLE productos (
    producto_id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    precio NUMERIC(10, 2) NOT NULL CHECK (precio >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

-- 3. Tabla: cupones
CREATE TABLE cupones (
    cupon_id SERIAL PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE NOT NULL,
    porcentaje_descuento NUMERIC(5, 2) NOT NULL CHECK (porcentaje_descuento BETWEEN 0.01 AND 100.00),
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    CHECK (fecha_fin > fecha_inicio)
);

-- 4. Tabla: pedidos
CREATE TABLE pedidos (
    pedido_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    cupon_id INT, -- Puede ser NULL si no aplicó ningún cupón
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'completado' CHECK (estado IN ('pendiente', 'completado', 'cancelado')),
    FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id) ON DELETE RESTRICT,
    FOREIGN KEY (cupon_id) REFERENCES cupones(cupon_id) ON DELETE SET NULL
);

-- 5. Tabla: detalle_pedidos (Relación N:M entre pedidos y productos)
CREATE TABLE detalle_pedidos (
    detalle_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(producto_id) ON DELETE RESTRICT,
    CONSTRAINT uq_pedido_producto UNIQUE (pedido_id, producto_id)
);