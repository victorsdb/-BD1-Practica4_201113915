BEGIN;
-- ======================================================================================
-- Eliminación de tablas
-- ======================================================================================
	DROP TABLE IF EXISTS departamento CASCADE;
	DROP TABLE IF EXISTS municipio CASCADE;
	DROP TABLE IF EXISTS estado_civil CASCADE;	
	DROP TABLE IF EXISTS nacimiento CASCADE;
	DROP TABLE IF EXISTS fallecimiento CASCADE;
	DROP TABLE IF EXISTS dpi CASCADE;
	DROP TABLE IF EXISTS matrimonio CASCADE;
	DROP TABLE IF EXISTS divorcio CASCADE;
	DROP TABLE IF EXISTS tipo_licencia CASCADE;
	DROP TABLE IF EXISTS licencia CASCADE;
	DROP TABLE IF EXISTS renovacion_licencia CASCADE;
	DROP TABLE IF EXISTS anulacion_licencia CASCADE;
	DROP SEQUENCE IF EXISTS partida_nacimiento CASCADE;
-- ======================================================================================
-- Creación de la tabla DEPARTAMENTO
-- ======================================================================================
	CREATE TABLE departamento (
		codigo_departamento  INTEGER NOT NULL,
		nombre_departamento  VARCHAR(15) NOT NULL
	);

	ALTER TABLE departamento 
		ADD CONSTRAINT departamento_pk PRIMARY KEY ( codigo_departamento );

	ALTER TABLE departamento 
		ADD CONSTRAINT departamento__un UNIQUE ( nombre_departamento );
-- ======================================================================================
-- Creación de la tabla MUNICIPIO
-- ======================================================================================
	CREATE TABLE municipio (
		codigo_municipio        INTEGER NOT NULL,
		nombre_municipio        VARCHAR(50) NOT NULL,
		departamento_municipio  INTEGER NOT NULL
	);

	ALTER TABLE municipio 
		ADD CONSTRAINT municipio_pk PRIMARY KEY ( codigo_municipio );

	ALTER TABLE municipio
		ADD CONSTRAINT municipio_departamento_fk FOREIGN KEY ( departamento_municipio )
			REFERENCES departamento ( codigo_departamento );
-- ======================================================================================
-- Creación de la tabla ESTADO_CIVIL
-- ======================================================================================			
	CREATE TABLE estado_civil (
		id_estado_civil      SERIAL NOT NULL,
		nombre_estado_civil  VARCHAR(50)
	);

	ALTER TABLE estado_civil ADD CONSTRAINT estado_civil_pk PRIMARY KEY ( id_estado_civil );
-- ======================================================================================
-- Creación de la tabla NACIMIENTO
-- ======================================================================================
	CREATE TABLE nacimiento (
		cui_persona             BIGINT NOT NULL,
		acta_nacimiento         INTEGER NOT NULL,
		cui_padre               BIGINT,
		cui_madre               BIGINT,
		primer_nombre_persona   VARCHAR(150) NOT NULL,
		segundo_nombre_persona  VARCHAR(150),
		tercer_nombre_persona   VARCHAR(150),
		primer_apellido_persona   VARCHAR(150) NOT NULL,
		segundo_apellido_persona  VARCHAR(150),
		fecha_nacimiento        TIMESTAMP NOT NULL,
		municipio_nacimiento    INTEGER NOT NULL,
		genero_persona          VARCHAR(1) NOT NULL,
		estado_civil			INTEGER NOT NULL
	);

	ALTER TABLE nacimiento 
		ADD CONSTRAINT nacimiento_pk PRIMARY KEY ( cui_persona );

	ALTER TABLE nacimiento 
		ADD CONSTRAINT nacimiento__un UNIQUE ( cui_persona );

	ALTER TABLE nacimiento
		ADD CONSTRAINT nacimiento_municipio_fk FOREIGN KEY ( municipio_nacimiento )
			REFERENCES municipio ( codigo_municipio );

	ALTER TABLE nacimiento
		ADD CONSTRAINT nacimiento_nacimiento_fk FOREIGN KEY ( cui_padre )
			REFERENCES nacimiento ( cui_persona );

	ALTER TABLE nacimiento
		ADD CONSTRAINT nacimiento_nacimiento_fkv2 FOREIGN KEY ( cui_madre )
			REFERENCES nacimiento ( cui_persona );
	
	ALTER TABLE nacimiento
		ADD CONSTRAINT nacimiento_estado_civil_fk FOREIGN KEY ( estado_civil )
			REFERENCES estado_civil ( id_estado_civil );
	
	ALTER TABLE nacimiento
    	ADD CONSTRAINT nacimiento_ck_1 
			CHECK ( genero_persona = 'M' OR genero_persona = 'F' );
