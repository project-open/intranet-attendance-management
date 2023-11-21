ToDo
====


## Editor Portlet
- Link zu Monatszeiterfassung
- Anzeige Gleitzeitkonto
- Anzeige Urlaubskonto

### Bugs

- Doesn't save time of new entry
- Write out error message when end_time < start_time
- Handle error message if start=end, and object
  destroy() fails
- Creating a new entry, it's created at the top, not at
  the bottom of the list. -> Add attendance_start with date.
- Sort order:
  There is an issue with the GMT+1 time zone,
  so just cutting off the TZ in a string is wrong
- Manually deleting the end-time of an entry doesn't save.



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


## Editor portlet
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


Timesheet Monthly Calendar:
- Pro Tag zusätzlicher Eintrag: Anwesenheit


## Done Bugs
- Format for GridPanel date column is different from renderer

