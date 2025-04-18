

	DECLARE
	
		count_poligoni_attesi_filtrati integer;
		count_join_pratiche_dati_pratica integer;
		count_pratiche_presentate integer;
		count_pratiche_ammesse integer;
		count_pratiche_archiviate integer;
		count_cantiere_aperto integer;
		count_cantiere_chiuso integer;
		var_indicatore_A numeric(4,3);
		var_indicatore_B numeric(4,3);
		var_indicatore_C numeric(4,3);
		var_indicatore_D numeric(4,3);
		temprow RECORD;

    BEGIN
	
		DROP TABLE IF EXISTS stato_ricostruzione CASCADE;
		DROP VIEW IF EXISTS "VIEW_pratiche_dati_pratica";
		DROP VIEW IF EXISTS "VIEW_pratiche_stato_ricostruzione";
		
		-- poligoni_attesi_filtrati
		DROP TABLE IF EXISTS poligoni_attesi_filtrati;
		CREATE TEMPORARY TABLE poligoni_attesi_filtrati AS
			SELECT * 
			FROM poligoni_attesi 
			WHERE pubblico='NO' AND statistica='SI' AND statistica_esito='SI';
			
		-- count cantiere_aperto
		count_poligoni_attesi_filtrati := (SELECT COUNT(*) FROM poligoni_attesi_filtrati);
		--RAISE NOTICE 'count_poligoni_attesi_filtrati: %', count_poligoni_attesi_filtrati;
    
		-- join_pratiche_dati_pratica
		DROP TABLE IF EXISTS join_pratiche_dati_pratica;
		CREATE TEMPORARY TABLE join_pratiche_dati_pratica AS
			SELECT 
			--a.geom,
			a.protocollo_normalizzato,
			a.id_aggregato,
			b.data_ammissione_chiusura,
			b.importo_ammesso,
			b.denominazione_aggregato,
			b.codice_fiscale_richiedente,
			b.cantiere_chiuso,
			b.cantiere_avviato,
			b.cup,
			b.fonte_dati,
			b.stato_della_fonte_dati,
			b.erogato,
			b.esito_agibilita,
			b.stato_omogeneo,
			b.ufficio,
			b.data_richiesto,
			b.importo_richiesto,
			b.livello_di_sicurezza_post,
			b.livello_di_sicurezza_ante,
			b.tipologia,
			b.stato_usrc_gis
			FROM pratiche AS a 
			LEFT JOIN dati_pratica AS b ON a.protocollo_normalizzato = b.protocollo_normalizzato;
		ALTER TABLE join_pratiche_dati_pratica ADD COLUMN _count int NOT NULL DEFAULT 1;

		-- count join_pratiche_dati_pratica
		count_join_pratiche_dati_pratica := (SELECT COUNT(*) FROM join_pratiche_dati_pratica);
		--RAISE NOTICE 'count_join_pratiche_dati_pratica: %', count_join_pratiche_dati_pratica;
		
		-- pratiche_presentate
		DROP TABLE IF EXISTS pratiche_presentate;
		CREATE TEMPORARY TABLE pratiche_presentate AS
			SELECT * 
			FROM join_pratiche_dati_pratica 
			WHERE stato_usrc_gis IN ('0','1','2','3','4');
			
		-- count pratiche_presentate
		count_pratiche_presentate := (SELECT COUNT(*) FROM pratiche_presentate);
		--RAISE NOTICE 'count_pratiche_presentate: %', count_pratiche_presentate;
		
		-- pratiche_ammesse
		DROP TABLE IF EXISTS pratiche_ammesse;
		CREATE TEMPORARY TABLE pratiche_ammesse AS
			SELECT * 
			FROM join_pratiche_dati_pratica 
			WHERE stato_usrc_gis IN ('0','1','2');
			
		-- count pratiche_ammesse
		count_pratiche_ammesse := (SELECT COUNT(*) FROM pratiche_ammesse);
		--RAISE NOTICE 'count_pratiche_ammesse: %', count_pratiche_ammesse;
			
		-- pratiche_archiviate
		DROP TABLE IF EXISTS pratiche_archiviate;
		CREATE TEMPORARY TABLE pratiche_archiviate AS
			SELECT * 
			FROM join_pratiche_dati_pratica 
			WHERE stato_usrc_gis='3';
			
		-- count pratiche_archiviate
		count_pratiche_archiviate := (SELECT COUNT(*) FROM pratiche_archiviate);
		--RAISE NOTICE 'count_pratiche_archiviate: %', count_pratiche_archiviate;
			
		-- cantiere_aperto
		DROP TABLE IF EXISTS cantiere_aperto;
		CREATE TEMPORARY TABLE cantiere_aperto AS
			SELECT * 
			FROM join_pratiche_dati_pratica 
			WHERE stato_usrc_gis IN ('0','2');
			
		-- count cantiere_aperto
		count_cantiere_aperto := (SELECT COUNT(*) FROM cantiere_aperto);
		--RAISE NOTICE 'count_cantiere_aperto: %', count_cantiere_aperto;
			
		-- cantiere_chiuso
		DROP TABLE IF EXISTS cantiere_chiuso;
		CREATE TEMPORARY TABLE cantiere_chiuso AS
			SELECT * 
			FROM join_pratiche_dati_pratica 
			WHERE stato_usrc_gis='0';

		-- count cantiere_chiuso
		count_cantiere_chiuso := (SELECT COUNT(*) FROM cantiere_chiuso);
		--RAISE NOTICE 'count_cantiere_chiuso: %', count_cantiere_chiuso;

		-- statistiche_presentate
		DROP TABLE IF EXISTS statistiche_presentate;
		CREATE TEMPORARY TABLE statistiche_presentate AS
			SELECT id_aggregato,
			count (_count) AS _count
			FROM pratiche_presentate 
			GROUP BY id_aggregato;
		ALTER TABLE statistiche_presentate ADD COLUMN _min int NOT NULL DEFAULT 1;
		
		-- statistiche_ammesse
		DROP TABLE IF EXISTS statistiche_ammesse;
		CREATE TEMPORARY TABLE statistiche_ammesse AS
			SELECT id_aggregato,
			count (_count) AS _count
			FROM pratiche_ammesse
			GROUP BY id_aggregato;
		ALTER TABLE statistiche_ammesse ADD COLUMN _min int NOT NULL DEFAULT 1;

		-- statistiche_archiviate
		DROP TABLE IF EXISTS statistiche_archiviate;
		CREATE TEMPORARY TABLE statistiche_archiviate AS
			SELECT id_aggregato,
			count (_count) AS _count
			FROM pratiche_archiviate
			GROUP BY id_aggregato;
		ALTER TABLE statistiche_archiviate ADD COLUMN _min int NOT NULL DEFAULT 1;
		
		-- statistiche_cantiere_aperto
		DROP TABLE IF EXISTS statistiche_cantiere_aperto;
		CREATE TEMPORARY TABLE statistiche_cantiere_aperto AS
			SELECT id_aggregato,
			count (_count) AS _count
			FROM cantiere_aperto
			GROUP BY id_aggregato;
		ALTER TABLE statistiche_cantiere_aperto ADD COLUMN _min int NOT NULL DEFAULT 1;
		
		-- statistiche_cantiere_chiuso
		DROP TABLE IF EXISTS statistiche_cantiere_chiuso;
		CREATE TEMPORARY TABLE statistiche_cantiere_chiuso AS
			SELECT id_aggregato,
			count (_count) AS _count
			FROM cantiere_chiuso
			GROUP BY id_aggregato;
		ALTER TABLE statistiche_cantiere_chiuso ADD COLUMN _min int NOT NULL DEFAULT 1;

		-- stato_ricostruzione
		CREATE TABLE stato_ricostruzione AS
			SELECT 
			a.geom,
			a.importo,
			a.piano_di_ricostruzione,
			a.id_aggregato,
			a.ae,
			a.fase_cronologica,
			a.ambito,
			a.int_fin,
			a.ae_es,
			a.note,
			a.note_1,
			a.pubblico,
			a.statistica,
			a.esito_pdr,
			a.statistica_esito,
			a.procom,
			a.sisma_bonus,
			a.esito_a,
			b._count AS somma_presentate,
			b._min AS presentate,
			c._count AS somma_ammesse,
			c._min AS ammesse,
			d._count AS somma_archiviate,
			d._min AS archiviate,
			e._count AS somma_cantiere_aperto,
			e._min AS cantiere_aperto,
			f._count AS somma_cantiere_chiuso,
			f._min AS cantiere_chiuso
			FROM poligoni_attesi_filtrati AS a 
			--FROM poligoni_attesi AS a 
			LEFT JOIN statistiche_presentate AS b ON a.id_aggregato = b.id_aggregato
			LEFT JOIN statistiche_ammesse AS c ON a.id_aggregato = c.id_aggregato
			LEFT JOIN statistiche_archiviate AS d ON a.id_aggregato = d.id_aggregato
			LEFT JOIN statistiche_cantiere_aperto AS e ON a.id_aggregato = e.id_aggregato
			LEFT JOIN statistiche_cantiere_chiuso AS f ON a.id_aggregato = f.id_aggregato;
		UPDATE stato_ricostruzione SET somma_presentate = 0 WHERE somma_presentate IS NULL;
		UPDATE stato_ricostruzione SET presentate = 0 WHERE presentate IS NULL;
		UPDATE stato_ricostruzione SET somma_ammesse = 0 WHERE somma_ammesse IS NULL;
		UPDATE stato_ricostruzione SET ammesse = 0 WHERE ammesse IS NULL;
		UPDATE stato_ricostruzione SET somma_archiviate = 0 WHERE somma_archiviate IS NULL;
		UPDATE stato_ricostruzione SET archiviate = 0 WHERE archiviate IS NULL;
		UPDATE stato_ricostruzione SET somma_cantiere_aperto = 0 WHERE somma_cantiere_aperto IS NULL;
		UPDATE stato_ricostruzione SET cantiere_aperto = 0 WHERE cantiere_aperto IS NULL;
		UPDATE stato_ricostruzione SET somma_cantiere_chiuso = 0 WHERE somma_cantiere_chiuso IS NULL;
		UPDATE stato_ricostruzione SET cantiere_chiuso = 0 WHERE cantiere_chiuso IS NULL;

		ALTER TABLE stato_ricostruzione ADD COLUMN classe varchar(50);
		
		UPDATE stato_ricostruzione SET classe = 'AMMESSO' WHERE ammesse = 1;
		UPDATE stato_ricostruzione SET classe = 'ARCHIVIATO' WHERE (ammesse = 0 AND presentate = 1) AND ((somma_presentate-somma_archiviate) = 0);
		UPDATE stato_ricostruzione SET classe = 'PRESENTATO' WHERE (ammesse = 0 AND presentate = 1) AND ((somma_presentate-somma_archiviate) > 0);
		UPDATE stato_ricostruzione SET classe = 'DA PRESENTARE' WHERE presentate = 0;
		UPDATE stato_ricostruzione SET classe = 'ESITO A' WHERE esito_a = 'SI';
		
		ALTER TABLE stato_ricostruzione ADD COLUMN stato_cantiere varchar(50) NOT NULL DEFAULT 'NO DATA';

		UPDATE stato_ricostruzione SET stato_cantiere = 'CANTIERE APERTO' WHERE ammesse = 1 AND cantiere_aperto = 1 AND ((somma_cantiere_aperto-somma_cantiere_chiuso) > 0);
		UPDATE stato_ricostruzione SET stato_cantiere = 'CANTIERE CHIUSO' WHERE ammesse = 1 AND cantiere_aperto = 1 AND ((somma_cantiere_aperto-somma_cantiere_chiuso) = 0);

		-- indicatori_esclusione_esiti_a
		DROP TABLE IF EXISTS indicatori_esclusione_esiti_a;
		CREATE TEMPORARY TABLE indicatori_esclusione_esiti_a AS
			SELECT * FROM stato_ricostruzione
			WHERE esito_a = 'NO';
		ALTER TABLE indicatori_esclusione_esiti_a ADD COLUMN archiviate_new integer DEFAULT 0;
		UPDATE indicatori_esclusione_esiti_a SET archiviate_new = 1 WHERE (ammesse = 0 AND presentate = 1) AND ((somma_presentate-somma_archiviate) = 0);
		ALTER TABLE indicatori_esclusione_esiti_a ADD COLUMN cantiere_chiuso_new integer DEFAULT 0;
		UPDATE indicatori_esclusione_esiti_a SET cantiere_chiuso_new = 1 WHERE ammesse = 1 AND cantiere_aperto = 1 AND ((somma_cantiere_aperto-somma_cantiere_chiuso) = 0);
			
		-- indicatori_comune
		DROP TABLE IF EXISTS indicatori_comune;
		CREATE TEMPORARY TABLE indicatori_comune AS
			SELECT a.procom,
			count(a.presentate) AS totali_attesi,
			sum(a.presentate) AS aggregati_con_pratica_presentata,
			sum(a.ammesse) AS aggregati_con_pratica_ammessa,
			sum(a.archiviate_new) AS aggregati_con_pratica_archiviata,
			sum(a.cantiere_aperto) AS aggregati_con_cantiere_aperto,
			sum(a.cantiere_chiuso_new) AS aggregati_con_cantiere_chiuso,
			b.nome_minus,
			b.area_omogenea
			FROM indicatori_esclusione_esiti_a AS a
			LEFT JOIN "SUPPORTO_perimetrazione_comuni_cratere" AS b ON a.procom = b.procom::integer
			WHERE a.procom IS NOT NULL
			GROUP BY a.procom, b.nome_minus, b.area_omogenea;
		ALTER TABLE indicatori_comune ADD COLUMN indicatore_A decimal;
		ALTER TABLE indicatori_comune ADD COLUMN indicatore_B decimal;
		ALTER TABLE indicatori_comune ADD COLUMN indicatore_C decimal;
		ALTER TABLE indicatori_comune ADD COLUMN indicatore_D decimal;

		FOR temprow IN (SELECT * FROM indicatori_comune)
    	LOOP
			var_indicatore_A := TRUNC((temprow.aggregati_con_pratica_presentata::numeric / temprow.totali_attesi::numeric),3);
			var_indicatore_B := TRUNC((temprow.aggregati_con_pratica_ammessa::numeric / (temprow.aggregati_con_pratica_presentata::numeric - temprow.aggregati_con_pratica_archiviata::numeric)),3);
			var_indicatore_C := TRUNC((temprow.aggregati_con_cantiere_aperto::numeric / (temprow.aggregati_con_pratica_presentata::numeric - temprow.aggregati_con_pratica_archiviata::numeric)),3);
			var_indicatore_D := TRUNC((temprow.aggregati_con_cantiere_chiuso::numeric / (temprow.aggregati_con_pratica_presentata::numeric - temprow.aggregati_con_pratica_archiviata::numeric)),3);
			UPDATE indicatori_comune 
			SET indicatore_A = var_indicatore_A,  
			indicatore_B = var_indicatore_B,
			indicatore_C = var_indicatore_C,
			indicatore_D = var_indicatore_D						  
			WHERE procom = temprow.procom;		
		END LOOP;

		-- indicatori_comune
		DROP TABLE IF EXISTS indicatori_comune_geom;
		CREATE TABLE indicatori_comune_geom AS
			SELECT a.procom,
			a.totali_attesi,
			a.aggregati_con_pratica_presentata,
			a.aggregati_con_pratica_ammessa,
			a.aggregati_con_pratica_archiviata,
			a.aggregati_con_cantiere_aperto,
			a.aggregati_con_cantiere_chiuso,
			a.nome_minus,
			a.indicatore_A,
			a.indicatore_B,
			a.indicatore_C,
			a.indicatore_D,
			b.geom
			FROM indicatori_comune AS a
			LEFT JOIN "SUPPORTO_perimetrazione_comuni_cratere" AS b ON a.procom = b.procom::integer;
		
		-- statistiche_presentate_ao
		DROP TABLE IF EXISTS statistiche_presentate_ao;
		CREATE TEMPORARY TABLE statistiche_presentate_ao AS
			SELECT sum(aggregati_con_pratica_presentata) AS aggregati_con_pratica_presentata_ao,
			area_omogenea
			FROM indicatori_comune 
			GROUP BY area_omogenea;

		-- statistiche_ammesse_ao
		DROP TABLE IF EXISTS statistiche_ammesse_ao;
		CREATE TEMPORARY TABLE statistiche_ammesse_ao AS
			SELECT sum(aggregati_con_pratica_ammessa) AS aggregati_con_pratica_ammessa_ao,
			area_omogenea
			FROM indicatori_comune 
			GROUP BY area_omogenea;

		-- statistiche_archiviate_ao
		DROP TABLE IF EXISTS statistiche_archiviate_ao;
		CREATE TEMPORARY TABLE statistiche_archiviate_ao AS
			SELECT sum(aggregati_con_pratica_archiviata) AS aggregati_con_pratica_archiviata_ao,
			area_omogenea
			FROM indicatori_comune 
			GROUP BY area_omogenea;

		-- statistiche_cantiere_aperto_ao
		DROP TABLE IF EXISTS statistiche_cantiere_aperto_ao;
		CREATE TEMPORARY TABLE statistiche_cantiere_aperto_ao AS
			SELECT sum(aggregati_con_cantiere_aperto) AS aggregati_con_cantiere_aperto_ao,
			area_omogenea
			FROM indicatori_comune 
			GROUP BY area_omogenea;

		-- statistiche_cantiere_chiuso_ao
		DROP TABLE IF EXISTS statistiche_cantiere_chiuso_ao;
		CREATE TEMPORARY TABLE statistiche_cantiere_chiuso_ao AS
			SELECT sum(aggregati_con_cantiere_chiuso) AS aggregati_con_cantiere_chiuso_ao,
			area_omogenea
			FROM indicatori_comune 
			GROUP BY area_omogenea;
		
		-- statistiche_attesi_ao
		DROP TABLE IF EXISTS statistiche_attesi_ao;
		CREATE TEMPORARY TABLE statistiche_attesi_ao AS
			SELECT sum(totali_attesi) AS totali_attesi_ao,
			area_omogenea
			FROM indicatori_comune 
			GROUP BY area_omogenea;

		-- indicatori_ao_geom
		DROP TABLE IF EXISTS indicatori_ao_geom;
		CREATE TABLE indicatori_ao_geom AS
			SELECT 
			a.area_omogenea,
			a.aggregati_con_pratica_presentata_ao,
			b.aggregati_con_pratica_ammessa_ao,
			c.aggregati_con_pratica_archiviata_ao,
			d.aggregati_con_cantiere_aperto_ao,
			e.aggregati_con_cantiere_chiuso_ao,
			f.totali_attesi_ao,
			g.geom
			FROM statistiche_presentate_ao AS a 
			LEFT JOIN statistiche_ammesse_ao AS b ON a.area_omogenea = b.area_omogenea
			LEFT JOIN statistiche_archiviate_ao AS c ON a.area_omogenea = c.area_omogenea
			LEFT JOIN statistiche_cantiere_aperto_ao AS d ON a.area_omogenea = d.area_omogenea
			LEFT JOIN statistiche_cantiere_chiuso_ao AS e ON a.area_omogenea = e.area_omogenea
			LEFT JOIN statistiche_attesi_ao AS f ON a.area_omogenea = f.area_omogenea
			LEFT JOIN "SUPPORTO_area_omogenea" AS g ON a.area_omogenea = g.area_omogenea;
		ALTER TABLE indicatori_ao_geom ADD COLUMN indicatore_A decimal;
		ALTER TABLE indicatori_ao_geom ADD COLUMN indicatore_B decimal;
		ALTER TABLE indicatori_ao_geom ADD COLUMN indicatore_C decimal;
		ALTER TABLE indicatori_ao_geom ADD COLUMN indicatore_D decimal;
		
		FOR temprow IN (SELECT * FROM indicatori_ao_geom)
    	LOOP
			var_indicatore_A := TRUNC((temprow.aggregati_con_pratica_presentata_ao::numeric / temprow.totali_attesi_ao::numeric),3);
			var_indicatore_B := TRUNC((temprow.aggregati_con_pratica_ammessa_ao::numeric / (temprow.aggregati_con_pratica_presentata_ao::numeric - temprow.aggregati_con_pratica_archiviata_ao::numeric)),3);
			var_indicatore_C := TRUNC((temprow.aggregati_con_cantiere_aperto_ao::numeric / (temprow.aggregati_con_pratica_presentata_ao::numeric - temprow.aggregati_con_pratica_archiviata_ao::numeric)),3);
			var_indicatore_D := TRUNC((temprow.aggregati_con_cantiere_chiuso_ao::numeric / (temprow.aggregati_con_pratica_presentata_ao::numeric - temprow.aggregati_con_pratica_archiviata_ao::numeric)),3);
			UPDATE indicatori_ao_geom
			SET indicatore_A = var_indicatore_A,  
			indicatore_B = var_indicatore_B,
			indicatore_C = var_indicatore_C,
			indicatore_D = var_indicatore_D						  
			WHERE area_omogenea = temprow.area_omogenea;				
		END LOOP;
		
		CREATE VIEW "VIEW_pratiche_stato_ricostruzione" AS
		SELECT row_number() OVER (ORDER BY a.id) AS id,
    a.protocollo_normalizzato,
    COALESCE(b.denominazione_richiedente, '-'::character varying) AS denominazione_richiedente,
    COALESCE(c.descrizione, '-'::character varying) AS stato_usrc_gis,
    COALESCE(b.denominazione_aggregato, '-'::character varying) AS denominazione_aggregato,
        CASE
            WHEN b.data_richiesto IS NULL THEN '-'::text::character varying
            ELSE to_char(b.data_richiesto::timestamp with time zone, 'dd/mm/yyyy'::text)::character varying
        END AS data_richiesto,
    replace(replace(replace(replace(b.importo_richiesto::money::character varying::text, '$'::text, '€ '::text), ','::text, '#'::text), '.'::text, ','::text), '#'::text, '.'::text) AS importo_richiesto,
        CASE
            WHEN b.data_ammissione_chiusura IS NULL THEN '-'::text::character varying
			ELSE to_char(b.data_ammissione_chiusura::timestamp with time zone, 'dd/mm/yyyy'::text)::character varying
        END AS data_ammissione_chiusura,
    replace(replace(replace(replace(b.importo_ammesso::money::character varying::text, '$'::text, '€ '::text), ','::text, '#'::text), '.'::text, ','::text), '#'::text, '.'::text) AS importo_ammesso,
    replace(replace(replace(replace(b.erogato::money::character varying::text, '$'::text, '€ '::text), ','::text, '#'::text), '.'::text, ','::text), '#'::text, '.'::text) AS erogato,
    COALESCE(b.cantiere_avviato, '-'::character varying) AS cantiere_avviato,
    COALESCE(b.tipologia, '-'::character varying) AS tipologia,
    COALESCE(b.cup, '-'::character varying) AS cup,
    COALESCE(b.ufficio, '-'::character varying) AS ufficio,
    a.id_gis,
    a.id_aggregato,
    COALESCE(d.classe, '-'::character varying) AS classe,
    COALESCE(d.stato_cantiere, '-'::character varying) AS stato_cantiere,
        CASE
            WHEN b.livello_di_sicurezza_ante::text = 'Null'::text THEN '-'::text::character varying
            ELSE COALESCE(b.livello_di_sicurezza_ante, '-'::character varying)
        END AS livello_di_sicurezza_ante,
        CASE
            WHEN b.livello_di_sicurezza_post::text = 'Null'::text THEN '-'::text::character varying
            ELSE COALESCE(b.livello_di_sicurezza_post, '-'::character varying)
        END AS livello_di_sicurezza_post,
    d.somma_presentate,
    d.somma_ammesse,
    d.somma_archiviate,
    d.somma_cantiere_aperto,
    d.somma_cantiere_chiuso,
    d.geom,
        CASE
            WHEN c.descrizione::text = 'PRESENTATA'::text THEN '1'::text
            WHEN c.descrizione::text = 'AMMESSA'::text THEN '2'::text
            WHEN c.descrizione::text = 'CANTIERE APERTO'::text THEN '3'::text
            WHEN c.descrizione::text = 'CANTIERE CHIUSO'::text THEN '4'::text
            WHEN c.descrizione::text = 'CHIUSA SENZA AMMISSIONE'::text THEN '5'::text
            ELSE NULL::text
        END AS ordine_visualizzazione
   FROM pratiche a
     LEFT JOIN dati_pratica b ON a.protocollo_normalizzato::text = b.protocollo_normalizzato::text
     LEFT JOIN "VALORI_stato_usrc_gis" c ON b.stato_usrc_gis::text = c.valore::text
     LEFT JOIN stato_ricostruzione d ON a.id_aggregato::text = d.id_aggregato::text
  ORDER BY (COALESCE(c.descrizione, '-'::character varying));
		
		CREATE VIEW "VIEW_pratiche_dati_pratica" AS
		SELECT row_number() OVER (ORDER BY a.id) AS id,
    a.protocollo_normalizzato,
    COALESCE(b.denominazione_richiedente, '-'::character varying) AS denominazione_richiedente,
    COALESCE(c.descrizione, '-'::character varying) AS stato_usrc_gis,
    COALESCE(b.denominazione_aggregato, '-'::character varying) AS denominazione_aggregato,
        CASE
            WHEN b.data_richiesto IS NULL THEN '-'::text::character varying
            ELSE to_char(b.data_richiesto::timestamp with time zone, 'dd/mm/yyyy'::text)::character varying
        END AS data_richiesto,
    replace(replace(replace(replace(b.importo_richiesto::money::character varying::text, '$'::text, '€ '::text), ','::text, '#'::text), '.'::text, ','::text), '#'::text, '.'::text) AS importo_richiesto,
        CASE
            WHEN b.data_ammissione_chiusura IS NULL THEN '-'::text::character varying
			ELSE to_char(b.data_ammissione_chiusura::timestamp with time zone, 'dd/mm/yyyy'::text)::character varying
        END AS data_ammissione_chiusura,
    replace(replace(replace(replace(b.importo_ammesso::money::character varying::text, '$'::text, '€ '::text), ','::text, '#'::text), '.'::text, ','::text), '#'::text, '.'::text) AS importo_ammesso,
    replace(replace(replace(replace(b.erogato::money::character varying::text, '$'::text, '€ '::text), ','::text, '#'::text), '.'::text, ','::text), '#'::text, '.'::text) AS erogato,
    COALESCE(b.cantiere_avviato, '-'::character varying) AS cantiere_avviato,
    COALESCE(b.tipologia, '-'::character varying) AS tipologia,
    COALESCE(b.cup, '-'::character varying) AS cup,
    COALESCE(b.ufficio, '-'::character varying) AS ufficio,
    a.id_gis,
    a.id_aggregato,
        CASE
            WHEN b.livello_di_sicurezza_ante::text = 'Null'::text THEN '-'::text::character varying
            ELSE COALESCE(b.livello_di_sicurezza_ante, '-'::character varying)
        END AS livello_di_sicurezza_ante,
        CASE
            WHEN b.livello_di_sicurezza_post::text = 'Null'::text THEN '-'::text::character varying
            ELSE COALESCE(b.livello_di_sicurezza_post, '-'::character varying)
        END AS livello_di_sicurezza_post,
    a.geom,
        CASE
            WHEN c.descrizione::text = 'PRESENTATA'::text THEN '1'::text
            WHEN c.descrizione::text = 'AMMESSA'::text THEN '2'::text
            WHEN c.descrizione::text = 'CANTIERE APERTO'::text THEN '3'::text
            WHEN c.descrizione::text = 'CANTIERE CHIUSO'::text THEN '4'::text
            WHEN c.descrizione::text = 'CHIUSA SENZA AMMISSIONE'::text THEN '5'::text
            ELSE NULL::text
        END AS ordine_visualizzazione
   FROM pratiche a
     LEFT JOIN dati_pratica b ON a.protocollo_normalizzato::text = b.protocollo_normalizzato::text
     LEFT JOIN "VALORI_stato_usrc_gis" c ON b.stato_usrc_gis::text = c.valore::text;
		
		GRANT ALL ON stato_ricostruzione TO role_writeaccess;
		GRANT ALL ON indicatori_comune_geom TO role_writeaccess;
		GRANT ALL ON indicatori_ao_geom TO role_writeaccess;
		GRANT ALL ON "VIEW_pratiche_stato_ricostruzione" TO role_writeaccess;
		GRANT ALL ON "VIEW_pratiche_dati_pratica" TO role_writeaccess;
		
		GRANT SELECT ON stato_ricostruzione TO role_readaccess;
		GRANT SELECT ON indicatori_comune_geom TO role_readaccess;
		GRANT SELECT ON indicatori_ao_geom TO role_readaccess;
		GRANT SELECT ON "VIEW_pratiche_stato_ricostruzione" TO role_readaccess;
		GRANT SELECT ON "VIEW_pratiche_dati_pratica" TO role_readaccess;
		
	END;
