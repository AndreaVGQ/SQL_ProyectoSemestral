--CREATE PACKAGE
CREATE OR REPLACE PACKAGE PKG_CONACYT
IS
    FUNCTION INSTITUCION_POST(F_RUN NUMBER) RETURN VARCHAR2;
    FUNCTION ESTADO_CIVIL(F_RUN NUMBER) RETURN VARCHAR2;
    FUNCTION PUEBLO_INDIGENA(F_RUN NUMBER) RETURN VARCHAR2;
    FUNCTION ZONA_EXTREMA(F_RUN NUMBER) RETURN VARCHAR2;
END;

--CUERPO PACKAGE
CREATE OR REPLACE PACKAGE BODY PKG_CONACYT
IS
    FUNCTION INSTITUCION_POST(F_RUN NUMBER) RETURN VARCHAR2
    IS
        V_INSTITUCION VARCHAR2(50);
    BEGIN
        SELECT INST.NOMBRE_UNIV
        INTO V_INSTITUCION
        FROM POSTULANTE POST
            JOIN ANTECEDENTE_POSTULACION ANTE ON POST.POS_ID = ANTE.FK_POS_AP
            JOIN INSTITUCION_ACADEMICA INST ON ANTE.FK_IA_AP = INST.IA_ID
        WHERE POST.RUN_POS = F_RUN;
        RETURN V_INSTITUCION;
    END INSTITUCION_POST;


    FUNCTION ESTADO_CIVIL(F_RUN NUMBER) RETURN VARCHAR2
    IS
        V_ESTADO VARCHAR2(50);
    BEGIN
        SELECT EST_CIVIL
        INTO V_ESTADO
        FROM POSTULANTE
        WHERE RUN_POS = F_RUN;
        RETURN V_ESTADO;
    END ESTADO_CIVIL;
    FUNCTION PUEBLO_INDIGENA(F_RUN NUMBER) RETURN VARCHAR2
    IS
        V_PUEBLO VARCHAR2(50);
    BEGIN
        SELECT CASE
                WHEN PUEBLO_INDIGENA IS NULL THEN 'Ninguno'
                ELSE PUEBLO_INDIGENA
               END
        INTO V_PUEBLO
        FROM POSTULANTE
        WHERE RUN_POS = F_RUN;
        RETURN V_PUEBLO;
    END PUEBLO_INDIGENA;

    FUNCTION ZONA_EXTREMA(F_RUN NUMBER) RETURN VARCHAR2
    IS
        V_ZONA VARCHAR2(50);
    BEGIN
        SELECT CASE
                WHEN REG.REG_ID = '15' THEN 'Arica y Parinacota'
                WHEN REG.REG_ID = '1' THEN 'Tarapac�'
                WHEN REG.REG_ID = '11' THEN 'Ays�n del Gral.Carlos Ib��ez del Campo'
                WHEN REG.REG_ID = '12' THEN 'Magallanes y de la Ant�rtica Chilena'
                ELSE 'Ninguna'
               END
        INTO V_ZONA
        FROM POSTULANTE POST
            JOIN DIRECCION DIRE ON POST.POS_ID = DIRE.FK_POS_DIR
            JOIN COMUNA COMU ON DIRE.FK_COMU_DIR = COMU.COMU_ID
            JOIN REGION REG ON COMU.FK_REG_COMU = REG.REG_ID
        WHERE POST.RUN_POS = F_RUN;
        RETURN V_ZONA;
    END ZONA_EXTREMA;
END PKG_CONACYT;

--DESARROLLO LAS 3 FUNCIONES ALMACENADAS
--FUNCION DE PUNTAJE POR INSITUCION
CREATE OR REPLACE FUNCTION PUNTAJE_ED(P_RUN IN POSTULANTE.RUN_POS%TYPE) RETURN NUMBER
IS
    V_PUNTAJE NUMBER;
