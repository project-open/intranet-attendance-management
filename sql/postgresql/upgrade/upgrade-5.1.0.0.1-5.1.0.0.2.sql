-- 5.1.0.0.1-5.1.0.0.2.sql
SELECT acs_log__debug('/packages/intranet-attendance-management/sql/postgresql/upgrade/upgrade-5.1.0.0.1-5.1.0.0.2.sql','');




create or replace function inline_0 () 
returns integer as $body$
DECLARE
	v_count			integer;
BEGIN
	-- Check if colum exists in the database
	select	count(*) into v_count from user_tab_columns where lower(table_name) = 'im_attendance_intervals' and lower(column_name) = 'attendance_date_calculated';
	IF v_count = 0 THEN
		alter table im_attendance_intervals
		add column attendance_date_calculated date;
   	END IF;
	
	return 0;
END;$body$ language 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();




create or replace function im_attendance_intervals_calculate_date ()
returns trigger as $$
declare
begin
	IF pg_trigger_depth() > 1 THEN return new; END IF;
	-- IF old.attendance_start = new.attendance_start THEN return new; END IF;
	UPDATE im_attendance_intervals set attendance_date_calculated = new.attendance_start::date where attendance_id = new.attendance_id;
	return new;
end;$$ language 'plpgsql';



create or replace function inline_0 () 
returns integer as $body$
DECLARE
	v_count			integer;
BEGIN
	select count(*) into v_count from pg_trigger where tgname = 'im_attendance_intervals_date_calculated_tr';
	IF v_count = 0 THEN
		CREATE TRIGGER im_attendance_intervals_date_calculated_tr
		AFTER INSERT or UPDATE ON im_attendance_intervals
		FOR EACH ROW EXECUTE PROCEDURE im_attendance_intervals_calculate_date();
	END IF;
	
	return 0;
END;$body$ language 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();


update im_attendance_intervals set attendance_note = attendance_note;
-- update im_attendance_intervals set attendance_date_calculated = null where attendance_id = 79459;
-- select * from im_attendance_intervals where attendance_id = 79459;
