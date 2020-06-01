BEGIN;
	CALL obtener_acta_nacimiento(1111111110101);
	CALL obtener_acta_nacimiento(1111111120101);
	CALL obtener_acta_nacimiento(1111111130202);
	CALL obtener_acta_nacimiento(1111111140202);
	CALL obtener_acta_nacimiento(1111111150303);
	CALL obtener_acta_nacimiento(1111111160303);
	CALL obtener_acta_nacimiento(1111111170404);
	CALL obtener_acta_nacimiento(1111111180404);
	CALL obtener_acta_nacimiento(1111111190101);
	CALL obtener_acta_nacimiento(1111111200101);
	CALL obtener_acta_nacimiento(1111111210101);
	CALL obtener_acta_nacimiento(1111111220202);
	CALL obtener_acta_nacimiento(1111111230202);
	CALL obtener_acta_nacimiento(1111111240202);
	CALL obtener_acta_nacimiento(1111111250303);
	CALL obtener_acta_nacimiento(1111111260303);
	CALL obtener_acta_nacimiento(1111111270303);
	CALL obtener_acta_nacimiento(1111111280404);
	CALL obtener_acta_nacimiento(1111111290404);
	CALL obtener_acta_nacimiento(1111111300404);
	CALL obtener_acta_nacimiento(1111111311701);
	CALL obtener_acta_nacimiento(1111111321701);
	CALL obtener_acta_nacimiento(1111111331701);
	CALL obtener_acta_nacimiento(1111111341901);
	CALL obtener_acta_nacimiento(1111111351901);
	CALL obtener_acta_nacimiento(1111111361901);
	CALL obtener_acta_nacimiento(1111111371401);
	CALL obtener_acta_nacimiento(1111111381401);
	CALL obtener_acta_nacimiento(1111111391401);
	CALL obtener_acta_nacimiento(1111111401401);

	CALL generar_dpi(1111111110101, '13-08-1956',1708);
	
	CALL obtener_dpi(1111111110101);

	CALL obtener_acta_defuncion_cui(1111111110101);
	CALL obtener_acta_defuncion_cui(1111111140202);
	CALL obtener_acta_defuncion_cui(1111111160303);
	CALL obtener_acta_defuncion_cui(1111111170404);
	CALL obtener_acta_defuncion_cui(1111111190101);

	CALL obtener_acta_defuncion_noacta(1);
	CALL obtener_acta_defuncion_noacta(2);
	CALL obtener_acta_defuncion_noacta(3);
	CALL obtener_acta_defuncion_noacta(4);
	CALL obtener_acta_defuncion_noacta(5);

	CALL obtener_acta_matrimonio(1);
	CALL obtener_acta_matrimonio(2);
	CALL obtener_acta_matrimonio(3);
	CALL obtener_acta_matrimonio(4);
	CALL obtener_acta_matrimonio(5);
	CALL obtener_acta_matrimonio(6);
	CALL obtener_acta_matrimonio(7);
	CALL obtener_acta_matrimonio(8);
	CALL obtener_acta_matrimonio(9);
	CALL obtener_acta_matrimonio(10);

	CALL obtener_acta_divorcio(1);
	CALL obtener_acta_divorcio(2);	
	CALL obtener_acta_divorcio(3);	
	CALL obtener_acta_divorcio(4);	
	CALL obtener_acta_divorcio(5);
	
	CALL obtener_acta_divorcio_mat(1);
	CALL obtener_acta_divorcio_mat(3);	
	CALL obtener_acta_divorcio_mat(5);	
	CALL obtener_acta_divorcio_mat(7);	
	CALL obtener_acta_divorcio_mat(9);

	CALL obtener_licencias_registradas(1111111110101);
	CALL obtener_licencias_registradas(1111111120101);
	CALL obtener_licencias_registradas(1111111130202);
	CALL obtener_licencias_registradas(1111111140202);
	CALL obtener_licencias_registradas(1111111150303);
	CALL obtener_licencias_registradas(1111111160303);
	CALL obtener_licencias_registradas(1111111170404);
	CALL obtener_licencias_registradas(1111111180404);
	CALL obtener_licencias_registradas(1111111190101);
	CALL obtener_licencias_registradas(1111111200101);
	CALL obtener_licencias_registradas(1111111210101);
	CALL obtener_licencias_registradas(1111111220202);
	CALL obtener_licencias_registradas(1111111230202);
	CALL obtener_licencias_registradas(1111111240202);
	CALL obtener_licencias_registradas(1111111250303);

	CALL obtener_hijos(1111111110101);
	CALL obtener_hijos(1111111120101);
	CALL obtener_hijos(1111111130202);
	CALL obtener_hijos(1111111140202);
	CALL obtener_hijos(1111111150303);
	CALL obtener_hijos(1111111160303);
	CALL obtener_hijos(1111111170404);
	CALL obtener_hijos(1111111180404);

	CALL obtener_nietos(1111111110101);
	CALL obtener_nietos(1111111120101);
	CALL obtener_nietos(1111111130202);
	CALL obtener_nietos(1111111140202);
	CALL obtener_nietos(1111111150303);
	CALL obtener_nietos(1111111160303);
	CALL obtener_nietos(1111111170404);
	CALL obtener_nietos(1111111180404);

	CALL obtener_bisnietos(1111111110101);
	CALL obtener_bisnietos(1111111120101);
	CALL obtener_bisnietos(1111111130202);
	CALL obtener_bisnietos(1111111140202);
	CALL obtener_bisnietos(1111111150303);
	CALL obtener_bisnietos(1111111160303);
	CALL obtener_bisnietos(1111111170404);
	CALL obtener_bisnietos(1111111180404);

	/*
		SELECT * FROM DEPARTAMENTO;
		SELECT * FROM MUNICIPIO;
		SELECT * FROM ESTADO_CIVIL;
		SELECT * FROM TIPO_LICENCIA;
		SELECT * FROM NACIMIENTO ORDER BY cui_persona;
		SELECT * FROM FALLECIMIENTO ORDER BY acta_defuncion;
		SELECT * FROM MATRIMONIO;
		SELECT * FROM DIVORCIO;
		SELECT * FROM DPI;
		SELECT * FROM LICENCIA;
		SELECT * FROM RENOVACION_LICENCIA;
		SELECT * FROM ANULACION_LICENCIA;
	*/
COMMIT;