-- ======================================================================================
-- Creación de la tabla FALLECIMIENTO
-- ======================================================================================
	CREATE TABLE fallecimiento (
		acta_defuncion       SERIAL NOT NULL,
		cui_fallecido        BIGINT NOT NULL,
		fecha_fallecimiento  TIMESTAMP NOT NULL,
		motivo				 VARCHAR(150) NOT NULL
	);

	ALTER TABLE fallecimiento 
		ADD CONSTRAINT fallecido_pk PRIMARY KEY ( acta_defuncion );

	ALTER TABLE fallecimiento 
		ADD CONSTRAINT fallecimiento__un UNIQUE ( cui_fallecido );

	ALTER TABLE fallecimiento
		ADD CONSTRAINT fallecimiento_nacimiento_fk FOREIGN KEY ( cui_fallecido )
			REFERENCES nacimiento ( cui_persona );
-- ======================================================================================
-- Creación de la tabla DPI
-- ======================================================================================
	CREATE TABLE dpi (
		cui                   BIGINT NOT NULL,
		fecha_emision         TIMESTAMP NOT NULL,
		municipio_residencia  INTEGER NOT NULL
	);

	ALTER TABLE dpi 
		ADD CONSTRAINT dpi_pk PRIMARY KEY ( cui, fecha_emision );

	ALTER TABLE dpi
		ADD CONSTRAINT dpi_municipio_fk FOREIGN KEY ( municipio_residencia )
			REFERENCES municipio ( codigo_municipio );

	ALTER TABLE dpi
		ADD CONSTRAINT dpi_nacimiento_fk FOREIGN KEY ( cui )
			REFERENCES nacimiento ( cui_persona );
-- ======================================================================================
-- Creación de la tabla MATRIMONIO
-- ======================================================================================
	CREATE TABLE matrimonio (
		id_acta_matrimonio  SERIAL NOT NULL,
		cui_hombre          BIGINT NOT NULL,
		cui_mujer           BIGINT NOT NULL,
		fecha_matrimonio    TIMESTAMP NOT NULL
	);

	ALTER TABLE matrimonio 
		ADD CONSTRAINT matrimonio_pk PRIMARY KEY ( id_acta_matrimonio );

	ALTER TABLE matrimonio
		ADD CONSTRAINT matrimonio_nacimiento_fk FOREIGN KEY ( cui_hombre )
			REFERENCES nacimiento ( cui_persona );

	ALTER TABLE matrimonio
		ADD CONSTRAINT matrimonio_nacimiento_fkv2 FOREIGN KEY ( cui_mujer )
			REFERENCES nacimiento ( cui_persona );
-- ======================================================================================
-- Creación de la tabla DIVORCIO
-- ======================================================================================
	CREATE TABLE divorcio (
		id_acta_divorcio  SERIAL NOT NULL,
		acta_matrimonio   INTEGER NOT NULL,
		fecha_divorcio    TIMESTAMP NOT NULL
	);

	ALTER TABLE divorcio 
		ADD CONSTRAINT divorcio_pk PRIMARY KEY ( id_acta_divorcio );

	ALTER TABLE divorcio 
		ADD CONSTRAINT divorcio__un UNIQUE ( acta_matrimonio );

	ALTER TABLE divorcio
		ADD CONSTRAINT divorcio_matrimonio_fk FOREIGN KEY ( acta_matrimonio )
			REFERENCES matrimonio ( id_acta_matrimonio );
