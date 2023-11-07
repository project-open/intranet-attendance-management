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
        icon: '/intranet/images/navbar_default/clock_go.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Start_logging "Start logging"] %>',
        id: 'buttonStartLogging',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/clock_stop.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Stop_logging "Stop logging and save"] %>',
        id: 'buttonStopLogging',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/clock_delete.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Cancel_logging "Cancel logging"] %>',
        id: 'buttonCancelLogging',
        disabled: true
    }, {
        icon: '/intranet/images/navbar_default/add.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Manual_logging "Manual logging"] %>',
        id: 'buttonManualLogging',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/delete.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Delete_logging "Delete entry"] %>',
        id: 'buttonDeleteLogging',
        disabled: false
    }]
});

