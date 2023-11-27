/* 
 * /intranet-attendance-management/www/controller/AttendanceController.js
 *
 * Copyright (C) 2021-2023 ]project-open[
 * All rights reserved. Please see
 * https://www.project-open.com/license/sencha/ for details.
 *
 * Controller for interaction between buttons and grid
 */
Ext.define('AttendanceManagement.controller.ResizeController', {
    extend: 'Ext.app.Controller',

    // Variables
    debug: true,

    attendanceButtonPanel: null,                                         // Outermost panel

    // Setup the various listeners so that everything gets concentrated here on this controller.
    init: function() {
        var me = this;
        if (me.debug) { console.log('ResizeController: init'); }
    
        // Handle collapsable side menu
        var sideBarTab = Ext.get('sideBarTab');
        sideBarTab.on('click', me.onSideBarResize, me);
        Ext.EventManager.onWindowResize(me.onWindowsResize, me);         // Deal with resizing the main window
        
        return this;
    },
    
    /**
     * The windows as a whole was resized
     */
    onWindowsResize: function(width, height) {
        console.log('AttendanceController.onWindowResize');
        var me = this;
        var sideBar = Ext.get('sidebar');                                // ]po[ left side bar component
        var sideBarSize = sideBar.getSize();
        me.onResize(sideBarSize.width);
    },

    /**
     * The ]po[ left sideBar was resized
     */
    onSideBarResize: function(event, el, config) {
        console.log('AttendanceController.onSideBarResize');
        var me = this;
        var sideBar = Ext.get('sidebar');                                // ]po[ left side bar component
        var sideBarSize = sideBar.getSize();

        // We get the event _before_ the sideBar has changed it's size.
        // So we actually need to the the oposite of the sidebar size:
        if (sideBarSize.width > 100) {
            sideBarSize.width = -5;
        } else {
            sideBarSize.width = 245;
        }

        me.onResize(sideBarSize.width);
    },

    /**
     * Generic resizing function, called with the target width of the sideBar
     */
    onResize: function(sideBarWidth) {
        var me = this;
        console.log('AttendanceController.onResize: '+sideBarWidth);

        var screenSize = Ext.getBody().getViewSize();
        var height = me.attendanceButtonPanel.getSize().height;
        var width = screenSize.width - sideBarWidth - 75;
        me.attendanceButtonPanel.setSize(width, height);
    }
    
});