-- ======================================================================================
-- Creación de la tabla TIPO_LICENCIA
-- ======================================================================================
	CREATE TABLE tipo_licencia (
		id_tipo_licencia  VARCHAR(1) NOT NULL,
		descripción       VARCHAR(500) NOT NULL
	);

	ALTER TABLE tipo_licencia 
		ADD CONSTRAINT tipo_licencia_pk PRIMARY KEY ( id_tipo_licencia );
-- ======================================================================================
-- Creación de la tabla LICENCIA
-- ======================================================================================
	CREATE TABLE licencia (
		no_licencia    		SERIAL NOT NULL,
		cui_persona    		BIGINT NOT NULL,
		fecha_emision  		TIMESTAMP NOT NULL,
		fecha_cambio		TIMESTAMP NOT NULL,
		fecha_vencimiento	TIMESTAMP NOT NULL,
		tipo_original  		VARCHAR(1) NOT NULL,
		tipo_actual  		VARCHAR(1) NOT NULL
	);

	ALTER TABLE licencia 
		ADD CONSTRAINT licencia_pk PRIMARY KEY ( no_licencia );

	ALTER TABLE licencia 
		ADD CONSTRAINT licencia__un UNIQUE ( cui_persona, tipo_original );

	ALTER TABLE licencia
		ADD CONSTRAINT licencia_nacimiento_fk FOREIGN KEY ( cui_persona )
			REFERENCES nacimiento ( cui_persona );

	ALTER TABLE licencia
		ADD CONSTRAINT licencia_tipo_licencia_fk1 FOREIGN KEY ( tipo_original )
			REFERENCES tipo_licencia ( id_tipo_licencia );
	
	ALTER TABLE licencia
		ADD CONSTRAINT licencia_tipo_licencia_fk2 FOREIGN KEY ( tipo_actual )
			REFERENCES tipo_licencia ( id_tipo_licencia );
-- ======================================================================================
-- Creación de la tabla RENOVACION_LICENCIA
-- ======================================================================================
	CREATE TABLE renovacion_licencia (
		no_licencia       INTEGER NOT NULL,
		fecha_renovacion  TIMESTAMP NOT NULL,
		tipo_licencia     VARCHAR(1) NOT NULL,
		anios_renovacion  INTEGER NOT NULL
	);

	ALTER TABLE renovacion_licencia 
		ADD CONSTRAINT renovacion_licencia_pk PRIMARY KEY ( no_licencia, fecha_renovacion );

	ALTER TABLE renovacion_licencia
		ADD CONSTRAINT renovacion_licencia_fk FOREIGN KEY ( no_licencia )
			REFERENCES licencia ( no_licencia );

	ALTER TABLE renovacion_licencia
		ADD CONSTRAINT renovacion_tipo_licencia_fk FOREIGN KEY ( tipo_licencia )
			REFERENCES tipo_licencia ( id_tipo_licencia );
-- ======================================================================================
-- Creación de la tabla ANULACION_LICENCIA
-- ======================================================================================
	CREATE TABLE anulacion_licencia (
		no_licencia      INTEGER NOT NULL,
		fecha_anulacion  TIMESTAMP NOT NULL,
		fecha_fin		 TIMESTAMP NOT NULL,
		motivo           VARCHAR(200) NOT NULL
	);

	ALTER TABLE anulacion_licencia 
		ADD CONSTRAINT anulacion_licencia_pk PRIMARY KEY ( no_licencia );

	ALTER TABLE anulacion_licencia
		ADD CONSTRAINT anulacion_licencia_licencia_fk FOREIGN KEY ( no_licencia )
			REFERENCES licencia ( no_licencia );
-- ======================================================================================
-- Creación de la secuencia PARTIDA_NACIMIENTO
-- ======================================================================================
	CREATE SEQUENCE partida_nacimiento
		INCREMENT BY 1
		MINVALUE 111111119
		MAXVALUE 999999999;
-- ======================================================================================
COMMIT;