BEGIN;
-- ======================================================================================
-- Creación de procedimiento MOSTRAR_MENSAJE
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE mostrar_mensaje( codigo INTEGER, mensaje VARCHAR(1000) )
	LANGUAGE plpgsql 
	AS $$
	BEGIN
		RAISE INFO '%',(SELECT to_json(t) as respuesta FROM ( SELECT key as estado, value as mensaje FROM json_each(('{"'||codigo||'":"'||mensaje||'"}')::json))t);
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento REGISTRAR_NACIMIENTO
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE registrar_nacimiento(
		padre BIGINT, madre BIGINT, p_name VARCHAR(150), s_name VARCHAR(150), t_name VARCHAR(150), fecha TIMESTAMP, id_mun INTEGER, genero VARCHAR(1)
	)
	LANGUAGE plpgsql 
	AS $$
	DECLARE
		partida INTEGER := 0;
		acta INTEGER := 0;
		cui BIGINT := 0;
		mun INTEGER := 0;
		p_apellido VARCHAR(150) := null;
		s_apellido VARCHAR(150) := null;
		fecha_bool BOOLEAN := false;
		p_name_bool BOOLEAN := false;
		p_apellido_bool BOOLEAN := false;
		caracter_invalido BOOLEAN := false;
	BEGIN
		caracter_invalido := concat_ws(' ', p_name, s_name, t_name) NOT SIMILAR TO '[A-Za-zÑñÁáÉéÍíÓóÚú ]+' ;
		--GENERANDO CUI
		partida := nextval('partida_nacimiento');
		cui := partida::BIGINT * 10000::BIGINT + id_mun::BIGINT;

		--VERIFICANDO APELLIDOS
		IF padre IS NOT NULL and madre IS NOT NULL
			THEN -- 2 PAPAS
				p_apellido := ( SELECT primer_apellido_persona FROM nacimiento WHERE cui_persona = padre AND genero_persona = 'M' AND (fecha - fecha_nacimiento) >= '18 year'::interval );
				s_apellido := ( SELECT primer_apellido_persona FROM nacimiento WHERE cui_persona = madre AND genero_persona = 'F' AND (fecha - fecha_nacimiento) >= '18 year'::interval );

				IF p_apellido IS NULL
				THEN CALL mostrar_mensaje(404, 'No se pudo encontrar padre mayor de 18 años con CUI: '||padre||'.');
				END IF;

				IF s_apellido IS NULL 
				THEN CALL mostrar_mensaje(404, 'No se pudo encontrar madre mayor de 18 años con CUI: '||madre||'.');
				END IF;

				IF p_apellido IS NULL OR s_apellido IS NULL 
				THEN p_apellido_bool:=false;
				ELSE p_apellido_bool:=true;
				END IF;

		ELSIF padre IS NOT NULL and madre IS NULL
			THEN -- PAPA
				p_apellido := ( SELECT primer_apellido_persona FROM nacimiento WHERE cui_persona = padre AND genero_persona = 'M' AND (fecha - fecha_nacimiento) >= '18 year'::interval );
				s_apellido := NULL;

				IF p_apellido IS NULL
				THEN p_apellido_bool:=false; CALL mostrar_mensaje(404, 'No se pudo encontrar padre mayor de 18 años con CUI: '||padre||'.');
				ELSE p_apellido_bool:=true;
				END IF;

		ELSIF padre IS NULL and madre IS NOT NULL
			THEN -- MAMA
				p_apellido := ( SELECT primer_apellido_persona FROM nacimiento WHERE cui_persona = madre AND genero_persona = 'F' AND (fecha - fecha_nacimiento) >= '18 year'::interval );
				s_apellido := NULL;

				IF p_apellido IS NULL 
				THEN p_apellido_bool:=false; CALL mostrar_mensaje(404, 'No se pudo encontrar madre mayor de 18 años con CUI: '||madre||'.');
				ELSE p_apellido_bool:=true;	
				END IF;
		ELSE --SIN PADRES
				CALL mostrar_mensaje(500, 'Error con el primer apellido: La persona debe tener por lo menos un apellido.');
		END IF;

		--VERIFICANDO EXISTENCIA DEL MUNICIPIO
		mun = (SELECT codigo_municipio FROM municipio WHERE codigo_municipio = id_mun);
		IF mun IS NULL THEN mun = 0;
			CALL mostrar_mensaje(404, 'No se pudo encontrar el municipio con codigo: '||id_mun||'.'); 
		END IF;

		--VERIFICANDO FECHA DE NACIMIENTO
		IF	fecha<=NOW() THEN fecha_bool := true;
		ELSE fecha_bool := false; CALL mostrar_mensaje(500, 'Error con la fecha nacimiento: No es permitido registrar nacimiento con fecha posterior a la actual');
		END IF;

		--VERIFICANDO PRIMER NOMBRE
		IF  p_name IS NOT NULL THEN p_name_bool := true;
		ELSE p_name_bool := false; CALL mostrar_mensaje(500, 'Error con el primer nombre: La persona debe tener por lo menos un nombre.');
		END IF;
		
		IF caracter_invalido
		THEN CALL mostrar_mensaje(500, 'Error existen caracteres invalidos en algun nombre.');
		END IF;


		--RAISE '%', caracter_invalido;
		--REGISTRANDO NACIMIENTO
		IF( fecha_bool AND p_name_bool AND p_apellido_bool AND mun <> 0) AND NOT caracter_invalido
			THEN INSERT INTO nacimiento VALUES(cui, partida, padre, madre, p_name, s_name, t_name, p_apellido, s_apellido, fecha, id_mun, genero, 1);
				CALL mostrar_mensaje(200, 'Operación completada.'); 
			ELSE CALL mostrar_mensaje(500, 'Error al registrar nacimiento: El nacimiento no cumple los requisitos.');
		END IF;
	END; 
	$$;
