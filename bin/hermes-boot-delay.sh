#!/bin/sh
# Colchón de arranque del gateway de Hermes.
#
# En un arranque en frío espera 60 s antes de lanzar el gateway (y con él el
# ticker del cron), para que el escritorio y los servicios de sesión se
# asienten antes de que empiecen los jobs pesados. En un reinicio del propio
# servicio (uptime ya alto) no espera nada.
up=$(cut -d. -f1 /proc/uptime)
if [ "$up" -lt 300 ]; then
    sleep 60
fi
exit 0
