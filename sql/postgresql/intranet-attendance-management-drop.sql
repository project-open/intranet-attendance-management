-- /packages/intranet-attendance-management/sql/postgres/intranet-attendance-management-drop.sql
--
-- Copyright (C) 2021 ]project-open[
--
-- @author      frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-attendance-management');
select  im_menu__del_module('intranet-attendance-management');

delete from im_biz_object_urls where object_type = 'im_attendance_interval'

-- Drop table etc
drop table if exists im_attendance_intervals;
drop sequence if exists im_attendance_intervals_seq;

-- Drop object type
delete from acs_object_type_tables where object_type = 'im_attendance_interval';
SELECT acs_object_type__drop_type ('im_attendance_interval', 't');