-- ======================================================================================
-- Creación de procedimiento REGISTRAR_FALLECIMIENTO
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE registrar_fallecimiento (
		fallecido BIGINT, fecha_fallecido TIMESTAMP, motivo VARCHAR(150)
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		nac_bool BOOLEAN := false;
		fall_bool BOOLEAN := false;
		fecha_bool BOOLEAN := false;
	BEGIN
		--VERIFICANDO NACIMIENTO
		IF ( SELECT cui_persona FROM nacimiento WHERE cui_persona = fallecido) IS NULL
			THEN CALL mostrar_mensaje(404, 'No se pudo encontrar persona con CUI: '||fallecido||'.');
			ELSE nac_bool := true;
		END IF;
		--VERIFICANDO FALLECIMIENTO
		IF ( SELECT cui_fallecido FROM fallecimiento WHERE cui_fallecido = fallecido) IS NOT NULL
			THEN CALL mostrar_mensaje(404, 'Ya fallecio persona con CUI: '||fallecido||'.');
			ELSE fall_bool := true;
		END IF;

		--VERIFICANDO FECHA
		IF fecha_fallecido > ( SELECT fecha_nacimiento FROM nacimiento WHERE cui_persona = fallecido) AND fecha_fallecido <= NOW()
			THEN fecha_bool := true;
			ELSE CALL mostrar_mensaje(500, 'Fecha invalida.');
		END IF;

		IF nac_bool AND fall_bool AND fecha_bool
			THEN INSERT INTO fallecimiento(cui_fallecido, fecha_fallecimiento, motivo) VALUES(fallecido, fecha_fallecido, motivo);

			UPDATE nacimiento SET estado_civil = 4
				WHERE cui_persona = (
					SELECT cui_persona
						FROM matrimonio
						INNER JOIN nacimiento ON cui_persona = cui_mujer OR cui_persona = cui_hombre
							WHERE estado_civil = 2 AND (cui_mujer = 1111111130202 OR cui_hombre = 1111111130202) AND cui_persona <> 1111111130202
				);
			CALL mostrar_mensaje(200, 'Operación completada.');
		ELSE CALL mostrar_mensaje(500, 'Error al registrar fallecimiento: El fallecimiento no cumple los requisitos.');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento REGISTRAR_MATRIMONIO
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE registrar_matrimonio (
		hombre BIGINT, mujer BIGINT, fecha_matrimonio TIMESTAMP
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		mujer_bool BOOLEAN := false;
		hombre_bool BOOLEAN := false;
	BEGIN
		IF  ( SELECT primer_apellido_persona FROM nacimiento WHERE cui_persona = hombre AND genero_persona = 'M' AND (fecha_matrimonio - fecha_nacimiento) >= '18 year'::interval ) IS NULL 
			OR (SELECT cui_fallecido FROM fallecimiento WHERE cui_fallecido = hombre) IS NOT NULL
		THEN CALL mostrar_mensaje(404, 'No se pudo encontrar hombre vivo mayor de 18 años con CUI: '||hombre||'.');
		ELSE hombre_bool := true;
		END IF;
		IF ( SELECT primer_apellido_persona FROM nacimiento WHERE cui_persona = mujer AND genero_persona = 'F' AND (fecha_matrimonio - fecha_nacimiento) >= '18 year'::interval ) IS NULL
			OR (SELECT cui_fallecido FROM fallecimiento WHERE cui_fallecido = mujer) IS NOT NULL
		THEN CALL mostrar_mensaje(404, 'No se pudo encontrar mujer viva mayor de 18 años con CUI: '||mujer||'.');
		ELSE mujer_bool := true;
		END IF;


		-- VERIFICAR CASAMIENTO HOMBRE
		IF (SELECT cui_persona FROM nacimiento WHERE estado_civil = 2 AND cui_persona = hombre ) IS NOT NULL AND hombre_bool = true
			THEN mujer_bool := false; CALL mostrar_mensaje(500, 'Ya se encuentra casado el caballero con CUI: '||hombre);
		END IF;
		-- VERIFICAR CASAMIENTO MUJER
		IF (SELECT cui_persona FROM nacimiento WHERE estado_civil = 2 AND cui_persona = mujer ) IS NOT NULL AND mujer_bool = true
			THEN mujer_bool := false; CALL mostrar_mensaje(500, 'Ya se encuentra casada la señorita con CUI: '||mujer);
		END IF;

		IF mujer_bool AND hombre_bool
			THEN INSERT INTO matrimonio( cui_hombre, cui_mujer, fecha_matrimonio) VALUES (hombre, mujer, fecha_matrimonio);

			UPDATE nacimiento 
				SET estado_civil = 2 
					WHERE cui_persona = hombre OR cui_persona = mujer;

			CALL mostrar_mensaje(200, 'Operación completada.');
		ELSE CALL mostrar_mensaje(500, 'Error al registrar matrimonio: El matrimonio no cumple los requisitos.');
		END IF;

	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento REGISTRAR_DIVORCIO
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE registrar_divorcio (
		id_matrimonio INTEGER, fecha_divorcio TIMESTAMP
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		hombre BIGINT := 0;
		mujer BIGINT := 0;
	BEGIN
		hombre := ( SELECT cui_persona FROM matrimonio INNER JOIN nacimiento ON cui_persona = cui_hombre WHERE id_acta_matrimonio = id_matrimonio AND estado_civil = 2 );
		mujer := ( SELECT cui_persona FROM matrimonio INNER JOIN nacimiento ON cui_persona = cui_mujer WHERE id_acta_matrimonio = id_matrimonio AND estado_civil = 2 );

		IF hombre IS NULL
		THEN CALL mostrar_mensaje(404, 'No se pudo encontrar hombre casado.');
		END IF;

		IF mujer IS NULL 
		THEN CALL mostrar_mensaje(404, 'No se pudo encontrar mujer casada.');
		END IF;

		IF hombre IS NOT NULL AND mujer IS NOT NULL
			THEN INSERT INTO divorcio (acta_matrimonio, fecha_divorcio) VALUES(id_matrimonio, fecha_divorcio);

				UPDATE nacimiento 
					SET estado_civil = 3 
						WHERE cui_persona = hombre OR cui_persona = mujer;

				CALL mostrar_mensaje(200, 'Operación completada.'); 
			ELSE CALL mostrar_mensaje(500, 'Error al registrar divorcio: El divorcio no cumple los requisitos.');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento REGISTRAR_LICENCIA
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE registrar_licencia (
		cui_licencia BIGINT, fecha TIMESTAMP, tipo VARCHAR(1)
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		fecha_bool BOOLEAN := false;
		cui_bool BOOLEAN := false;
		exist BOOLEAN := false;
	BEGIN
		cui_bool := 
		(
			SELECT cui_persona 
				FROM nacimiento 
					WHERE cui_persona = cui_licencia AND (fecha - fecha_nacimiento) >= '16 year'::interval
		) IS NOT NULL;
		
		IF cui_bool
			THEN 
				fecha_bool := fecha > NOW();

				CASE tipo
					WHEN 'C' THEN
						exist := (SELECT no_licencia FROM licencia WHERE (tipo_original = 'M' OR tipo_original = 'C') AND cui_persona = cui_licencia) IS NOT NULL;
					WHEN 'M' THEN
						exist := (SELECT no_licencia FROM licencia WHERE (tipo_original = 'M' OR tipo_original = 'C') AND cui_persona = cui_licencia) IS NOT NULL;
					WHEN 'E' THEN
						exist := (SELECT no_licencia FROM licencia WHERE tipo_original = 'E' AND cui_persona = cui_licencia) IS NOT NULL;
					ELSE CALL mostrar_mensaje(404, 'Tipo de primer licencia no valida.');
				END CASE;

				IF fecha_bool
					THEN CALL mostrar_mensaje(404, 'Fecha posterior a la actual.');
				END IF;

				IF exist
					THEN CALL mostrar_mensaje(404, 'Ya cuenta con una licencia.');
				END IF;
				
			ELSE CALL mostrar_mensaje(404, 'No existe persona mayor a 16 años con CUI: '||cui_licencia);
		END IF;
		
		IF NOT fecha_bool AND NOT exist AND cui_bool
			THEN INSERT INTO licencia(cui_persona, fecha_emision, fecha_cambio, fecha_vencimiento, tipo_original, tipo_actual) VALUES (cui_licencia, fecha, fecha, fecha + '1 year'::interval,  tipo, tipo);
				CALL mostrar_mensaje(200, 'Operación completada.'); 
			ELSE CALL mostrar_mensaje(500, 'Error al registrar licencia: La licencia no cumple los requisitos.');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento RENOVAR_LICENCIA
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE renovar_licencia (
		no_lic INTEGER, fecha_ren TIMESTAMP, tipo_nuevo VARCHAR(1), tiempo INTEGER
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		tipo_act VARCHAR(1) := NULL;
		fecha_max TIMESTAMP := NULL;
		fecha_ven TIMESTAMP := NULL;
		fecha_cam TIMESTAMP := NULL;
		
		edad INTERVAL := NULL;
		
		error_tipo BOOLEAN := false;
		error_edad BOOLEAN := false;
		error_intervalo BOOLEAN := false;
		error_anulada BOOLEAN := false;
		exist BOOLEAN := false;
	BEGIN
		exist := ( SELECT no_licencia FROM licencia WHERE no_licencia = no_lic ) IS NOT NULL;
		
		IF exist
			THEN
				fecha_ven := ( SELECT fecha_vencimiento FROM licencia WHERE no_licencia = no_lic );
				fecha_cam := ( SELECT fecha_cambio FROM licencia WHERE no_licencia = no_lic );
				tipo_act := ( SELECT tipo_actual FROM licencia WHERE no_licencia = no_lic );
				edad := ( SELECT age( fecha_ren, fecha_nacimiento) FROM licencia INNER JOIN nacimiento USING (cui_persona) WHERE no_licencia = no_lic);
				fecha_max := ( SELECT MAX(fecha_renovacion) FROM renovacion_licencia WHERE no_licencia = no_lic );
				error_anulada := (SELECT no_licencia FROM anulacion_licencia WHERE fecha_ren >= fecha_anulacion AND fecha_ren <= fecha_fin AND no_licencia = no_lic ) IS NOT NULL;
				IF fecha_max = NULL THEN fecha_max := ( SELECT fecha_emisión FROM licencia WHERE no_licencia = no_lic ); END IF;
				
				CASE tipo_act
					WHEN 'E' THEN 
						CASE tipo_nuevo
							WHEN 'E' THEN 
							ELSE error_tipo = true; -- error tipo 
						END CASE;
					WHEN 'M' THEN 
						CASE tipo_nuevo
							WHEN 'M' THEN --sin error
							WHEN 'C' THEN --sin error
							ELSE error_tipo = true; -- error tipo
						END CASE;
					WHEN 'C' THEN
						CASE tipo_nuevo
							WHEN 'C' THEN --sin error
							WHEN 'B' THEN 
								IF edad < '23 year'::interval
									THEN error_edad := true;
								END IF;

								IF(fecha_ren - fecha_cam) < '2 year'::interval
									THEN error_intervalo := true;
								END IF;
							WHEN 'A' THEN
								IF edad < '25 year'::interval
									THEN error_edad := true;
								END IF;

								IF(fecha_ren - fecha_cam) <= '3 year'::interval
									THEN error_intervalo := true;
								END IF;
							ELSE error_tipo = true; -- error tipo
						END CASE;
					WHEN 'B' THEN 
						CASE tipo_nuevo
							WHEN 'B' THEN --sin error
							WHEN 'A' THEN
								IF edad < '25 year'::interval
									THEN error_edad := true;
								END IF;

								IF(fecha_ren - fecha_cam) <= '3 year'::interval
									THEN error_intervalo := true;
								END IF;
							ELSE error_tipo = true; -- error tipo
						END CASE;
					WHEN 'A' THEN
						CASE tipo_nuevo
							WHEN 'A' THEN 
							ELSE error_tipo = true;-- error tipo
						END CASE;
					ELSE
				END CASE;
			ELSE CALL mostrar_mensaje(404, 'No existe la licencia No.: '||no_lic||'.'); 
		END IF;
		
		IF error_tipo
			THEN CALL mostrar_mensaje(404, 'No puede actualizar a este tipo de licencia.'); 
		END IF;
		
		IF error_edad
			THEN CALL mostrar_mensaje(404, 'No cumple con la edad necesaria para el tipo de licencia.'); 
		END IF;
		
		IF error_intervalo
			THEN CALL mostrar_mensaje(404, 'No cumple con el tiempo necesario para la actualización de tipo.'); 
		END IF;
		
		IF fecha_ren < fecha_max
			THEN CALL mostrar_mensaje(404, 'Fecha de renovación menor a ultima fecha de renovación: '||fecha_max); 
		END IF;
		
		IF error_anulada
			THEN CALL mostrar_mensaje(404, 'No se puede renovar, ya que esta anulada la licencia No.: '|| no_lic); 
		END IF;
		
		IF NOT error_tipo AND NOT error_edad AND NOT error_intervalo AND exist AND fecha_ren > fecha_cam AND NOT error_anulada
			THEN
				INSERT INTO renovacion_licencia VALUES(no_lic, fecha_ren, tipo_nuevo, tiempo);
				
				IF (fecha_ven < fecha_ren)
					THEN UPDATE licencia SET fecha_vencimiento = fecha_ven + (tiempo||' year')::interval WHERE no_licencia = no_lic;
					ELSE UPDATE licencia SET fecha_vencimiento = fecha_ren + (tiempo||' year')::interval WHERE no_licencia = no_lic;
				END IF;
				
				IF tipo_act <> tipo_nuevo
					THEN UPDATE licencia SET tipo_actual = tipo_nuevo, fecha_cambio = fecha_ren  WHERE no_licencia = no_lic;
				END IF;
				CALL mostrar_mensaje(200, 'Operación completada.'); 
			ELSE CALL mostrar_mensaje(500, 'Error al renovar licencia: La renovación de licencia no cumple los requisitos.');
		END IF;
		
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento ANULAR_LICENCIA
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE anular_licencia (
		no_lic INTEGER, fecha_anu TIMESTAMP, mot VARCHAR(200)
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		exist BOOLEAN := false;
		anulada BOOLEAN := false;
		error_fecha BOOLEAN := false;
		
		fecha_inicio TIMESTAMP := NULL;
		fecha_fin TIMESTAMP := NULL;
		fecha_reg TIMESTAMP := NULL;
		
	BEGIN
		exist := (SELECT no_licencia FROM licencia WHERE no_licencia = no_lic) IS NOT NULL;
		
		IF exist
			THEN
				fecha_reg := (SELECT fecha_emision FROM licencia WHERE no_licencia = no_lic);
				anulada := (SELECT no_licencia FROM anulacion_licencia WHERE no_licencia = no_lic) IS NOT NULL;
				IF anulada
					THEN
						fecha_inicio := (SELECT fecha_anulación FROM anulacion_licencia WHERE no_licencia = no_lic);
						fecha_fin := (SELECT fecha_fin FROM anulacion_licencia WHERE no_licencia = no_lic);
						
						IF fecha_anu < fecha_fin AND fecha_anu > fecha_inicio AND fecha_anu > fecha_reg AND fecha_anu <= now()
							THEN 
								UPDATE anulacion_licencia
									SET fecha_fin = fecha_anu + '2 year'::interval,
										motivo = mot
								WHERE no_licencia = no_lic;
						ELSE error_fecha := true;
							CALL mostrar_mensaje(404, 'Fecha no valida para la anulación.');
						END IF;
						
					ELSE
						INSERT INTO anulacion_licencia VALUES (no_lic, fecha_anulacion, fecha_anulacion + '2 year'::interval, motivo);
					END IF;
			ELSE  CALL mostrar_mensaje(404, 'No existe la licencia No.: '||no_lic||'.');
		END IF;
		
		IF NOT error_fecha AND exist
			THEN CALL mostrar_mensaje(200, 'Operación completada.'); 
			ELSE CALL mostrar_mensaje(500, 'Error al anular licencia: La anulación de licencia no cumple los requisitos.');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento GENERAR_DPI
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE generar_dpi (
		cui_dpi BIGINT, fecha TIMESTAMP, residencia INTEGER
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		fecha_bool BOOLEAN := false;
		persona_bool BOOLEAN := false;
		mun_bool BOOLEAN := false;
		exist BOOLEAN := false;
	BEGIN
		--VERIFICANDO PERSONA
			persona_bool := (SELECT cui_persona FROM nacimiento WHERE cui_persona = cui_dpi) IS NOT NULL;
		--VERIFICANDO FECHA VALIDA Y MUNICIPIO
			IF persona_bool 
				THEN
					fecha_bool := ( SELECT cui_persona FROM nacimiento WHERE cui_persona = cui_dpi AND (fecha - fecha_nacimiento) >= '18 year'::interval) IS NOT NULL;
					mun_bool := ( SELECT codigo_municipio FROM municipio WHERE codigo_municipio = residencia) IS NOT NULL;

					IF NOT fecha_bool
						THEN CALL mostrar_mensaje(404, 'No se encontro persona con por lo menos 18 años de edad con CUI: '||cui_dpi||'.'); 
					END IF;

					IF NOT mun_bool
						THEN CALL mostrar_mensaje(404, 'No se encontro municipio con código: '||residencia||'.'); 
					END IF;
			ELSE CALL mostrar_mensaje(404, 'No se encontro persona con CUI: '||cui_dpi||'.'); 
			END IF;

			--YA EXISTE DPI CON ESA FECHA
			exist := (SELECT cui FROM dpi WHERE cui = cui_dpi AND fecha_emision = fecha) IS NULL;
					IF NOT exist
						THEN CALL mostrar_mensaje(404, 'Ya existe un DPI generado el : '||TO_CHAR(fecha,'yyyy-mm-dd')||'.'); 
					END IF;
			--GENERANDO DPI
			IF( persona_bool AND fecha_bool AND mun_bool AND exist )
				THEN INSERT INTO dpi VALUES(cui_dpi, fecha, residencia);
					CALL mostrar_mensaje(200, 'Operación completada.'); 
				ELSE CALL mostrar_mensaje(500, 'Error al registrar dpi: El registro de DPI no cumple los requisitos.');
			END IF;

	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_ACTA_NACIMIENTO
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_acta_nacimiento (
		cui BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta :=( SELECT cui_persona FROM nacimiento WHERE cui_persona = cui );

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontro persona con CUI: '||cui||'.');
			ELSE
				EXECUTE FORMAT(' COPY (
								  SELECT row_to_json(t)
									FROM (
											SELECT h.acta_nacimiento noacta,
												h.cui_persona cui,
												concat_ws('' '', h.primer_apellido_persona, h.segundo_apellido_persona) apellidos,				
												concat_ws('' '', h.primer_nombre_persona, h.segundo_nombre_persona, h.tercer_nombre_persona ) nombres,
												h.cui_padre dpipadre,
												concat_ws('' '', p.primer_nombre_persona, p.segundo_nombre_persona, p.tercer_nombre_persona ) nombrepadre,
												concat_ws('' '', p.primer_apellido_persona, p.segundo_apellido_persona) apellidopadre,
												h.cui_madre dpimadre,
												concat_ws('' '', m.primer_nombre_persona, m.segundo_nombre_persona, m.tercer_nombre_persona ) nombremadre,
												concat_ws('' '', m.primer_apellido_persona, m.segundo_apellido_persona) apellidosmadre,
												TO_CHAR(h.fecha_nacimiento, ''dd-mm-yyyy'')fechanac,
												d.nombre_departamento departamento,
												mn.nombre_municipio municipio,
												CASE h.genero_persona 
													WHEN ''M'' THEN ''MASCULINO'' 
													WHEN ''F'' THEN ''FEMENINO'' 
													ELSE null
												END genero
												FROM nacimiento h
												LEFT JOIN nacimiento p ON h.cui_padre = p.cui_persona
												LEFT JOIN nacimiento m ON h.cui_madre = m.cui_persona
												INNER JOIN municipio mn ON h.municipio_nacimiento = mn.codigo_municipio
												INNER JOIN departamento d ON mn.departamento_municipio = d.codigo_departamento
													WHERE h.cui_persona = %L
									)t

							  ) TO  %L ',
							   cui, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\acta_nacimiento_'||cui||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo acta_nacimiento_'||cui||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_DPI
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_dpi (

		cui_dpi BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta :=( 
			SELECT cui_persona cui
					FROM nacimiento
					INNER JOIN dpi ON cui = cui_persona
						WHERE fecha_emision = ( SELECT MAX(fecha_emision) FROM dpi WHERE cui = cui_dpi )
		);

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontro DPI con CUI: '||cui_dpi||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
								  SELECT row_to_json(t)
									FROM (
										SELECT cui_persona cui,
											concat_ws('' '', primer_apellido_persona, segundo_apellido_persona) apellidos,
											concat_ws('' '', primer_nombre_persona, segundo_nombre_persona, tercer_nombre_persona) nombres,
											TO_CHAR(fecha_nacimiento, ''dd-mm-yyyy'') fechanac,
											dn.nombre_departamento departamento,
											mn.nombre_municipio municipio,			
											dr.nombre_departamento  deptvecindad,
											mr.nombre_municipio munivecindad,
											CASE genero_persona 
												WHEN ''M'' THEN ''MASCULINO''
												WHEN ''F'' THEN ''FEMENINO'' ELSE null 
											END genero,
							   				nombre_estado_civil estadocivil
												FROM nacimiento
												INNER JOIN dpi ON cui = cui_persona
												INNER JOIN municipio mn ON municipio_nacimiento = mn.codigo_municipio
												INNER JOIN departamento dn ON mn.departamento_municipio = dn.codigo_departamento
												INNER JOIN municipio mr ON municipio_residencia = mr.codigo_municipio
												INNER JOIN departamento dr ON mr.departamento_municipio = dr.codigo_departamento
							   					INNER JOIN estado_civil ON estado_civil = id_estado_civil
													WHERE fecha_emision = ( SELECT MAX(fecha_emision) FROM dpi WHERE cui = %L )
									)t

							  ) TO  %L ',
							   cui_dpi, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\dpi_'||cui_dpi||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo dpi_'||cui_dpi||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_HIJOS
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_hijos (
		cui BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta :=( 
			SELECT DISTINCT g1.cui_persona 
				FROM nacimiento g1
				INNER JOIN nacimiento g2 ON g2.cui_padre = g1.cui_persona OR g2.cui_madre = g1.cui_persona
				WHERE g1.cui_persona = 1111111110101
		);

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontraron hijo de persona con CUI: '||cui||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
									SELECT row_to_json(t2) 
									FROM
									(
										SELECT(
											SELECT array_to_json(array_agg(row_to_json(t)))
											FROM (
													SELECT g2.cui_persona AS CUI, 
														concat_ws('' '', g2.primer_nombre_persona, g2.segundo_nombre_persona, g2.tercer_nombre_persona) nombres, 
														concat_ws('' '', g2.primer_apellido_persona, g2.segundo_apellido_persona) apellidos,
														to_char(g2.fecha_nacimiento, ''dd-mm-yyyy'') fechanac,
														dp.nombre_departamento departamento,
														mn.nombre_municipio municipio,
														CASE g2.genero_persona 
															WHEN ''M'' THEN ''MASCULINO''
															WHEN ''F'' THEN ''FEMENINO'' ELSE null 
														END genero
															FROM nacimiento g1
															INNER JOIN nacimiento g2 ON g2.cui_padre = g1.cui_persona OR g2.cui_madre = g1.cui_persona
															INNER JOIN municipio mn ON g2.municipio_nacimiento = mn.codigo_municipio
															INNER JOIN departamento dp ON mn.departamento_municipio = dp.codigo_departamento
															WHERE g1.cui_persona = %L
											)t
										)hijos
									)t2

							  ) TO  %L ',
							   cui, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\hijos_'||cui||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo hijos_'||cui||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_NIETOS
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_nietos (
	cui BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta :=( 
			SELECT DISTINCT g1.cui_persona
				FROM nacimiento g1
				INNER JOIN nacimiento g2 ON g2.cui_padre = g1.cui_persona OR g2.cui_madre = g1.cui_persona
				INNER JOIN nacimiento g3 ON g3.cui_padre = g2.cui_persona OR g3.cui_madre = g2.cui_persona
					WHERE g1.cui_persona = cui
		);

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontraron hijo de persona con CUI: '||cui||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
									SELECT row_to_json(t2) 
									FROM
									(
										SELECT(
											SELECT array_to_json(array_agg(row_to_json(t)))
											FROM (
												SELECT g3.cui_persona AS CUI, 
												concat_ws('' '', g3.primer_nombre_persona, g3.segundo_nombre_persona, g3.tercer_nombre_persona) nombres, 
												concat_ws('' '', g3.primer_apellido_persona, g3.segundo_apellido_persona) apellidos,
												to_char(g3.fecha_nacimiento, ''dd-mm-yyyy'') fechanac,
												dp.nombre_departamento departamento,
												mn.nombre_municipio municipio,
												CASE g3.genero_persona 
													WHEN ''M'' THEN ''MASCULINO'' 
													WHEN ''F'' THEN ''FEMENINO'' ELSE null 
												END genero
													FROM nacimiento g1
													INNER JOIN nacimiento g2 ON g2.cui_padre = g1.cui_persona OR g2.cui_madre = g1.cui_persona
													INNER JOIN nacimiento g3 ON g3.cui_padre = g2.cui_persona OR g3.cui_madre = g2.cui_persona
													INNER JOIN municipio mn ON g3.municipio_nacimiento = mn.codigo_municipio
													INNER JOIN departamento dp ON mn.departamento_municipio = dp.codigo_departamento
													WHERE g1.cui_persona = %L
											)t
										)nietos
									)t2

							  ) TO  %L ',
							   cui, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\nietos_'||cui||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo nietos_'||cui||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_BISNIETOS
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_bisnietos (
	cui BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta :=( 
			SELECT DISTINCT g1.cui_persona
				FROM nacimiento g1
				INNER JOIN nacimiento g2 ON g2.cui_padre = g1.cui_persona OR g2.cui_madre = g1.cui_persona
				INNER JOIN nacimiento g3 ON g3.cui_padre = g2.cui_persona OR g3.cui_madre = g2.cui_persona
				INNER JOIN nacimiento g4 ON g4.cui_padre = g3.cui_persona OR g4.cui_madre = g3.cui_persona
					WHERE g1.cui_persona = cui
		);

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontraron hijo de persona con CUI: '||cui||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
									SELECT row_to_json(t2) 
									FROM
									(
										SELECT(
											SELECT array_to_json(array_agg(row_to_json(t)))
											FROM (
												SELECT g4.cui_persona AS CUI, 
												concat_ws('' '', g4.primer_nombre_persona, g4.segundo_nombre_persona, g4.tercer_nombre_persona) nombres, 
												concat_ws('' '', g4.primer_apellido_persona, g4.segundo_apellido_persona) apellidos,
												to_char(g4.fecha_nacimiento, ''dd-mm-yyyy'') fechanac,
												dp.nombre_departamento departamento,
												mn.nombre_municipio municipio,
												CASE g4.genero_persona 
													WHEN ''M'' THEN ''MASCULINO'' 
													WHEN ''F'' THEN ''FEMENINO'' ELSE null 
												END genero
													FROM nacimiento g1
													INNER JOIN nacimiento g2 ON g2.cui_padre = g1.cui_persona OR g2.cui_madre = g1.cui_persona
													INNER JOIN nacimiento g3 ON g3.cui_padre = g2.cui_persona OR g3.cui_madre = g2.cui_persona
													INNER JOIN nacimiento g4 ON g4.cui_padre = g3.cui_persona OR g4.cui_madre = g3.cui_persona
													INNER JOIN municipio mn ON g4.municipio_nacimiento = mn.codigo_municipio
													INNER JOIN departamento dp ON mn.departamento_municipio = dp.codigo_departamento
													WHERE g1.cui_persona = %L
											)t
										)bisnietos
									)t2

							  ) TO  %L ',
							   cui, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\bisnietos_'||cui||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo bisnietos_'||cui||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_ACTA_DEFUNCION
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_acta_defuncion_cui (
		cui_dpi BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta INTEGER := 0;
	BEGIN
		respuesta :=( SELECT acta_defuncion FROM fallecimiento WHERE cui_fallecido = cui_dpi );
			
		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontro fallecimiento con CUI: '||cui_dpi||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
								  SELECT row_to_json(t)
									FROM (
										SELECT acta_defuncion noacta,
											cui_fallecido cui,
											concat_ws('' '', primer_apellido_persona, segundo_apellido_persona) apellidos,
											concat_ws('' '', primer_nombre_persona, segundo_nombre_persona, tercer_nombre_persona) nombres,
											TO_CHAR(fecha_fallecimiento, ''yyyy-mm-dd'') fechafallecimiento,
											nombre_departamento departamento,
											nombre_municipio municipio,
											motivo
											FROM fallecimiento
											INNER JOIN nacimiento ON cui_persona = cui_fallecido
											INNER JOIN municipio ON municipio_nacimiento = codigo_municipio
											INNER JOIN departamento ON departamento_municipio = codigo_departamento
												WHERE cui_fallecido = %L
									)t

							  ) TO  %L ',
							   cui_dpi, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\acta_fallecimiento_cui_'||cui_dpi||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo acta_fallecimiento_cui_'||cui_dpi||'.json');
		END IF;
		
	END;
	$$;
		
	CREATE OR REPLACE PROCEDURE obtener_acta_defuncion_noacta (
		no_acta INTEGER
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta INTEGER := 0;
	BEGIN
		respuesta :=( SELECT acta_defuncion FROM fallecimiento WHERE acta_defuncion = no_acta );
			
		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontro fallecimiento con acta No.: '||no_acta||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
								  SELECT row_to_json(t)
									FROM (
										SELECT acta_defuncion noacta,
											cui_fallecido cui,
											concat_ws('' '', primer_apellido_persona, segundo_apellido_persona) apellidos,
											concat_ws('' '', primer_nombre_persona, segundo_nombre_persona, tercer_nombre_persona) nombres,
											TO_CHAR(fecha_fallecimiento, ''dd-mm-yyyy'') fechafallecimiento,
											nombre_departamento departamento,
											nombre_municipio municipio,
											motivo
											FROM fallecimiento
											INNER JOIN nacimiento ON cui_persona = cui_fallecido
											INNER JOIN municipio ON municipio_nacimiento = codigo_municipio
											INNER JOIN departamento ON departamento_municipio = codigo_departamento
												WHERE acta_defuncion = %L
									)t

							  ) TO  %L ',
							   no_acta, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\acta_fallecimiento_noacta_'||no_acta||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo acta_fallecimiento_noacta_'||no_acta||'.json');
		END IF;
		
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_ACTA_MATRIMONIO
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_acta_matrimonio (
		no_acta INTEGER
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta INTEGER := 0;
	BEGIN
		respuesta :=( SELECT id_acta_matrimonio FROM matrimonio WHERE id_acta_matrimonio = no_acta );

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontro matrimonio con acta No.: '||no_acta||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
								  SELECT row_to_json(t)
									FROM (
										SELECT id_acta_matrimonio nomatrimonio,
											cui_hombre dpihombre,
											concat_ws('' '', h.primer_nombre_persona, h.segundo_nombre_persona, h.tercer_nombre_persona, h.primer_apellido_persona, h.segundo_apellido_persona) nombrehombre,
											cui_mujer dpimujer,
											concat_ws('' '', m.primer_nombre_persona, m.segundo_nombre_persona, m.tercer_nombre_persona, m.primer_apellido_persona, m.segundo_apellido_persona) nombremujer,
											TO_CHAR(fecha_matrimonio, ''dd-mm-yyyy'') fecha
											FROM matrimonio
											INNER JOIN nacimiento m ON cui_mujer = m.cui_persona
											INNER JOIN nacimiento h ON cui_hombre = h.cui_persona
											WHERE id_acta_matrimonio = %L
									)t

							  ) TO  %L ',
							   no_acta, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\acta_matrimonio_'||no_acta||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo acta_matrimonio_'||no_acta||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_ACTA_DIVORCIO
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_acta_divorcio (
		no_acta INTEGER
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta INTEGER := 0;
	BEGIN
		respuesta :=( SELECT id_acta_divorcio nodivorcio FROM divorcio WHERE id_acta_divorcio = no_acta );

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontro divorcio con acta No.: '||no_acta||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
								  SELECT row_to_json(t)
									FROM (
										SELECT id_acta_divorcio nodivorcio,
										cui_hombre dpihombre,
										concat_ws('' '', h.primer_nombre_persona, h.segundo_nombre_persona, h.tercer_nombre_persona, h.primer_apellido_persona, h.segundo_apellido_persona) nombrehombre,
										cui_mujer dpimujer,
										concat_ws('' '', m.primer_nombre_persona, m.segundo_nombre_persona, m.tercer_nombre_persona, m.primer_apellido_persona, m.segundo_apellido_persona) nombremujer,
										TO_CHAR(fecha_divorcio, ''dd-mm-yyyy'') fecha
										FROM divorcio
										INNER JOIN matrimonio ON id_acta_matrimonio = acta_matrimonio
										INNER JOIN nacimiento m ON cui_mujer = m.cui_persona
										INNER JOIN nacimiento h ON cui_hombre = h.cui_persona
										WHERE id_acta_divorcio = %L
									)t

							  ) TO  %L ',
							   no_acta, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\acta_divorcio_'||no_acta||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo acta_divorcio_'||no_acta||'.json');
		END IF;
	END;
	$$;	
	
	CREATE OR REPLACE PROCEDURE obtener_acta_divorcio_mat (
		no_acta INTEGER
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta INTEGER := 0;
	BEGIN
		respuesta :=( SELECT id_acta_divorcio nodivorcio FROM divorcio WHERE acta_matrimonio = no_acta );

		IF respuesta IS NULL
			THEN 
				CALL mostrar_mensaje(404, 'No se encontro matrimonio divorciado con acta No.: '||no_acta||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
								  SELECT row_to_json(t)
									FROM (
										SELECT acta_matrimonio nomatrimoniodivorciado,
										cui_hombre dpihombre,
										concat_ws('' '', h.primer_nombre_persona, h.segundo_nombre_persona, h.tercer_nombre_persona, h.primer_apellido_persona, h.segundo_apellido_persona) nombrehombre,
										cui_mujer dpimujer,
										concat_ws('' '', m.primer_nombre_persona, m.segundo_nombre_persona, m.tercer_nombre_persona, m.primer_apellido_persona, m.segundo_apellido_persona) nombremujer,
										TO_CHAR(fecha_divorcio, ''dd-mm-yyyy'') fecha
										FROM divorcio
										INNER JOIN matrimonio ON id_acta_matrimonio = acta_matrimonio
										INNER JOIN nacimiento m ON cui_mujer = m.cui_persona
										INNER JOIN nacimiento h ON cui_hombre = h.cui_persona
										WHERE  acta_matrimonio = %L
									)t

							  ) TO  %L ',
							   no_acta, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\acta_divorcio_mat_'||no_acta||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo acta_divorcio_mat_'||no_acta||'.json');
		END IF;
	END;
	$$;	
-- ======================================================================================
-- Creación de procedimiento OBTENER_LICENCIAS_REGISTRADAS
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_licencias_registradas (
		cui_licencia BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta := ( SELECT count(*) FROM licencia WHERE cui_persona = cui_licencia );

		IF respuesta <= 0
			THEN 
				CALL mostrar_mensaje(404, 'No se encontraron licencias registradas de persona con CUI: '||cui_licencia||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
									SELECT row_to_json(t2) 
									FROM
									(
										SELECT(
											SELECT array_to_json(array_agg(row_to_json(t)))
											FROM (
												SELECT no_licencia nolicencia,
													concat_ws('' '', primer_nombre_persona, segundo_nombre_persona, tercer_nombre_persona) nombres,
													concat_ws('' '', primer_apellido_persona, segundo_apellido_persona) apellidos,
													TO_CHAR(fecha_emision,''dd-mm-yyyy'') fechaemision,
													TO_CHAR(fecha_vencimiento,''dd-mm-yyyy'') fechavencimiento,
													tipo_original tipoinicial,
													tipo_actual tipolicencia
													FROM licencia
													INNER JOIN nacimiento USING (cui_persona)
														WHERE cui_persona = %L
											)t
										)licencias_registradas
									)t2

							  ) TO  %L ',
							   cui_licencia, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\licencias_registradas_'||cui_licencia||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo licencias_registradas_'||cui_licencia||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_RENOVACIONES
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_renovaciones_licencia (
		no_lic INTEGER
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta INTEGER := 0;
	BEGIN
		respuesta := ( SELECT count(*) FROM renovacion_licencia WHERE no_licencia = no_lic );

		IF respuesta <= 0
			THEN 
				CALL mostrar_mensaje(404, 'No se encontraron licencias renovadas con No.: '||no_lic||'.');
			ELSE
				EXECUTE FORMAT(' COPY (
									SELECT row_to_json(t2) 
									FROM
									(
										SELECT(
											SELECT array_to_json(array_agg(row_to_json(t)))
											FROM (
												SELECT no_licencia,
													concat_ws('' '', primer_nombre_persona, segundo_nombre_persona, tercer_nombre_persona) nombres,
													concat_ws('' '', primer_apellido_persona, segundo_apellido_persona) apellidos,
													fecha_emision fechaemision,
													fecha_renovacion fecharenovacion,
													(anios_renovacion||'' year'')::interval tiempovigencia
													FROM renovacion_licencia
													INNER JOIN licencia USING(no_licencia)
													INNER JOIN nacimiento USING(cui_persona)
														WHERE no_licencia = %L
											)t
										)renovaciones
									)t2

							  ) TO  %L ',
							   no_lic, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\licencias_renovadas_'||no_lic||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo licencias_renovadas_'||no_lic||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_MATRIMONIOS
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_matrimonios (
		cui_dpi BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta := ( SELECT count(*) FROM matrimonio WHERE cui_hombre = cui_dpi OR cui_mujer = cui_dpi );

		IF respuesta <= 0
			THEN 
				CALL mostrar_mensaje(404, 'No se encontraron hijo de persona con CUI: '||cui||'.');
			ELSE
				EXECUTE FORMAT(' COPY (
									SELECT row_to_json(t2) 
									FROM
									(
										SELECT(
											SELECT array_to_json(array_agg(row_to_json(t)))
											FROM (
												SELECT id_acta_matrimonio nomatrimonio,
													cui_hombre dpihombre,
													concat_ws('' '', h.primer_nombre_persona, h.segundo_nombre_persona, h.tercer_nombre_persona, h.primer_apellido_persona, h.segundo_apellido_persona) nombrehombre,
													cui_mujer dpimujer,
													concat_ws('' '', m.primer_nombre_persona, m.segundo_nombre_persona, m.tercer_nombre_persona, m.primer_apellido_persona, m.segundo_apellido_persona) nombremujer,
													TO_CHAR(fecha_matrimonio, ''dd-mm-yyyy'') fecha
													FROM matrimonio
													INNER JOIN nacimiento m ON cui_mujer = m.cui_persona
													INNER JOIN nacimiento h ON cui_hombre = h.cui_persona
													WHERE cui_hombre = %L OR cui_mujer = %L
											)t
										)matrimonios
									)t2

							  ) TO  %L ',
							   cui_dpi, cui_dpi, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\matrimonios_'||cui_dpi||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo matrimonios_'||cui_dpi||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
-- Creación de procedimiento OBTENER_DIVORCIOS
-- ======================================================================================
	CREATE OR REPLACE PROCEDURE obtener_divorcios (
		cui_dpi BIGINT
	)
	LANGUAGE plpgsql
	AS $$
	DECLARE
		respuesta BIGINT := 0;
	BEGIN
		respuesta := ( SELECT count(*) FROM divorcio INNER JOIN matrimonio ON id_acta_matrimonio = acta_matrimonio WHERE cui_hombre = cui_dpi OR cui_mujer = cui_dpi );

		IF respuesta <= 0
			THEN 
				CALL mostrar_mensaje(404, 'No se encontraron hijo de persona con CUI: '||cui||'.');
			ELSE 
				EXECUTE FORMAT(' COPY (
									SELECT row_to_json(t2) 
									FROM
									(
										SELECT(
											SELECT array_to_json(array_agg(row_to_json(t)))
											FROM (
												SELECT id_acta_divorcio nodivorcio,
													cui_hombre dpihombre,
													concat_ws('' '', h.primer_nombre_persona, h.segundo_nombre_persona, h.tercer_nombre_persona, h.primer_apellido_persona, h.segundo_apellido_persona) nombrehombre,
													cui_mujer dpimujer,
													concat_ws('' '', m.primer_nombre_persona, m.segundo_nombre_persona, m.tercer_nombre_persona, m.primer_apellido_persona, m.segundo_apellido_persona) nombremujer,
													TO_CHAR(fecha_divorcio, ''dd-mm-yyyy'') fecha
													FROM divorcio
													INNER JOIN matrimonio ON id_acta_matrimonio = acta_matrimonio
													INNER JOIN nacimiento m ON cui_mujer = m.cui_persona
													INNER JOIN nacimiento h ON cui_hombre = h.cui_persona
													WHERE cui_hombre = %L OR cui_mujer = %L	
											)t
										)divorcios
									)t2

							  ) TO  %L ',
							   cui_dpi, cui_dpi, 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Report\divorcios_'||cui_dpi||'.json'
				);
				CALL mostrar_mensaje(200, 'Operación completada. Puede ver el resultado en el archivo divorcios_'||cui_dpi||'.json');
		END IF;
	END;
	$$;
-- ======================================================================================
COMMIT;





