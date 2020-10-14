---------------------------------
-- GET
---------------------------------

-- GET student/info/
-- cerere pentru toti studentii cu paginare de 25 elemente
SELECT * FROM student

-- GET student/id/
-- cerere pentru studentul cu id-ul specificat
SELECT * 
FROM student
WHERE id_student = :id

-- GET student/nume/
-- cerere pentru studentul cu numele-ul specificat
SELECT * 
FROM student
WHERE nume_stud = :nume

-- GET versiune/ 
-- versiunea aplicatiei
BEGIN 
    sys.htp.p('{"versiune": "1.2"}');
END;

-- GET universitate/
-- cerere pentru universitatile existente 
SELECT *
FROM universitate

-- GET facultate/
-- cerere pentru facultatile existente 
SELECT *
FROM facultate

-- GET card/
-- cerere pentru cardurile studentilor
SELECT *
FROM card

-- GET card/{nume}
-- cerere pentru card-ul studentului cu numele specificat
SELECT *
FROM card
WHERE id_student = (
    SELECT id_student 
    FROM student
    WHERE nume_stud = :nume)

-- GET locatie/
-- cerere pentru locatiile de unde se fac tranzactiile
SELECT * 
FROM locatie

-- GET tranzactie/
-- cerere pentru tranzactiile efectuate
SELECT *
FROM tranzactie

-- GET tranzactie/{nume}
-- cerere pentru tranzacțiile studentului cu numele specificat
SELECT *
FROM tranzactie
WHERE id_student = (
    SELECT id_student 
    FROM student
    WHERE nume_stud = :nume)
	
-- GET student/login/
-- verificare nume si parola si intoarcere mesaj de raspuns
CREATE OR REPLACE PROCEDURE get_student_login(nume VARCHAR2, parola VARCHAR2)
IS
	any_rows_found NUMBER;
	v_parola student.parola%TYPE;
	e_stud EXCEPTION;
BEGIN 
	SELECT count(*)
		INTO any_rows_found
		FROM student
		WHERE nume_stud = nume;
	IF any_rows_found = 1 then
		SELECT parola
			INTO v_parola
			FROM student
			WHERE nume_stud = nume;
		IF v_parola = parola THEN
			sys.htp.p('{"autentificare": "corect"}');
		ELSE 
			sys.htp.p('{"autentificare": "fals", "motiv":"parola"}');
		END IF;
	ELSE   
		RAISE e_stud;
	END IF;
EXCEPTION
	WHEN e_stud THEN 
		sys.htp.p('{"autentificare": "fals", "motiv":"student"}');
	WHEN NO_DATA_FOUND THEN
		sys.htp.p('{"autentificare": "fals"}');
	WHEN others THEN
		sys.htp.p('{"autentificare": "fals", "motiv":"alta eroare"}');
END post_student_login;
	
---------------------------------
-- POST
---------------------------------

CREATE OR REPLACE PACKAGE post_procedures 
IS
	PROCEDURE post_student(nume VARCHAR2, n_universitate NUMBER, n_facultate NUMBER, telefon VARCHAR2, email VARCHAR2, parola VARCHAR2, status OUT INTEGER);
	PROCEDURE post_universitate(nume VARCHAR2, oras VARCHAR2, status OUT INTEGER);
	PROCEDURE post_facultate(nume VARCHAR2, univ NUMBER, status OUT INTEGER);
	PROCEDURE post_card(nr_card NUMBER, suma_card NUMBER, t_card VARCHAR2, d_expirarii VARCHAR2, cvv_card VARCHAR2, id_stud NUMBER, status OUT INTEGER);
	PROCEDURE post_locatie(den_loc VARCHAR2, adr VARCHAR2, tel VARCHAR2, com NUMBER, status OUT INTEGER);
	PROCEDURE post_tranzactie(tip_tranz VARCHAR2, data_tranz VARCHAR2, val_tranz VARCHAR2, id_stud NUMBER, id_loc NUMBER, status OUT INTEGER);
END post_procedures;

