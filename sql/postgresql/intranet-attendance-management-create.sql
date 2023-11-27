-- /packages/intranet-attendance-management/sql/postgres/intranet-attendance-management-create.sql
--
-- Copyright (C) 2014-2023 ]project-open[
--
-- @author frank.bergmann@project-open.com


------------------------------------------------------------
-- Attendance Hours
--

select acs_object_type__create_type (
	'im_attendance_interval',		-- object_type
	'Attendance Interval',			-- pretty_name
	'Attendance Interval',			-- pretty_plural
	'acs_object',				-- supertype
	'im_attendance_intervals',		-- table_name
	'attendance_id',			-- id_column
	'intranet-attendance-management',	-- package_name
	'f',					-- abstract_p
	null,					-- type_extension_table
	'im_attendance_interval__name'		-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_attendance_interval', 'im_attendance_intervals', 'attendance_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_attendance_interval', 'acs_objects', 'object_id');

update acs_object_types set
	status_type_table = 'im_attendance_intervals',
	status_column = 'attendance_status_id',
	type_column = 'attendance_type_id',
	type_category_type = 'Intranet Attendance Interval Type'
where object_type = 'im_attendance_interval';


-------------------------------------------------------------
-- Business Object URLs

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_attendance_interval','view','/intranet-attendance-management/new?form_mode=display&attendance_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_attendance_interval','edit','/intranet-attendance-management/new?attendance_id=');


-------------------------------------------------------------
-- Table

create table im_attendance_intervals (
	attendance_id		integer 
				constraint im_attendance_intervals_pk
				primary key
				constraint im_attendance_intervals_attendance_fk
				references acs_objects,
				
	attendance_user_id	integer 
				constraint im_attendance_intervals_user_id_nn
				not null 
				constraint im_attendance_intervals_user_id_fk
				references users,
	attendance_start	timestamptz
				constraint im_attendance_intervals_attendance_start_nn
				not null,
	attendance_end		timestamptz,
				-- may be NULL to indicate that logging in ongoing
				
	attendance_status_id	integer
				constraint im_attendance_intervals_status_nn
				not null
				constraint im_attendance_intervals_status_fk
				references im_categories
				default 92020, -- Active
	attendance_type_id	integer
				constraint im_attendance_intervals_type_nn
				not null
				constraint im_attendance_intervals_type_fk
				references im_categories
				default 92100, -- Attendance
				
	attendance_material_id	integer
				constraint im_attendance_intervals_material_fk
				references im_materials,
	attendance_activity_id	integer
				constraint im_attendance_intervals_activity_fk
				references im_categories,
	attendance_note		text
);

-- Unique constraint to avoid that you can add two identical rows
alter table im_attendance_intervals
add constraint im_attendance_intervals_unique
unique (attendance_user_id, attendance_start);

create index im_attendance_intervals_user_id_idx on im_attendance_intervals(attendance_user_id);
create index im_attendance_intervals_attendance_start_idx on im_attendance_intervals(attendance_start);



-- ------------------------------------------------------------
-- Portlet
-- ------------------------------------------------------------

SELECT im_component_plugin__new (
	null, 'im_component_plugin', now(), null, null, null,
	'Attendance Management',		-- plugin_name
	'intranet-attendance-management',	-- package_name
	'left',					-- location
	'/intranet/index',			-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_attendance_management_portlet -width 600 -height 500'
);

SELECT acs_permission__grant_permission(
	(select plugin_id
	from im_component_plugins
	where plugin_name = 'Attendance Management' and
	      package_name = 'intranet-attendance-management'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);




-- ------------------------------------------------------------
-- Categories
-- ------------------------------------------------------------

-- 92000-92999  Attendance Management (1000)

-- 92000-92099  Intranet Attendance Status (100)
-- 92100-92199  Intranet Attendance Type (100)
-- 92200-92299  Intranet Attendance Action (100)
-- 92300-92399  Intranet Attendance Activity (100)


-- ---------------------------------------------------------
-- Attendance Status
--
-- 92000-92099  Intranet Attendance Status (100)
SELECT im_category_new(92000, 'Approved', 'Intranet Attendance Status');
SELECT im_category_new(92010, 'Requested', 'Intranet Attendance Status');
SELECT im_category_new(92020, 'Active', 'Intranet Attendance Status');
SELECT im_category_new(92090, 'Closed', 'Intranet Attendance Status');
SELECT im_category_new(92099, 'Deleted', 'Intranet Attendance Status');
SELECT im_category_hierarchy_new(92099, 92090);

create or replace view im_attendance_status as
select category_id as attendance_status_id, category as attendance_status
from im_categories
where category_type = 'Intranet Attendance Status';


-- ---------------------------------------------------------
-- Attendance Type
--
-- 92100-92199  Intranet Attendance Type (100)
SELECT im_category_new(92100, 'Work', 'Intranet Attendance Type');
SELECT im_category_new(92110, 'Break', 'Intranet Attendance Type');

create or replace view im_attendance_type as
select category_id as attendance_type_id, category as attendance_type
from im_categories
where category_type = 'Intranet Attendance Type';


-- ---------------------------------------------------------
-- Attendance Activity
--
-- 92300-92399  Intranet Attendance Activity (100)
SELECT im_category_new(92300, 'Work', 'Intranet Attendance Activity');
SELECT im_category_new(92310, 'Break', 'Intranet Attendance Activity');

create or replace view im_attendance_activity as
select category_id as attendance_activity_id, category as attendance_activity
from im_categories
where category_type = 'Intranet Attendance Activity';


-- ---------------------------------------------------------
-- Other

-- SELECT im_category_new(92200, 'Save', 'Intranet Attendance Action');
-- SELECT im_category_new(92290, 'Delete', 'Intranet Attendance Action');



-----------------------------------------------------------
-- Permissions & Privileges
-----------------------------------------------------------

select acs_privilege__create_privilege('view_attendances','View Attendances','');
select acs_privilege__add_child('admin', 'view_attendances');

select acs_privilege__create_privilege('view_attendances_all','View all Attendances','');
select acs_privilege__add_child('admin', 'view_attendances_all');

select acs_privilege__create_privilege('edit_attendances_all','Edit all Attendances','');
select acs_privilege__add_child('admin', 'edit_attendances_all');

select acs_privilege__create_privilege('add_attendances','Add new Attendances','');
select acs_privilege__add_child('admin', 'add_attendances');


select im_priv_create('view_attendances', 'Employees');

select im_priv_create('view_attendances_all', 'Senior Managers');
select im_priv_create('view_attendances_all', 'Accounting');

select im_priv_create('edit_attendances_all', 'Senior Managers');
select im_priv_create('edit_attendances_all', 'Accounting');

select im_priv_create('add_attendances', 'Employees');





-- ------------------------------------------------------------
-- Attendance Constructor/Destructor
-- ------------------------------------------------------------

create or replace function im_attendance_interval__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, timestamptz, timestamptz, integer, integer, varchar
) returns integer as $$
DECLARE
	p_attendance_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date		alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_attendance_user_id    alias for $7;
	p_attendance_start      alias for $8;
	p_attendance_end        alias for $9;

	p_attendance_status_id	alias for $10;
	p_attendance_type_id	alias for $11;
	p_attendance_note       alias for $12;

	v_attendance_id	integer;
BEGIN
	v_attendance_id := acs_object__new (
		p_attendance_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);
	insert into im_attendance_intervals (
		attendance_id, attendance_user_id, attendance_start, attendance_end,
		attendance_status_id, attendance_type_id, attendance_note
	) values (
		v_attendance_id, p_attendance_user_id, p_attendance_start, p_attendance_end,
		p_attendance_status_id, p_attendance_type_id, p_attendance_note
	);
	return v_attendance_id;
end;$$ language 'plpgsql';


create or replace function im_attendance_interval__delete (integer) 
returns integer as $$
DECLARE
	v_attendance_id		alias for $1;
	row				RECORD;
BEGIN
	-- Delete the im_attendance_intervals interval associated with the id
	delete from 	im_attendance_intervals
	where		attendance_id = v_attendance_id;

	-- Delete all the priviledges
	delete from 	acs_permissions
	where		object_id = v_attendance_id;

	PERFORM	acs_object__delete(v_attendance_id);

	return 0;
end;$$ language 'plpgsql';


create or replace function im_attendance_interval__name (integer) 
returns varchar as $$
DECLARE
	v_attendance_id	alias for $1;
	v_name		varchar;
BEGIN
	select	im_category_from_id(coalesce(attendance_type_id, 92100)) ||
		' #' || attendance_id ||
		' of ' || im_name_from_user_id(attendance_user_id) ||
		' from ' || to_char(attendance_start, 'YYYY-MM-DD HH24-MI-SS') ||
		coalesce(' to ' || to_char(attendance_end, 'YYYY-MM-DD HH24-MI-SS'), '')
	into	v_name
	from	im_attendance_intervals
	where	attendance_id = v_attendance_id;

	return v_name;
end;$$ language 'plpgsql';

