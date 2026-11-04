-- =====================================================================
-- Archivo  : m4_consultas_negocio.sql
-- Proyecto : Ventas_Tech_DB · Pre-entrega Módulo 4
-- Título   : Extrayendo métricas clave con SQL
-- Autora   : Salva, María Gimena
-- Motor    : SQL Server, ejecutado en SQL Server Management Studio (SSMS)
-- Base     : Ventas_Tech_DB (creada en el Módulo 3)
-- Alcance  : solo la tabla ventas. Se trabaja con id_cliente e id_producto;
--            los nombres se van a traer con JOIN en el Módulo 5.
-- Importe  : en todas las consultas, el total de cada venta se calcula
--            como cantidad * precio_unitario.
-- =====================================================================

USE Ventas_Tech_DB;
GO

-- =====================================================================
-- CONSULTA 1 · Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- Se agrupa también por año para que, cuando haya más de un año de
-- datos, marzo 2024 y marzo 2025 no se sumen juntos.
-- Resultado esperado con los datos de M3: 1 fila (marzo 2024).
-- Brief M1 · P1 (evolución mensual) y P4 (transacciones y ticket).
-- =====================================================================
SELECT
    YEAR(fecha_venta)                 AS anio,
    MONTH(fecha_venta)                AS mes,
    SUM(cantidad * precio_unitario)   AS total_facturado,
    COUNT(*)                          AS cantidad_pedidos,
    AVG(cantidad * precio_unitario)   AS ticket_promedio
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio, mes;

-- =====================================================================
-- CONSULTA 2 · Ranking de productos
-- Top 5 de productos por total facturado, con las unidades vendidas.
-- Brief M1 · P3 (qué productos explican la facturación).
-- =====================================================================
SELECT TOP 5
    id_producto,
    SUM(cantidad)                     AS unidades_vendidas,
    SUM(cantidad * precio_unitario)   AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;

-- =====================================================================
-- CONSULTA 3 · Clientes recurrentes
-- Clientes con más de un pedido, con su cantidad de pedidos y el total
-- gastado. HAVING filtra después de agrupar (WHERE no puede usar COUNT).
-- Brief M1 · P5 (qué clientes concentran las compras).
-- =====================================================================
SELECT
    id_cliente,
    COUNT(*)                          AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)   AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;

-- =====================================================================
-- CONSULTA 4 · Productos por encima / por debajo del promedio
-- Paso 1 (WITH): se calcula el total facturado de cada producto.
-- Paso 2 (subconsulta): se calcula el promedio de ESOS totales, es decir,
--   el promedio de facturación por producto, no el de las filas de ventas.
-- Paso 3 (CASE WHEN): se etiqueta cada producto según ese promedio.
-- Brief M1 · H1 (mix de producto: qué productos sostienen la facturación).
-- =====================================================================
WITH totales_por_producto AS (
    SELECT
        id_producto,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY id_producto
)
SELECT
    id_producto,
    total_facturado,
    (SELECT AVG(total_facturado) FROM totales_por_producto) AS promedio_por_producto,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM totales_por_producto)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END AS posicion_vs_promedio
FROM totales_por_producto
ORDER BY total_facturado DESC;

-- =====================================================================
-- HALLAZGOS
-- Datos analizados: 10 ventas de marzo 2024, facturación total $6.444,
-- ticket promedio $644,40.
--
-- 1. Alta concentración en un solo producto: el producto 1 factura $3.600,
--    el 55,9% del total. Junto con el producto 3 ($1.350) suman el 76,8%.
--    Son los únicos 2 de 6 productos por encima del promedio por producto
--    ($1.074); los otros 4 facturan entre $360 y $390 cada uno.
--
-- 2. Todos los clientes son recurrentes: los 5 hicieron 2 pedidos cada uno.
--    Pero el gasto es muy desigual: los clientes 1 y 5 suman $4.740
--    (73,6% del total) y ambos compraron el producto 1.
--
-- 3. Volumen no es lo mismo que valor: el producto 2 es el más vendido en
--    unidades (13 de 29, el 44,8%) y aun así aporta solo $364 (5,6% de la
--    facturación) y queda último en el top 5. Mirar unidades sin mirar
--    importes llevaría a conclusiones equivocadas.
-- =====================================================================