CREATE OR REPLACE PACKAGE BODY post_procedures
IS

	-- POST student/
	-- adaugare un nou student in baza de date
	CREATE OR REPLACE PROCEDURE post_student(nume VARCHAR2, n_universitate NUMBER, n_facultate NUMBER, telefon VARCHAR2, email VARCHAR2, parola VARCHAR2, status OUT INTEGER) 
	IS
		any_rows_found_stud NUMBER;
		e_stud EXCEPTION;
		e_facult EXCEPTION;
		v_id_universitate universitate.id_universitate%TYPE;
		v_id_facultate facultate.id_facultate%TYPE;
	BEGIN
		SELECT count(*)
			INTO any_rows_found_stud
			FROM student
			WHERE nume_stud = nume;
		IF any_rows_found_stud = 1 then
			RAISE e_stud;
		ELSE
			SELECT id_universitate
				INTO v_id_universitate
				FROM universitate
				WHERE nume_univ = n_universitate;
			SELECT id_facultate
				INTO v_id_facultate
				FROM facultate
				WHERE nume_facultate = n_facultate AND id_universitate = v_id_universitate;
			INSERT INTO student(nume_stud, telefon, email, parola, id_facultate)
				VALUES(nume, telefon, email, parola, v_id_facultate);
			status := 200;
		END IF;
	EXCEPTION
		WHEN e_stud THEN 
			status := 555;
		WHEN NO_DATA_FOUND THEN
			status := 550;
		WHEN others THEN
			status := 400;
	END post_student; 

	-- POST universitate/
	-- adaugare universitate
	CREATE OR REPLACE PROCEDURE post_universitate(nume VARCHAR2, oras VARCHAR2, status OUT INTEGER)
	IS
		any_rows_found NUMBER;
		e_univ EXCEPTION;
	BEGIN
		SELECT count(*)
			INTO any_rows_found
			FROM universitate
			WHERE nume_univ = nume;
		IF any_rows_found = 1 then
			RAISE e_univ;
		ELSE
			INSERT INTO universitate(nume_univ, oras)
				VALUES(nume, oras);
			status := 200;
		END IF;
	EXCEPTION
		WHEN e_univ THEN 
			status := 555;
		WHEN others THEN
			status := 400;
	END post_universitate;

	-- POST facultate/
	-- adaugare facultate
	CREATE OR REPLACE PROCEDURE post_facultate(nume VARCHAR2, univ NUMBER, status OUT INTEGER)
	IS
		any_rows_found NUMBER;
		e_facult EXCEPTION;
	BEGIN
		SELECT count(*)
			INTO any_rows_found
			FROM facultate
			WHERE nume_facultate = nume AND id_universitate = univ;
		IF any_rows_found = 1 then
			RAISE e_facult;
		ELSE
			INSERT INTO facultate(nume_facultate, id_universitate)
				VALUES(nume, univ);
			status := 200;
		END IF;
	EXCEPTION
		WHEN e_facult THEN 
			status := 555;
		WHEN others THEN
			status := 400;
	END post_facultate;

	-- POST card/
	-- adaugare card
	CREATE OR REPLACE PROCEDURE post_card(nr_card NUMBER, suma_card NUMBER, t_card VARCHAR2, d_expirarii VARCHAR2, cvv_card VARCHAR2, id_stud NUMBER, status OUT INTEGER)
	IS
		any_rows_found NUMBER;
		any_rows_found_card NUMBER;
		e_user EXCEPTION;
		e_card EXCEPTION;
	BEGIN
		SELECT count(*)
			INTO any_rows_found
			FROM student
			WHERE id_student = id_stud;
		IF any_rows_found = 1 THEN
			SELECT count(*)
				INTO any_rows_found_card
				FROM card
				WHERE numar_card = nr_card;
			IF any_rows_found_card = 1 THEN
				RAISE e_card;
			ELSE
				INSERT INTO card(numar_card, suma, tip_card, data_expirarii, cvv, id_student)
					VALUES(nr_card, suma_card, t_card, to_date(d_expirarii, 'DD.MM.YYYY'), cvv_card, id_stud);
				status := 200;
			END IF;
		ELSE
			RAISE e_user;
		END IF;
	EXCEPTION
		WHEN e_user THEN
			status := 555;
		WHEN e_card THEN
			status := 550;
		WHEN others THEN
			status := 400;
	END post_card;

	-- POST locatie/
	-- adaugare locatie
	CREATE OR REPLACE PROCEDURE post_locatie(den_loc VARCHAR2, adr VARCHAR2, tel VARCHAR2, com NUMBER, status OUT INTEGER)
	IS
		any_rows_found NUMBER;
		e_locatie EXCEPTION;
	BEGIN
		SELECT count(*)
			INTO any_rows_found
			FROM locatie
			WHERE denumire_locatie = den_loc;
		IF any_rows_found = 1 then
			RAISE e_locatie;
		ELSE
			INSERT INTO locatie(DENUMIRE_LOCATIE, ADRESA, TELEFON, COMISION)
				VALUES(den_loc, adr, tel, com);
			status := 200;
		END IF;
	EXCEPTION
		WHEN e_locatie THEN 
			status := 555;
		WHEN others THEN
			status := 400;
	END post_locatie;

	-- POST tranzactie/
	-- adaugare tranzactie si efectuare scadere / adunare in suma card-ului studentului
	CREATE OR REPLACE PROCEDURE post_tranzactie(tip_tranz VARCHAR2, data_tranz VARCHAR2, val_tranz VARCHAR2, id_stud NUMBER, id_loc NUMBER, status OUT INTEGER)
	IS
		any_rows_found_stud NUMBER;
		any_rows_found_loc NUMBER;
		e_tranzactie EXCEPTION;
		v_suma card.suma%TYPE;
		CURSOR c_suma_card(v_id_student card.id_student%TYPE) IS
			SELECT suma 
				FROM card
				WHERE id_student = v_id_student;
	BEGIN
		SELECT count(*)
			INTO any_rows_found_stud
			FROM student
			WHERE id_student = id_stud;
		SELECT count(*)
			INTO any_rows_found_loc
			FROM locatie
			WHERE id_locatie = id_loc;
		IF any_rows_found_stud = 1 AND any_rows_found_loc = 1 THEN
			OPEN c_suma_card(id_stud);
			FETCH c_suma_card IN v_suma;
			IF tip_tranz = 'A' AND v_suma - (val_tranz*12) > 0 THEN
				UPDATE card 
					SET suma = suma - (val_tranz*12)
					WHERE id_student = id_stud;
			IF tip_tranz = 'C' AND v_suma - val_tranz > 0 THEN
				UPDATE card 
					SET suma = suma - val_tranz
					WHERE id_student = id_stud;
			ELSIF tip_tranz = 'V' THEN
				UPDATE card 
					SET suma = suma + val_tranz
					WHERE id_student = id_stud;
			ELSE 
				RAISE e_suma;
			END IF;
			INSERT INTO tranzactie(tip_tranzactie, data, valoare, id_student, id_locatie)
					VALUES(tip_tranz, data_tranz, val_tranz, id_stud, id_loc);
			status := 200;
		ELSE
			RAISE e_tranzactie;
		END IF;
	EXCEPTION
		WHEN e_tranzactie THEN 
			status := 555;
		WHEN e_suma THEN
			status := 550;
		WHEN others THEN
			status := 400;
	END post_tranzactie;
	
