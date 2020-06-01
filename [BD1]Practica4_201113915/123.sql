	CALL registrar_nacimiento (1111111210101, 1111111240202, 'JAVIER', 'JUAN', null, '01-01-2000', 101, 'M');
	CALL obtener_acta_nacimiento(1111111470101);
	CALL registrar_nacimiento (1111111210101, 1111111240202, 'JAVIER', 'JUAN', null, '01-01-2021', 101, 'M');
	CALL registrar_licencia(1111111470101,'01-01-2017','M');
	CALL registrar_licencia(1111111470101,'01-01-2018','E');
	CALL renovar_licencia(1, '01-02-2017','C',1);
	CALL renovar_licencia(1, '01-02-2018','B',1);
	CALL renovar_licencia(1, '02-02-2019','B',1);
	CALL renovar_licencia(1, '02-02-2020','C',1);
	CALL anular_licencia(1, '02-03-2020', 'Javier lo pidio');
	
	CALL obtener_renovaciones_licencia(1);
	CALL obtener_licencias_registradas(1111111470101);
	
	CALL registrar_matrimonio(1111111470101, 1111111300404, '01-01-2020');
	
	CALL generar_dpi(1111111470101, '01-01-2018', 1701);
	CALL obtener_dpi(1111111470101);
	
	CALL obtener_acta_matrimonio(11);
	
	CALL registrar_divorcio(12, '01-01-2019');
	
	CALL obtener_matrimonios(1111111470101);
	
	CALL registrar_matrimonio(1111111470101, 1111111470101, '01-01-2020');
	
	CALL registrar_fallecimiento(1111111300404, '01-01-2020', 'Muerte Natural');
	
	CALL registrar_matrimonio(1111111470101, 1111111300404, '02-01-2020');
	
	
	
	
	

	
	
	
