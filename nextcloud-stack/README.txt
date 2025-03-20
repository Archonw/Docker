Mit diesen Scripts kann unter Debian-basierten Distributionen eine Nextcloud-Docker Installation ausgeführt werden

Vorgehensweise:

Das erste Script welches ausgeführt werden muss ist:
1_nextcloud_stack_installer.sh

Ist dieses erfolgreich durchgelaufen kommt am Ende eine Zusammenfassung mit den nötigen Daten, die im nächsten Schritt in Nextcloud-Web Oberfläche bei der Erst-Einrichtung eingegeben werden müssen.
Nachdem die Erst-Einrichtung erfolgt ist, und man erfolgreich mit seinem ersten Konto in der Nextcloud angemeldet ist, kann jetzt das zweite Script ausgeführt werden.
2_after-first-setup.sh

Das zweite Script sorgt für ein paar wichtige Einstellungen, die noch in der Nextcloud vorgenommen werden müssen.
Navigiert man im Anschluss in seinem Nextcloud-Konto zu der Administrationseinstellungen und dort zur üBersicht, so sollten nur noch wenige Fehlermeldungen zu sehene sein.

Die Meldung zur E-Mail-Serverkonfiguration lässt sich beheben, in dem in in den Administrationseinstellungen unter Grundeinstellungen den E-Mail-Server einstellt.
