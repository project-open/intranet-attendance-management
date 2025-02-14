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

    current_user_id: null,                         // Set during initialization
    curren_user_name: null,                        // Set during initialization

    defaults: {
        collapsible: true,
        split: true,
        bodyPadding: 0
    },
    tbar: [{
        xtype: 'tbspacer', width: 0
    }, {
        icon: '/intranet/images/navbar_default/clock_go.png',
        tooltip: '<nobr><%= [lang::message::lookup "" intranet-attendance-management.Button_text_Start_work "Start work"] %></nobr>',
        id: 'buttonStartWork',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/cup_go.png',
        tooltip: '<nobr><%= [lang::message::lookup "" intranet-attendance-management.Button_text_Start_break "Start break"] %></nobr>',
        id: 'buttonStartBreak',
        disabled: false
    }, {
        xtype: 'tbspacer', width: 0
    }, {
        icon: '/intranet/images/navbar_default/stop.png',
        tooltip: '<nobr><%= [lang::message::lookup "" intranet-attendance-management.Button_text_Stop "Stop logging"] %></nobr>',
        id: 'buttonStop',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/add.png',
        tooltip: '<nobr><%= [lang::message::lookup "" intranet-attendance-management.Button_text_Add "Add entry"] %></nobr>',
        id: 'buttonAdd',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/delete.png',
        tooltip: '<nobr><%= [lang::message::lookup "" intranet-attendance-management.Button_text_Delete "Delete entry"] %></nobr>',
        id: 'buttonDelete',
        disabled: false
    }, {
        xtype: 'tbspacer', width: 20
    }, {
        icon: '/intranet/images/navbar_default/arrow_left.png',
        tooltip: '<nobr><%= [lang::message::lookup "" intranet-attendance-management.Button_text_Previous_week "Previous week"] %></nobr>',
        id: 'buttonPreviousWeek',
        disabled: false
    }, {
        xtype: 'label',
        text: 'current week',
        id: 'labelWeek'
    }, {
        icon: '/intranet/images/navbar_default/arrow_right.png',
        tooltip: '<nobr><%= [lang::message::lookup "" intranet-attendance-management.Button_text_Next_week "Next week"] %></nobr>',
        id: 'buttonNextWeek',
        disabled: false
    }, '->', {
	// A label with the name of a user when the portlet is called with user_id_from_search
        xtype: 'label',
        text: 'not yet computed',
        id: 'currentusername',
        listeners: {
            beforerender: function(label, eOpts) { 
                var toolbar = label.ownerCt;
                var buttonPanel = toolbar.ownerCt;
                var current_user_id = buttonPanel.current_user_id;

		if (current_user_id != <%= [ad_conn user_id] %>) {
                    var current_user_name = buttonPanel.current_user_name;
                    label.setText(current_user_name);
		} else {
                    label.setText("");
		}
            }
        }
    }, {
        xtype: 'tbspacer', width: 20
    },	
    {
	text: 'Help',
	icon: gifPath+'help.png',
	menu: Ext.create('PO.view.menu.HelpMenu', {
            id: 'helpMenu',
            debug: false,
            style: {overflow: 'visible'},						// For the Combo popup
            store: Ext.create('Ext.data.Store', { fields: ['text', 'url'], data: [
		{text: 'Attendance Management', url: 'https://www.project-open.net/en/package-intranet-attendance-management'}
            ]})
	})
    }]
});