BEGIN
    SELECT CASE
            WHEN INST.RANKING BETWEEN 1 AND 10 THEN 5
            WHEN INST.RANKING BETWEEN 11 AND 20 THEN 4
            WHEN INST.RANKING BETWEEN 21 AND 30 THEN 3
            WHEN INST.RANKING BETWEEN 31 AND 50 THEN 2
            WHEN INST.RANKING BETWEEN 51 AND 100 THEN 1
            ELSE 0
           END
    INTO V_PUNTAJE
    FROM POSTULANTE POST
        JOIN ANTECEDENTE_POSTULACION ANTE ON POST.POS_ID = ANTE.FK_POS_AP
        JOIN INSTITUCION_ACADEMICA INST ON ANTE.FK_IA_AP = INST.IA_ID
    WHERE POST.RUN_POS = P_RUN;
    RETURN V_PUNTAJE;
END;

--FUNCION PUNTAJE POR EDAD
CREATE OR REPLACE FUNCTION PUNTAJE_EDAD(P_RUN IN POSTULANTE.RUN_POS%TYPE) RETURN NUMBER
IS
    V_PUNTAJE NUMBER;
BEGIN
    SELECT CASE
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, FECHA_NAC)/12) < 30 THEN 5
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, FECHA_NAC)/12) BETWEEN 30 AND 40 THEN 3
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, FECHA_NAC)/12) > 40 THEN 1
           END
    INTO V_PUNTAJE
    FROM POSTULANTE
    WHERE RUN_POS = P_RUN;
    RETURN V_PUNTAJE;
END;

--FUNCION PUNTAJE POR TRAYECTORIA Y/O EXPERIENCIA LABORAL
CREATE OR REPLACE FUNCTION PUNTAJE_TRAY(P_RUN IN POSTULANTE.RUN_POS%TYPE) RETURN NUMBER
IS
    V_PUNTAJE NUMBER;
BEGIN
    SELECT CASE
            WHEN TRUNC(MONTHS_BETWEEN(EXPE.FECHA_TERMINO, EXPE.FECHA_INICIO)/12) > 5 THEN 5
            WHEN TRUNC(MONTHS_BETWEEN(EXPE.FECHA_TERMINO, EXPE.FECHA_INICIO)/12) = 5 THEN 4
            WHEN TRUNC(MONTHS_BETWEEN(EXPE.FECHA_TERMINO, EXPE.FECHA_INICIO)/12) = 4 THEN 3
            WHEN TRUNC(MONTHS_BETWEEN(EXPE.FECHA_TERMINO, EXPE.FECHA_INICIO)/12) = 3 THEN 2
            WHEN TRUNC(MONTHS_BETWEEN(EXPE.FECHA_TERMINO, EXPE.FECHA_INICIO)/12) = 2 THEN 1
            ELSE 0
           END
    INTO V_PUNTAJE
    FROM POSTULANTE POST
        JOIN EXPERIENCIA_LAB_ACAD EXPE ON POST.POS_ID = EXPE.FK_POS_ELA
    WHERE RUN_POS = P_RUN;
    RETURN V_PUNTAJE;
END;

--PROCEDIMIENTO GENERAL
CREATE OR REPLACE PROCEDURE RESULTADOS_POSTULANTES(ANIO NUMBER) 
IS
    CURSOR C_POSTULANTES IS SELECT RUN_POS RUN,
                                   RUN_POS || '-' || DV_POS RUT,
                                   PNOMBRE || ' ' || SNOMBRE || ' ' || APATERNO || ' ' || AMATERNO NOMBRE
                            FROM POSTULANTE;
    V_POSTULANTE VARCHAR2(50);
    V_RUN VARCHAR2(50);
    V_NOMBRE VARCHAR2(50);
    V_EDAD NUMBER;
    V_PTJ_EDAD NUMBER;
    V_ESTADO_CIVIL VARCHAR2(50);
    V_PTJ_EST_CIVIL NUMBER;
    V_PUEBLO_INDIGENA VARCHAR2(50);
    V_PTJ_PUEBLO_INDIGENA NUMBER;
    V_ZONA_EXTREMA VARCHAR2(50);
    V_PTJ_ZONA NUMBER;
    V_ANTEC_ACAB NUMBER;
    V_PTJ_ACAB NUMBER;
    V_EXP_LAB VARCHAR2(50);
    V_PTJ_EXP_LAB NUMBER;
    V_DOCENCIA VARCHAR2(50);
    V_PTJ_DOCENCIA NUMBER;
    V_OBJ VARCHAR2(50);
    V_PTJ_OBJ NUMBER;
    V_INTERES VARCHAR2(50);
    V_PTJ_INTERES NUMBER;
    V_RETRIBUCION VARCHAR2(50);
    V_PTJ_RETRIBUCION NUMBER;
    V_UNIVERSIDAD VARCHAR2(50);
    V_PTJ_UNIV NUMBER;
    V_TOTAL NUMBER;
