BEGIN;
	COPY departamento 
		FROM 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Data\departamento.csv' 
			DELIMITER ';' NULL '-' 
				CSV HEADER;

    COPY municipio
		FROM 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Data\municipio.csv' 
			DELIMITER ';' NULL '-' 
				CSV HEADER;
				
	COPY estado_civil (nombre_estado_civil)
		FROM 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Data\estado_civil.csv' 
			DELIMITER ';' NULL '-' 
				CSV HEADER;
				
	COPY tipo_licencia
		FROM 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Data\tipo_licencia.csv' 
			DELIMITER ';' NULL '-'
			QUOTE '"'
				CSV HEADER;
	
	COPY nacimiento
		FROM 'C:\Users\victo\Documents\GitHub\-BD1-Practica4_201113915\[BD1]Practica4_201113915\Data\primera_generacion.csv' 
			DELIMITER ';' NULL '-'
			QUOTE '"'
				CSV HEADER;

	CALL registrar_nacimiento (1111111110101, 1111111120101, 'GUSTAVO', 'ADOLFO', null, '11-06-1958', 101, 'M');	
	CALL registrar_nacimiento (1111111110101, 1111111120101, 'ANA', 'MARIA', null, '12-07-1959', 101, 'F');
	CALL registrar_nacimiento (1111111110101, 1111111120101, 'KEVIN', 'ALEJANDRO', null, '11-08-1960', 101, 'M');
	CALL registrar_nacimiento (1111111130202, 1111111140202, 'ROSMERY', 'SAMANTHA', null, '12-08-1960', 202, 'F');
	CALL registrar_nacimiento (1111111130202, 1111111140202, 'MARCOS', 'ESTUARDO', null, '12-09-1961', 202, 'M');
	CALL registrar_nacimiento (1111111130202, 1111111140202, 'CAROLINA', '', null, '13-10-1962', 202, 'F');
	CALL registrar_nacimiento (1111111150303, 1111111160303, 'JORGE', 'LUIS', null, '15-10-1962', 303, 'M');
	CALL registrar_nacimiento (1111111150303, 1111111160303, 'LUCAS', 'MATEO', null, '15-11-1963', 303, 'M');
	CALL registrar_nacimiento (1111111150303, 1111111160303, 'MIGUEL', 'ANGEL', null, '15-12-1964', 303, 'M');
	CALL registrar_nacimiento (1111111170404, 1111111180404, 'PAULA', 'ISABEL', null, '16-12-1964', 404, 'F');
	CALL registrar_nacimiento (1111111170404, 1111111180404, 'SANDRA', 'KARINA', null, '16-01-1966', 404, 'F');
	CALL registrar_nacimiento (1111111170404, 1111111180404, 'TANIA', 'ELIZABETH', null, '16-02-1967', 404, 'F');
	CALL registrar_nacimiento (1111111190101, 1111111220202, 'JORGE', 'ALBERTO', null, '08-08-1979', 1701, 'M');
	CALL registrar_nacimiento (1111111190101, 1111111220202, 'ANA', 'LORENA', null, '07-09-1980', 1701, 'F');
	CALL registrar_nacimiento (1111111190101, 1111111220202, 'JOSE', 'LUIS', null, '08-10-1981', 1701, 'M');
	CALL registrar_nacimiento (1111111250303, 1111111280404, 'SILVIA', 'ELIZABETH', null, '12-12-1983', 1901, 'F');
	CALL registrar_nacimiento (1111111250303, 1111111280404, 'DIEGO', 'ALEJANDRO', null, '11-01-1985', 1901, 'M');
	CALL registrar_nacimiento (1111111250303, 1111111280404, 'ZULMA', 'SUCELY', null, '11-02-1986', 1901, 'F');
	CALL registrar_nacimiento (null, 1111111321701, 'INGRID', 'MARISOL', null, '03-09-1999', 1401, 'F');
	CALL registrar_nacimiento (1111111311701, 1111111341901, 'ROLANDO', 'SALVADOR', null, '07-12-2002', 1401, 'M');
	CALL registrar_nacimiento (1111111311701, 1111111341901, 'JUANA', 'PATRICIA', 'DEL ROSARIO', '07-01-2004', 1401, 'F');
	CALL registrar_nacimiento (1111111311701, 1111111341901, 'BRANDO', 'ELIAS', null, '06-02-2005', 1401, 'M');

	CALL registrar_matrimonio(1111111110101, 1111111120101, '16-06-1957');
	CALL registrar_matrimonio(1111111130202, 1111111140202, '18-08-1959');
	CALL registrar_matrimonio(1111111150303, 1111111160303, '20-10-1961');
	CALL registrar_matrimonio(1111111170404, 1111111180404, '22-12-1963');
	CALL registrar_matrimonio(1111111190101, 1111111220202, '13-08-1978');
	CALL registrar_matrimonio(1111111230202, 1111111200101, '13-09-1979');
	CALL registrar_matrimonio(1111111250303, 1111111280404, '17-12-1982');
	CALL registrar_matrimonio(1111111260303, 1111111290404, '17-01-1984');
	CALL registrar_matrimonio(1111111311701, 1111111341901, '12-12-2001');
	CALL registrar_matrimonio(1111111351901, 1111111321701, '12-01-2003');
	
	CALL registrar_licencia(1111111110101, '15-05-1954','M');
	CALL registrar_licencia(1111111120101, '16-06-1955','C');
	CALL registrar_licencia(1111111130202, '16-07-1956','C');
	CALL registrar_licencia(1111111140202, '17-08-1957','C');
	CALL registrar_licencia(1111111150303, '19-09-1958','C');
	CALL registrar_licencia(1111111160303, '20-10-1959','C');
	CALL registrar_licencia(1111111170404, '20-11-1960','E');
	CALL registrar_licencia(1111111180404, '21-12-1961','E');
	CALL registrar_licencia(1111111190101, '11-06-1974','C');
	CALL registrar_licencia(1111111200101, '12-07-1975','C');
	CALL registrar_licencia(1111111210101, '11-08-1976','C');
	CALL registrar_licencia(1111111220202, '12-08-1976','C');
	CALL registrar_licencia(1111111230202, '12-09-1977','C');
	CALL registrar_licencia(1111111240202, '13-10-1978','C');
	CALL registrar_licencia(1111111250303, '15-10-1978','C');

	CALL registrar_divorcio(1, '16-06-1967');
	CALL registrar_divorcio(3, '20-10-1971');
	CALL registrar_divorcio(5, '13-08-1988');
	CALL registrar_divorcio(7, '17-12-1992');
	CALL registrar_divorcio(9, '12-12-2011');

	CALL registrar_fallecimiento (1111111110101, '11-08-1961', 'Paro cardiaco');
	CALL registrar_fallecimiento (1111111140202, '13-10-1963', 'Muerte natural');
	CALL registrar_fallecimiento (1111111160303, '15-12-1964', 'Accidente automóvilistico');
	CALL registrar_fallecimiento (1111111170404, '16-02-1968', 'Diabetes');
	CALL registrar_fallecimiento (1111111190101, '08-10-1982', 'Paro respiratorio');
	
COMMIT;
	