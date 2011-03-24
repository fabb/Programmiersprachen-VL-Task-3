3. �bungsaufgabe
===============

�berblick:
----------
Entwickeln Sie ein Workflow-Werkzeug zur Bearbeitung von Dateien nach einem festlegbaren Schema in einer dynamisch typisierten Scripting-Sprache wie Perl, PHP, Ruby, ...

Workflow-Werkzeug:
------------------
Das Werkzeug soll einen in einer Konfigurationsdatei festgelegten Workflow abarbeiten und dabei vorgegebene Programme auf Dateien anwenden, die einem vorgegebenen Muster entsprechen.

Folgende Aktionen sollen in der Konfigurationsdatei festlegbar sein:

* Eine *primitive Aktion* ruft ein Programm auf bzw. setzt ein (Unix-)Kommando ab, m�glicherweise mit Argumenten, die auch benannte Teile eines Musters enthalten. Die Ausf�hrung einer primitiven Aktion ist erfolgreich, wenn der Programmaufruf mit dem Wert 0 terminiert, sonst ist sie gescheitert. Alle anderen (nicht-primitiven) Aktionen erweitern oder kombinieren einfachere Aktionen.

* Eine *Sequenz* besteht aus mehreren Aktionen, die in der gegebenen Reihenfolge hintereinander ausgef�hrt werden. Wenn eine Ausf�hrung einer Aktion scheitert, werden die weiteren Aktionen nicht mehr ausgef�hrt, und die Ausf�hrung der Sequenz gilt als gescheitert, sonst als erfolgreich.

* Eine *Mengen-Aktion* besteht aus einem Muster und einer Aktion. Das Muster spezifiziert eine Menge von Dateien (siehe unten), und die Aktion wird f�r jede Datei in der Menge in beliebiger Reihenfolge einmal ausgef�hrt. Falls eine Ausf�hrung der Aktion scheitert, wird die Aktion auf keine weitere Dateien mehr angewandt, und die Ausf�hrung der Mengen-Aktion gilt als gescheitert.

* Eine *Schleife* beinhaltet eine Aktion, die st�ndig wiederholt ausgef�hrt wird, solange die Ausf�hrung der Aktion erfolgreich ist und dabei zumindest eine primitive Aktion ausgef�hrt wird. Die Ausf�hrung einer Schleife terminiert nur dann erfolgreich, wenn die Aktion nur aus Mengen-Aktionen besteht, deren Muster in einem Durchlauf keine Dateien spezifizieren.

* Eine *Fehlerbehandlung* kombiniert zwei Aktionen A und B. Falls die Ausf�hrung von A erfolgreich ist, ist auch die Ausf�hrung der ganzen Fehlerbehandlung erfolgreich, und B wird nicht ausgef�hrt. Falls aber die Ausf�hrung von A scheitert, wird B ausgef�hrt, und die Fehlerbehandlung ist genau dann erfolgreich, wenn die Ausf�hrung von B erfolgreich ist.

Muster in Mengen-Aktionen sollen Pfade im Dateisystem darstellen, die benannte Wildcards enthalten k�nnen. Beispielsweise k�nnte `Bilder/2011-04-[tag]/[name].jpg` f�r alle Dateien entsprechend dem Unix-Pfad `Bilder/2011-04-*/*.jpg` stehen, wobei `[[tag]]` und `[[name]]` im Argument einer primitiven Aktion oder im Muster einer anderen enthaltenen Mengen-Aktion f�r die beiden Zeichenketten stehen, die im Unix-Pfad durch die beiden Wildcards (`*`) dargestellt werden. Die genaue Syntax und Semantik f�r Muster (so wie in diesem Beispiel oder anders) sollen Sie selbst festlegen, genauso wie die Syntax zur Festlegung von Workflows in der Konfigurationsdatei.

Ein Workflow ist in gewisser Weise ein einfaches Programm mit bedingten Anweisungen und Schleifen. Ihre Aufgabe besteht also darin, die Syntax und einige semantische Details der Sprache festzulegen und einen einfachen Interpreter daf�r zu implementieren. Bitte halten Sie die Syntax so einfach, dass die Aufgabe leicht ohne spezielle Compilerbau-Werkzeuge l�sbar ist.

Anwendungsbeispiele:
-------------------
Obige Beschreibung des Werkzeugs ist abstrakt gehalten. Hier werden einige Anwendungsbeispiele angerissen, die den Zweck klarer umschreiben und als Testf�lle dienen k�nnen.

* Das Werkzeug �berpr�ft, ob neue Dateien in einem Eingangs-Ordner erstellt wurden, verschiebt Dateien mit bestimmten Endungen im Namen in andere Ordner, und f�hrt ein Protokoll �ber verschobene Dateien.

* Angenommen, Sie wollen mehrere Texte, die Sie per Mail bekommen und in einem Verzeichnis abgelegt haben, zu einer Einheit zusammenf�gen. Das Werkzeug kann Sie dabei unterst�tzen, indem es aus jeder Datei mit Hilfe eines Skripts den Header entfernt, die ge�nderten Dateien zu einer gro�en Datei zusammenfasst und diese Datei in einem Editor f�r weitere Korrekturen �ffnet.

* Das Werkzeug erstellt f�r alle Bilder in einem Ordner je zwei Kopien in unterschiedlichen Gr��en in anderen Ordnern und f�gt f�r jedes Bild eine passende Zeile in eine bestehende HTML-Datei ein, sodass die Bilder in einer �bersichtstabelle und im Detail auf einem Web-Browser betrachtet werden k�nnen.
