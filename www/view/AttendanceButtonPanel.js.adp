/* 
 * /intranet-attendance-management/www/view/AttendanceButtonPanel.js
 *
 * Copyright (C) 2021-2023 ]project-open[
 * All rights reserved. Please see
 * https://www.project-open.com/license/sencha/ for details.
 *
 * Attendance interval is time that an employee is present
 * "at work".
 */

Ext.define('AttendanceManagement.view.AttendanceButtonPanel', {
    extend: 'Ext.panel.Panel',
    alias: 'ganttButtonPanel',
    layout: 'border',
    defaults: {
        collapsible: true,
        split: true,
        bodyPadding: 0
    },
    tbar: [{
	xtype: 'tbspacer', width: 0
    }, {
        icon: '/intranet/images/navbar_default/clock_go.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Start_work "Start&nbsp;work"] %>',
        id: 'buttonStartWork',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/cup_go.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Start_break "Start&nbsp;break"] %>',
        id: 'buttonStartBreak',
        disabled: false
    }, {
	xtype: 'tbspacer', width: 0
    }, {
        icon: '/intranet/images/navbar_default/stop.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Stop "Stop&nbsp;logging"] %>',
        id: 'buttonStop',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/delete.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Delete "Delete&nbsp;entry"] %>',
        id: 'buttonDelete',
        disabled: false
    }, {
	xtype: 'tbspacer', width: 20
    }, {
        icon: '/intranet/images/navbar_default/arrow_left.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Previous_week "Previous&nbsp;week"] %>',
        id: 'buttonPreviousWeek',
        disabled: false
    }, {
        xtype: 'label',
	text: 'current week',
	id: 'labelWeek'
    }, {
        icon: '/intranet/images/navbar_default/arrow_right.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Next_week "Next&nbsp;week"] %>',
        id: 'buttonNextWeek',
        disabled: false
    }, {
	xtype: 'tbspacer', width: 20
    }]
});