BEGIN
    FOR POSTULANTES IN C_POSTULANTES LOOP
        IF POSTULANTES.RUN IS NOT NULL THEN
            SELECT POSTULANTES.RUT,
                   POSTULANTES.NOMBRE,
                   TRUNC(MONTHS_BETWEEN(SYSDATE, POST.FECHA_NAC)/12),                  
                   CASE
                       WHEN UPPER(POST.EST_CIVIL) = 'CASADO' THEN 5
                       WHEN UPPER(POST.EST_CIVIL) = 'CONVIVIENTE CIVIL' THEN 4
                       WHEN UPPER(POST.EST_CIVIL) = 'SOLTERO' THEN 3
                       WHEN UPPER(POST.EST_CIVIL) = 'DIVORCIADO' THEN 2
                       WHEN UPPER(POST.EST_CIVIL) = 'VIUDO' THEN 1
                   END,
                   CASE
                      WHEN PUEBLO_INDIGENA IS NOT NULL THEN 5
                      ELSE 0
                   END,
                   CASE
                      WHEN REG.REG_ID = 15 THEN 5
                      WHEN REG.REG_ID = 1 THEN 4
                      WHEN REG.REG_ID = 11 THEN 4
                      WHEN REG.REG_ID = 12 THEN 5
                      ELSE 0
                   END,
                   TGP.PROMEDIO_NOTAS,
                   CASE
                     WHEN TGP.PROMEDIO_NOTAS BETWEEN 6.6 AND 7.0 THEN 5
                     WHEN TGP.PROMEDIO_NOTAS BETWEEN 6.0 AND 6.5 THEN 4
                     WHEN TGP.PROMEDIO_NOTAS BETWEEN 5.5 AND 5.9 THEN 3
                     WHEN TGP.PROMEDIO_NOTAS BETWEEN 5.2 AND 5.4 THEN 2
                     WHEN TGP.PROMEDIO_NOTAS BETWEEN 5.0 AND 5.1 THEN 1
                     ELSE 0
                   END,
                   TRUNC(MONTHS_BETWEEN(ELA.FECHA_INICIO , ELA.FECHA_TERMINO )/12) || ' a�os',
                   EVA.DESCRIPCION,
                   CASE
                      WHEN EVA.EV_INV_ID = 3 THEN 5
                      WHEN EVA.EV_INV_ID = 2 THEN 3
                      WHEN EVA.EV_INV_ID = 1 THEN 2
                   END,
                   EVORP.EV_OBJETIVO,
                   CASE
                      WHEN UPPER(EVORP.EV_OBJETIVO) = 'EXCELENTE' THEN 5
                      WHEN UPPER(EVORP.EV_OBJETIVO) = 'MUY BUENO' THEN 4
                      WHEN UPPER(EVORP.EV_OBJETIVO) = 'BUENO' THEN 3
                      WHEN UPPER(EVORP.EV_OBJETIVO) = 'REGULAR' THEN 1
                   END,
                   EVORP.EV_RAZON,
                   CASE
                      WHEN UPPER(EVORP.EV_RAZON) = 'EXCELENTE' THEN 5
                      WHEN UPPER(EVORP.EV_RAZON) = 'MUY BUENO' THEN 4
                      WHEN UPPER(EVORP.EV_RAZON) = 'BUENO' THEN 3
                      WHEN UPPER(EVORP.EV_RAZON) = 'REGULAR' THEN 1
                   END,
                   EVORP.EV_RETORNO,
                   CASE
                      WHEN UPPER(EVORP.EV_RETORNO) = 'EXCELENTE' THEN 5
                      WHEN UPPER(EVORP.EV_RETORNO) = 'MUY BUENO' THEN 4
                      WHEN UPPER(EVORP.EV_RETORNO) = 'BUENO' THEN 3
                      WHEN UPPER(EVORP.EV_RETORNO) = 'REGULAR' THEN 1
                   END,
                   IA.NOMBRE_UNIV
            INTO V_RUN, V_NOMBRE, V_EDAD, V_PTJ_EST_CIVIL, V_PTJ_PUEBLO_INDIGENA, V_PTJ_ZONA, V_ANTEC_ACAB, V_PTJ_ACAB,
            V_EXP_LAB, V_DOCENCIA, V_PTJ_DOCENCIA, V_OBJ, V_PTJ_OBJ, V_INTERES, V_PTJ_INTERES, V_RETRIBUCION, V_PTJ_RETRIBUCION, V_UNIVERSIDAD
            FROM POSTULANTE POST 
                JOIN DIRECCION DIRE ON POST.POS_ID = DIRE.FK_POS_DIR
                JOIN COMUNA COMU ON DIRE.FK_COMU_DIR = COMU.COMU_ID
                JOIN REGION REG ON COMU.FK_REG_COMU = REG.REG_ID
                JOIN FORMACION_ACADEMICA FA ON POST.POS_ID = FA.FK_POS_FA
                JOIN TITULO_GRADO_POSTTITULO TGP ON FA.FA_ID = TGP.FK_FA_TGP
                JOIN EXPERIENCIA_LAB_ACAD ELA ON POST.POS_ID = ELA.FK_POS_ELA
                JOIN INVESTIGACION INV ON POST.POS_ID = INV.FK_POS_INV
                JOIN EV_INV EVA ON INV.FK_EV_INV = EVA.EV_INV_ID
                JOIN OBJETIVO_RAZON_POSTU ORP ON POST.POS_ID = ORP.FK_POS_ORP
                JOIN EV_OB_RA_PO EVORP ON ORP.FK_EV_ORP = EVORP.ORP_EV_ID
                JOIN ANTECEDENTE_POSTULACION ANP ON POST.POS_ID = ANP.FK_POS_AP
                JOIN INSTITUCION_ACADEMICA IA ON ANP.FK_IA_AP = IA.IA_ID
            WHERE POSTULANTES.RUN = RUN_POS;
            V_ESTADO_CIVIL := PKG_CONACYT.ESTADO_CIVIL(POSTULANTES.RUN);
            V_PTJ_EDAD := PUNTAJE_EDAD(POSTULANTES.RUN);
            V_PUEBLO_INDIGENA := PKG_CONACYT.PUEBLO_INDIGENA(POSTULANTES.RUN);
            V_ZONA_EXTREMA := PKG_CONACYT.ZONA_EXTREMA(POSTULANTES.RUN);
            V_PTJ_EXP_LAB := PUNTAJE_TRAY(POSTULANTES.RUN);
            V_PTJ_UNIV := PUNTAJE_ED(POSTULANTES.RUN);
            V_TOTAL := V_PTJ_EDAD + V_PTJ_EST_CIVIL + V_PTJ_PUEBLO_INDIGENA + V_PTJ_ZONA + V_PTJ_ACAB + V_PTJ_EXP_LAB + V_PTJ_DOCENCIA + V_PTJ_OBJ + V_PTJ_INTERES + V_PTJ_RETRIBUCION + V_PTJ_UNIV;
        END IF;
        INSERT INTO RESULTADOS VALUES(V_RUN, V_NOMBRE, V_EDAD, V_PTJ_EDAD, V_ESTADO_CIVIL, V_PTJ_EST_CIVIL, V_PUEBLO_INDIGENA, V_PTJ_PUEBLO_INDIGENA, V_ZONA_EXTREMA, V_PTJ_ZONA, V_ANTEC_ACAB, V_PTJ_ACAB,
            V_EXP_LAB, V_PTJ_EXP_LAB, V_DOCENCIA, V_PTJ_DOCENCIA, V_OBJ, V_PTJ_OBJ, V_INTERES, V_PTJ_INTERES, V_RETRIBUCION, V_PTJ_RETRIBUCION, V_UNIVERSIDAD, V_PTJ_UNIV, V_TOTAL);
    END LOOP;
END;

EXEC RESULTADOS_POSTULANTES(2021);