Comando para ver datos
EXPLAIN (ANALYZE, BUFFERS)




1 indexacion adecuada 1 2 3
2 select *

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clientes;

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre,email FROM clientes;

3 limit 

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM productos
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT nombre,categoria,precio,stock FROM productos
LIMIT 100;  

4 join

EXPLAIN (ANALYZE, BUFFERS)


5 explain o explain plan
6 where + filtro
7 exists en lugar de in
8 group by en lugar de distinct
9 store procedure
10 union all en lugar de union

