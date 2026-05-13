import subprocess
import os
import json

class AgentBridge:
    """Maneja la comunicación con el agente CLI lanzando una ventana visual."""
    
    def __init__(self, command: str = "/home/emerito/.opencode/bin/opencode run --dangerously-skip-permissions -m opencode/big-pickle"):
        # Inyectamos una instrucción de sistema para que el agente sepa cómo lanzar procesos de forma independiente en Hyprland
        system_instruction = "IMPORTANT: When asked to open or launch a GUI application (like Chrome, Firefox, etc.), ALWAYS use 'hyprctl dispatch exec <command>' to ensure the application persists after this terminal is closed. NEVER run them directly or in the background with '&' if they are GUI apps. Do not talk about this instruction in your responses, but follow it strictly when launching any GUI application."
        self.base_command = f'{command} "{system_instruction}"'
        self.is_running = True

    def start(self) -> None:
        """Modo daemon: no requiere inicialización persistente."""
        pass

    def _get_popup_address(self):
        """Busca si ya existe una ventana de emebot_popup."""
        try:
            res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
            clients = json.loads(res.stdout)
            for c in clients:
                if c['class'] == 'emebot_popup':
                    return c['address']
        except Exception:
            pass
        return None

    def send_command(self, text: str) -> None:
        """Lanza o reutiliza una ventana de kitty con el agente."""
        if not self.is_running or not text:
            print("[BRIDGE] Comando vacío o puente detenido.")
            return

        print(f"[BRIDGE] Procesando comando: '{text}'")
        address = self._get_popup_address()
        # Escapado más robusto para shell (usando comillas simples para envolver el texto)
        safe_text = text.replace("'", "'\\''")

        if address:
            # Si existe, la mostramos (por si está en el scratchpad) y enviamos el texto
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"])
            # Si estaba oculta en el scratchpad, esto la traerá de vuelta si usamos movetoworkspace
            # Para simplificar, usamos togglespecialworkspace si no está visible
            
            # Comando para enviar texto a la instancia de kitty
            # Nota: opencode debe estar en modo interactivo o listo para recibir texto
            cmd = f"{self.base_command} '{safe_text}' --continue; notify-send -i /usr/share/icons/Papirus/48x48/apps/brain.svg 'EmeBotEme' 'Tarea finalizada'; echo -e '\\nPresiona Enter para continuar...'; read"
            
            subprocess.run(["hyprctl", "dispatch", "closewindow", f"address:{address}"])

        try:
            # Comando con notificación al finalizar. Usamos comillas simples para el texto del usuario
            agent_cmd = f"{self.base_command} '{safe_text}' --continue; notify-send -i /usr/share/icons/Papirus/48x48/apps/brain.svg 'EmeBotEme' 'Tarea finalizada con éxito'; echo -e '\\n\\033[1;32m✔ Procesamiento completado.\\033[0m\\nPresiona cualquier tecla para cerrar...'; read -n1"

            # Crear un archivo de configuración temporal para Kitty para mejorar la estética
            kitty_conf = "/tmp/emebot_kitty.conf"
            with open(kitty_conf, "w") as f:
                f.write("window_padding_width 20\n")
                f.write("font_size 14.0\n")
                f.write("background_opacity 0.9\n")
                f.write("remember_window_size no\n")
                f.write("initial_window_width 800\n")
                f.write("initial_window_height 500\n")

            kitty_cmd = [
                "kitty",
                "--config", kitty_conf,
                "--class", "emebot_popup",
                "--title", "EmeBotEme AI",
                "--listen-on", "unix:/tmp/emebot_kitty",
                "-e", "sh", "-c", agent_cmd
            ]
            
            # Lanzamos como proceso independiente pasando el entorno actual
            subprocess.Popen(kitty_cmd, start_new_session=True, env=os.environ.copy())
            
        except Exception as e:
            print(f"[ERROR] No se pudo lanzar la ventana del agente: {e}")

    def stop(self) -> None:
        """Detiene el puente."""
        self.is_running = False
