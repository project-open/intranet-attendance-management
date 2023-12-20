-- /packages/intranet-attendance-management/sql/postgres/testcases.sql
--
-- Copyright (C) 2014-2023 ]project-open[
--
-- @author frank.bergmann@project-open.com

-- 53574 = Bruno Kesel, 92020 = active, 92100 = work

-- work: 9:00 - 12:00, break: 12:01 - 13:00, work: 13:00 - 17:00
select im_attendance_interval__new (null, 'im_attendance_interval', now(), 0, '0.0.0.0', null, 53574, '2023-12-18  9:00', '2023-12-18 12:00', 92020, 92100, 'perfect day');
select im_attendance_interval__new (null, 'im_attendance_interval', now(), 0, '0.0.0.0', null, 53574, '2023-12-18 12:01', '2023-12-18 13:00', 92020, 92110, null);
select im_attendance_interval__new (null, 'im_attendance_interval', now(), 0, '0.0.0.0', null, 53574, '2023-12-18 13:00', '2023-12-18 17:00', 92020, 92100, null);
insert into im_hours (user_id, project_id, day, hours) values (53574, (select min(project_id) from im_projects where parent_id is null), '2023-12-18', 8.0);

select im_attendance_interval__new (null, 'im_attendance_interval', now(), 0, '0.0.0.0', null, 53574, '2023-12-18  9:00', '2023-12-18 12:00', 92020, 92100, 'perfect day');
select im_attendance_interval__new (null, 'im_attendance_interval', now(), 0, '0.0.0.0', null, 53574, '2023-12-18 12:01', '2023-12-18 13:00', 92020, 92110, null);
select im_attendance_interval__new (null, 'im_attendance_interval', now(), 0, '0.0.0.0', null, 53574, '2023-12-18 13:00', '2023-12-18 17:00', 92020, 92100, null);




-- Create a vacation for 2023-12-20
select im_user_absence__new(
	null, 'im_user_absence', now(), 0, '0.0.0.0', null,
	'Vacation',
	53574, -- Bruno Kesel
	'2023-12-20',
	'2023-12-20',
	16004, -- status active
	5000, -- type vacation
	null, -- description,
	null -- contact info
);	
