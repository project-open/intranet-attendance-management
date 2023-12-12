ToDo
====


Editor Portlet
--------------

ToDo: Optional Features:

- [ ] Add parameters for min and max durations of intervals/breaks?


Timesheet Monthly Calendar
--------------------------

ToDo: Features:

- [ ] Vergleich Anwesenheit vs. Soll Anwesenheit
	- [ ] Monatlich mit Berechnung der Soll-Anwesenheit
	- [ ] Calculate monthly required presence including
	  absences
- [ ] Localization of Work, Break etc.
- [ ] Consistency check


Report Pausenzeiten
-------------------

ToDo: Features

- [ ] Business Logic Checks:
	- [ ] Ab 6h verpflichtend 30min Pause
	- [ ] Ab 9h 45min Pause


Consistency Checker
-------------------

Shared between Attendance Report and Monthly View

- [ ] Rules:
	- [ ] Overlap of attendances
	- [ ] Short break
	- [ ] Minimum breaks 2x
	- [ ] Comparison between timesheet hours and attendance
	- [ ] No night hours(?)

- [ ] Build test-case




Done
====

Editor portlet
--------------

- [x] At the homepage
- [x] Without reference to projects / without left tree
- [x] Column end time can be left empty
- [x] Allow uncompleted entry (no end date) to be saved to disk
- [x] Add column with attendance type
- [x] Buttons:
	- [x] Kommen:
		- [x] Neuer Eintrag mit aktueller Zeit
		- [x] ohne gehen
		- [x] Typ: Anwesenheit
	- [x] Anfang Pause:
		- [x] Wie "Kommen" nur Type: Pause
	- [x] Gehen:
		- [x] Letzter Eintrag muss Anwesenheit gewesen sein, mit "Gehen" leer,
		  sonst ignorieren
	- [x] Ende Pause:
		- [x] Ähnlich wie "Gehen"
- [x] Implement "<- current week ->"
- [x] Klick auf Anwesenheits-Link führt zu Widget, 
  mit der richtigen Woche "aufgeklappt"
- [x] Link zu Monatszeiterfassung
- [x] Anzeige Gleitzeitkonto
- [x] Anzeige Urlaubskonto
- [x] Two digit precision on Duration
- [x] Cancel: Consistency checker: Last entry every day should have been Work?
- [x] Consistency checker: There should be no open entries in the past?
  => Handle in report (globally)
  => User can check himself in the monthly calendar view
- [x] Done: Consistency checker: Check for multiple open issues only today?
- [x] (+) and (-) buttons in previous weeks
- [x] (+) and (-) buttons in future weeks
- [x] Clarify: What happens when editing a date, so that the
  attendance moves to a different week?
- [x] Localization to German
  - [x] Localize Attendance Type Store
- [x] (+) button: Switch to edit mode


- [x] Bug: Format for GridPanel date column is different from renderer
- [x] Bug: Creating a new item doesn't save time
- [x] Bug: Shows attendances from any user
- [x] Bug:Adding a new break tries to add two items
- [x] Bug:Deleting an item issues two DELETE server operations
- [x] Bug: Sort order:
  There is an issue with the GMT+1 time zone,
  so just cutting off the TZ in a string is wrong
- [x] Bug: Creating a new entry, it's created at the top, not at
  the bottom of the list. -> Add attendance_start with date.
- [x] Bug: ButtonStop on next day sets date of next day,
  leading to interval > 12h
- [x] Bug: "Stopping" an entry in the past leads to >24h entries
- [x] Bug: Write out error message when end_time < start_time
- [x] Bug: Handle error message if start=end, and object destroy() fails
- [x] Bug: selectCurrentWeek() needs to execute the addItem
  in the after-load callback so that it gets loaded.
  (or with a delay?)
  Alternative: We just disable the main buttons when not
  showing the current week. Entries in the last weeks
  can be modified manually.
- [x] Bug: Manually deleting the end-time of an entry doesn't save.
- [x] Bug: Editing end-time leads to entry disappearing
- [x] Bug: Entering Start Time of "8:00" (without leading 0 before the 8)
  doesn't save, but doesn't produce an error message.


Timesheet Monthly Calendar
--------------------------

- [x] Pro Tag zusätzlicher Eintrag: Anwesenheit
- [x] Farbe rot/grün in Abhängigkeit von 8h 
- [x] Soll Anwesenheit = 8h/Tag * Verfügbarkeit


Report Pausenzeiten
-------------------

- [x] Integrate timesheet hours into "left dimension"
- [x] Add sums of timesheet hours to various lines
- [x] Drill-down per user:
  - [x] Open with filter per user + LoD++
- [x] Filter:
	- [x] User
	- [x] Abteilung
	- [x] Zeitraum
- [x] Anzeige:
	- [x] Pausenzeiten
	- [x] Anwesenheitszeiten
	- [x] Pro Monat (31 Spalten oben) und pro User (links)
	- [x] Jede Zelle:
		- [x] Gesamtzeit Pausen
		- [x] Rot wenn Business-Regeln verletzt (oben)
		  mit Kommentar warum
	- [x] Used to manually calculate working time per month
- [x] Translated to German
- [x] Business Logic Checks:
	- [x] Mindestens 15 pro Pause
	- [x] Jede Zelle:
		- [x] Gesamtzeit Pausen
		- [x] Rot wenn Business-Regeln verletzt (oben)
		  mit Kommentar warum
	- [x] Used to manually calculate working time per month