END post_procedures;

---------------------------------
-- PUT
---------------------------------

CREATE OR REPLACE PACKAGE put_procedures 
IS
	PROCEDURE put_student(id_stud NUMBER, numeS VARCHAR2, n_universitate NUMBER, n_facultate NUMBER, telefonS VARCHAR2, emailS VARCHAR2, parolaS VARCHAR2, status OUT INTEGER);
	PROCEDURE put_universitate(id_univ NUMBER, nume VARCHAR2, oras VARCHAR2, status OUT INTEGER);
	PROCEDURE put_facultate(id NUMBER, nume VARCHAR2, univ NUMBER, status OUT INTEGER);
	PROCEDURE put_locatie(id_loc NUMBER, den_loc VARCHAR2, adr VARCHAR2, tel VARCHAR2, com NUMBER, status OUT INTEGER);
END put_procedures;

CREATE OR REPLACE PACKAGE BODY put_procedures 
IS
	-- PUT student/
	-- actualizare date student
	CREATE OR REPLACE PROCEDURE put_student(id_stud NUMBER, numeS VARCHAR2, n_universitate NUMBER, n_facultate NUMBER, telefonS VARCHAR2, emailS VARCHAR2, parolaS VARCHAR2, status OUT INTEGER) 
	IS 
		any_rows_found_stud NUMBER;
		e_stud EXCEPTION;
		e_facult EXCEPTION;
		v_id_universitate universitate.id_universitate%TYPE;
		v_id_facultate facultate.id_facultate%TYPE;
	BEGIN
		SELECT count(*)
			INTO any_rows_found_stud
			FROM student
			WHERE id_student = id_stud;
		IF any_rows_found_stud = 1 then
			SELECT id_universitate
				INTO v_id_universitate
				FROM universitate
				WHERE nume_univ = n_universitate;
			SELECT id_facultate
				INTO v_id_facultate
				FROM facultate
				WHERE nume_facultate = n_facultate AND id_universitate = v_id_universitate;
			UPDATE student
				SET nume_stud = numeS, telefon = telefonS, email = emailS, parola = parolaS, id_facultate = v_id_facultate
				WHERE id_student = id_stud;
			status := 200;
		ELSE
			RAISE e_stud;
		END IF;
	EXCEPTION
		WHEN e_stud THEN 
			status := 555;
		WHEN NO_DATA_FOUND THEN
			status := 550;
		WHEN others THEN
			status := 400;
	end;
	
	-- PUT universitate/
	-- actualizare date universitate
	CREATE OR REPLACE PROCEDURE put_universitate(id_univ NUMBER, nume VARCHAR2, oras VARCHAR2, status OUT INTEGER)
	IS 
		any_rows_found NUMBER;
		e_univ EXCEPTION;
	BEGIN
		SELECT count(*)
			INTO any_rows_found
			FROM universitate
			WHERE id_universitate = id_univ;
		IF any_rows_found = 1 then
			UPDATE universitate
				SET nume_univ = nume, oras = oras
				WHERE id_universitate = id_univ;
			status := 200;
		ELSE
			RAISE e_univ;
		END IF;
	EXCEPTION
		WHEN e_univ THEN 
			status := 555;
		WHEN others THEN
			status := 400;
	end;

	-- PUT facultate/
	-- actualizare date facultate
	CREATE OR REPLACE PROCEDURE put_facultate(id NUMBER, nume VARCHAR2, univ NUMBER, status OUT INTEGER)
	IS 
		any_rows_found NUMBER;
		e_facult EXCEPTION;
	BEGIN
		SELECT count(*)
			INTO any_rows_found
			FROM facultate
			WHERE id_facultate = id;
		IF any_rows_found = 1 then
			UPDATE facultate
				SET nume_facultate = nume, id_universitate = univ
				WHERE id_facultate = id; 
			status := 200;
		ELSE        
			RAISE e_facult;
		END IF;
	EXCEPTION
		WHEN e_facult THEN 
			status := 555;
		WHEN others THEN
			status := 400;
	END;

	-- PUT locatie/
	-- actualizare date locatie/
	CREATE OR REPLACE PROCEDURE put_locatie(id_loc NUMBER, den_loc VARCHAR2, adr VARCHAR2, tel VARCHAR2, com NUMBER, status OUT INTEGER)
	IS 
		any_rows_found NUMBER;
		e_locatie EXCEPTION;
	BEGIN
		SELECT count(*)
			INTO any_rows_found
			FROM locatie
			WHERE id_locatie = id_loc;
		IF any_rows_found = 1 then
			UPDATE locatie
				SET DENUMIRE_LOCATIE = den_loc, ADRESA = adr, TELEFON = tel, COMISION = com
				WHERE id_locatie = id_loc;
			status := 200;
		ELSE
			RAISE e_locatie;
		END IF;
	EXCEPTION
		WHEN e_locatie THEN 
			status := 555;
		WHEN others THEN
			status := 400;
	end;

END put_procedures;

---------------------------------
-- DELETE
---------------------------------

CREATE OR REPLACE PACKAGE delete_procedures 
IS
	PROCEDURE delete_student(nume VARCHAR2, status OUT INTEGER);
	PROCEDURE delete_card(nume VARCHAR2, status OUT INTEGER)
END delete_procedures;

CREATE OR REPLACE PACKAGE BODY delete_procedures 
IS
	-- DELETE student/
	-- cerere pentru stergerea contului unui student
	CREATE OR REPLACE PROCEDURE delete_student(id VARCHAR2, status OUT INTEGER)
	IS 
		DELETE FROM student
		WHERE id_student = id;
		status := 200;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			status := 550;
		WHEN OTHERS THEN
			status := 400;
	END delete_student;

	-- DELETE card/
	-- cerere pentru eliminarea cardului
	CREATE OR REPLACE PROCEDURE delete_card(id VARCHAR2, status OUT INTEGER)
	IS 
	BEGIN
		DELETE FROM card
			WHERE id_student = id;
		status := 200;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			status := 500;
		WHEN others THEN
			status := 400;
	END;
END delete_procedures;