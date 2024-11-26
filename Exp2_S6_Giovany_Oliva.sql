-- Caso 1
CREATE TABLE RECAUDACION_BONOS_MEDICOS AS
SELECT 
    TO_CHAR(m.rut_med, '999,999,999-9') AS RUT_MEDICO,
    INITCAP(m.pnombre || ' ' || m.apaterno || ' ' || m.amaterno) AS NOMBRE_MEDICO,
    SUM(bc.costo) AS TOTAL_RECAUDADO,
    u.nombre AS UNIDAD_MEDICA
FROM BONO_CONSULTA bc
INNER JOIN MEDICO m ON bc.rut_med = m.rut_med
INNER JOIN UNIDAD_CONSULTA u ON m.uni_id = u.uni_id
INNER JOIN CARGO c ON m.car_id = c.car_id
WHERE c.car_id NOT IN (100, 500, 600)
  AND EXTRACT(YEAR FROM bc.fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY 
    m.rut_med, 
    m.pnombre, 
    m.apaterno, 
    m.amaterno, 
    u.nombre
ORDER BY 
    TOTAL_RECAUDADO ASC;

-- Caso 2 

SELECT 
    em.nombre AS ESPECIALIDAD_MEDICA,
    COUNT(bc.id_bono) AS CANTIDAD_BONOS,
    SUM(bc.costo) AS MONTO_PERDIDA,
    MIN(bc.fecha_bono) AS FECHA_BONO,
    CASE
        WHEN EXTRACT(YEAR FROM bc.fecha_bono) >= EXTRACT(YEAR FROM SYSDATE) - 1 THEN 'COBRABLE'
        ELSE 'INCOBRABLE'
    END AS ESTADO_DE_COBRO
FROM BONO_CONSULTA bc
INNER JOIN ESPECIALIDAD_MEDICA em ON bc.esp_id = em.esp_id
WHERE bc.id_bono NOT IN (
    SELECT p.id_bono
    FROM PAGOS p
)
GROUP BY em.nombre, 
         CASE
             WHEN EXTRACT(YEAR FROM bc.fecha_bono) >= EXTRACT(YEAR FROM SYSDATE) - 1 THEN 'COBRABLE'
             ELSE 'INCOBRABLE'
         END
ORDER BY 
    CANTIDAD_BONOS DESC,
    MONTO_PERDIDA DESC;


-- Caso 3

INSERT INTO CANT_BONOS_PACIENTES_ANNIO (ANNIO_CALCULO, PAC_RUN, DV_RUN, EDAD, CANTIDAD_BONOS, MONTO_TOTAL_BONOS, SISTEMA_SALUD)
SELECT 
    EXTRACT(YEAR FROM SYSDATE) AS ANNIO_CALCULO,
    p.pac_run, 
    p.dv_run, 
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM p.fecha_nacimiento) AS EDAD,
    COUNT(bc.id_bono) AS CANTIDAD_BONOS,
    NVL(SUM(bc.costo), 0) AS MONTO_TOTAL_BONOS, 
    ss.descripcion AS SISTEMA_SALUD
FROM PACIENTE p
LEFT JOIN BONO_CONSULTA bc ON p.pac_run = bc.pac_run
LEFT JOIN SALUD s ON p.sal_id = s.sal_id
LEFT JOIN SISTEMA_SALUD ss ON s.tipo_sal_id = ss.tipo_sal_id
WHERE 
    NVL(SUM(bc.costo), 0) < (
        SELECT ROUND(AVG(bc2.costo))
        FROM BONO_CONSULTA bc2
        WHERE EXTRACT(YEAR FROM bc2.fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
    )
GROUP BY 
    p.pac_run, 
    p.dv_run, 
    p.fecha_nacimiento, 
    ss.descripcion
ORDER BY 
    MONTO_TOTAL_BONOS DESC,
    EDAD DESC;