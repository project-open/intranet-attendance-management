ToDo
====


Editor Portlet
==============

ToDo: Features

ToDo: Optional Features
- Add parameters for min and max durations of intervals/breaks?
Bugs:
- Entering Start Time of "8:00" (without leading 0 before the 8)
  doesn't save, but doesn't produce an error message.


Timesheet Monthly Calendar
==========================

ToDo: Features
- Vergleich Anwesenheit vs. Soll Anwesenheit
  - Monatlich mit Berechnung der Soll-Anwesenheit
  - Calculate monthly required presence including
    absences
- Localization of Work, Break etc.


Report Pausenzeiten
===================

ToDo: Features

- Drill-down per user:
  - Open with filter per user + LoD++
  - Try to integrate timesheet hours into "left dimension"
  - Business Logic Checks:
	- Mindestens 15 pro Pause
	- Ab 6h verpflichtend 30min Pause
	- Ab 9h 45min Pause
	- Jede Zelle:
		- Gesamtzeit Pausen
		- Rot wenn Business-Regeln verletzt (oben)
		  mit Kommentar warum
	- Used to manually calculate working time per month




Done
====

Editor portlet:

- At the homepage
- Without reference to projects / without left tree
- Column end time can be left empty
- Allow uncompleted entry (no end date) to be saved to disk
- Add column with attendance type
- Buttons:
	- Kommen:
		- Neuer Eintrag mit aktueller Zeit
		- ohne gehen
		- Typ: Anwesenheit
	- Anfang Pause:
		- Wie "Kommen" nur Type: Pause
	- Gehen:
		- Letzter Eintrag muss Anwesenheit gewesen sein, mit "Gehen" leer,
		  sonst ignorieren
	- Ende Pause:
		- Ähnlich wie "Gehen"
- Implement "<- current week ->"
- Klick auf Anwesenheits-Link führt zu Widget, 
  mit der richtigen Woche "aufgeklappt"
- Link zu Monatszeiterfassung
- Anzeige Gleitzeitkonto
- Anzeige Urlaubskonto
- Two digit precision on Duration
- Cancel: Consistency checker: Last entry every day should have been Work?
- Consistency checker: There should be no open entries in the past?
  => Handle in report (globally)
  => User can check himself in the monthly calendar view
- Done: Consistency checker: Check for multiple open issues only today?
- (+) and (-) buttons in previous weeks
- (+) and (-) buttons in future weeks
- Clarify: What happens when editing a date, so that the
  attendance moves to a different week?
- Localization to German
  - Localize Attendance Type Store
- (+) button: Switch to edit mode


- Bug: Format for GridPanel date column is different from renderer
- Bug: Creating a new item doesn't save time
- Bug: Shows attendances from any user
- Bug:Adding a new break tries to add two items
- Bug:Deleting an item issues two DELETE server operations
- Bug: Sort order:
  There is an issue with the GMT+1 time zone,
  so just cutting off the TZ in a string is wrong
- Bug: Creating a new entry, it's created at the top, not at
  the bottom of the list. -> Add attendance_start with date.
- Bug: ButtonStop on next day sets date of next day,
  leading to interval > 12h
- Bug: "Stopping" an entry in the past leads to >24h entries
- Bug: Write out error message when end_time < start_time
- Bug: Handle error message if start=end, and object destroy() fails
- Bug: selectCurrentWeek() needs to execute the addItem
  in the after-load callback so that it gets loaded.
  (or with a delay?)
  Alternative: We just disable the main buttons when not
  showing the current week. Entries in the last weeks
  can be modified manually.
- Bug: Manually deleting the end-time of an entry doesn't save.
- Editing end-time leads to entry disappearing


Timesheet Monthly Calendar:

- Pro Tag zusätzlicher Eintrag: Anwesenheit
- Farbe rot/grün in Abhängigkeit von 8h 
- Soll Anwesenheit = 8h/Tag * Verfügbarkeit


Report Pausenzeiten

- Filter:
	- User
	- Abteilung
	- Zeitraum
- Anzeige:
	- Pausenzeiten
	- Anwesenheitszeiten
	- Pro Monat (31 Spalten oben) und pro User (links)
	- Jede Zelle:
		- Gesamtzeit Pausen
		- Rot wenn Business-Regeln verletzt (oben)
		  mit Kommentar warum
	- Used to manually calculate working time per month
- Translated to German

