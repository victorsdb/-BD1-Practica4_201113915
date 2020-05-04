select row_to_json(t2) 
from
(

	select (

		select array_to_json(array_agg(row_to_json(t))) 
		from (
			select nombre_categoria from categoria
		)t

	) as lenguajes
	
)t2;