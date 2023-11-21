ToDo
====


Editor Portlet
==============

- Implement "<- current week ->"
- Link zu Monatszeiterfassung
- Anzeige Gleitzeitkonto
- Anzeige Urlaubskonto
- Localization to other languages (German)
- Add parameters for min and max durations of intervals/breaks
- Check consistency: Last entry every day should have been Work
- Consistency checker: There should be no open entries in the past.
- Consistency checker: Check for multiple open issues only today.

Bugs

- ButtonStop on next day sets date of next day,
  leading to interval > 12h
- Write out error message when end_time < start_time
- Handle error message if start=end, and object
  destroy() fails
- Creating a new entry, it's created at the top, not at
  the bottom of the list. -> Add attendance_start with date.
- Sort order:
  There is an issue with the GMT+1 time zone,
  so just cutting off the TZ in a string is wrong
- Manually deleting the end-time of an entry doesn't save.
- Adding a new break tries to add two items
- Deleting an item issues two DELETE server operations



Timesheet Monthly Calendar
==========================

- Farbe rot/grün in Abhängigkeit von 8h 
- Vergleich Anwesenheit vs. Soll Anwesenheit
	- Monatlich mit Berechnung der Soll-Anwesenheit
- Soll Anwesenheit = 8h/Tag * Verfügbarkeit
- Klick auf Anwesenheits-Link führt zu Widget, 
  mit der richtigen Woche "aufgeklappt"



Report Pausenzeiten
===================

- Filter:
	- User
	- Abteilung
	- Zeitraum
- Anzeige:
	- Pausenzeiten
	- Mindestens 15 pro Pause
	- Ab 6h verpflichtend 30min Pause
	- Ab 9h 45min Pause
	- Pro Monat (31 Spalten oben) und pro User (links)
	- Jede Zelle:
		- Gesamtzeit Pausen
		- Rot wenn Business-Regeln verletzt (oben)
		  mit Kommentar warum
		- 



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
- Bug: Format for GridPanel date column is different from renderer
- Bug: Creating a new item doesn't save time



Timesheet Monthly Calendar:

- Pro Tag zusätzlicher Eintrag: Anwesenheit

