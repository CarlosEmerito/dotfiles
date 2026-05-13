import subprocess
import os
import json

class AgentBridge:
    """
    Gestiona la persistencia de la conversación y la interfaz de usuario.
    Utiliza el motor nativo de sesiones de Opencode para mantener el estado
    sin depender de procesos externos como TMUX.
    """
    
    def __init__(self, command: str, system_prompt: str, model: str = "opencode/deepseek-v4-flash-free"):
        self.raw_command = command
        self.system_prompt = system_prompt
        self.model = model
        self.is_running = True
        self.session_file = os.path.expanduser("~/.config/emebot_session_id")
        self.session_id = self._load_session_id()

    def _load_session_id(self):
        """Carga el ID de sesión persistente desde el disco si existe."""
        if os.path.exists(self.session_file):
            with open(self.session_file, "r") as f:
                return f.read().strip()
        return None

    def _save_session_id(self, session_id):
        """Guarda el ID de sesión para futuras interacciones."""
        os.makedirs(os.path.dirname(self.session_file), exist_ok=True)
        with open(self.session_file, "w") as f:
            f.write(session_id)
        self.session_id = session_id

    def _ensure_session(self):
        """Garantiza que tenemos un ID de sesión válido, creándolo si es necesario."""
        if self.session_id:
            return self.session_id
        
        # Si no hay sesión, creamos una silenciosamente
        try:
            cmd = [
                self.raw_command, "run", "System Init", 
                "--title", "EmeBotEme Voice Session", 
                "--format", "json",
                "--model", self.model
            ]
            res = subprocess.run(cmd, capture_output=True, text=True)
            # Intentamos parsear la primera línea o buscar el sessionID en el JSON
            for line in res.stdout.splitlines():
                try:
                    data = json.loads(line)
                    if "sessionID" in data:
                        self._save_session_id(data["sessionID"])
                        return data["sessionID"]
                except json.JSONDecodeError:
                    continue
        except Exception as e:
            print(f"[ERROR] No se pudo inicializar la sesión de Opencode: {e}")
        
        return None

    def start(self) -> None:
        """No requiere inicialización persistente (TMUX eliminado)."""
        pass

    def _get_popup_address(self):
        """Localiza la dirección de la ventana emergente en Hyprland."""
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
        """Lanza la interfaz Kitty con el comando Opencode aislado."""
        if not self.is_running or not text:
            return

        # Asegurar que tenemos una sesión antes de lanzar la ventana
        session_id = self._ensure_session()

        # Limpieza de ventanas previas
        address = self._get_popup_address()
        if address:
            subprocess.run(["hyprctl", "dispatch", "closewindow", f"address:{address}"], check=False)

        safe_text = text.replace("'", "'\\''")
        
        # Construcción del comando
        base = f"{self.raw_command} run --dangerously-skip-permissions -m {self.model}"
        if session_id:
            base += f" --session {session_id}"
        
        full_opencode_cmd = f"{base} \"{self.system_prompt}\" '{safe_text}'"

        # UI Script
        user_display = f"echo -e '\\033[1;32m󰔊 Tú:\\033[0m {safe_text}\\n'"
        thinking_msg = "echo -e '\\033[1;35m󰚩 Pensando...\\033[0m'"
        filter_cmd = "stdbuf -i0 -o0 -e0 grep -v '^> ' --line-buffered"
        
        ui_script = (
            f"clear; {user_display}; {thinking_msg}; "
            f"{full_opencode_cmd} 2>&1 | {filter_cmd}; "
            f"echo -e '\\n\\033[1;37m(Pulsa cualquier tecla para salir...)\\033[0m'; "
            f"read -n 1 -s"
        )

        self._launch_kitty(ui_script)

    def _launch_kitty(self, script: str):
        """Instancia la ventana flotante de Kitty."""
        try:
            kitty_conf = "/tmp/emebot_kitty.conf"
            if not os.path.exists(kitty_conf):
                with open(kitty_conf, "w") as f:
                    f.write("window_padding_width 20\nfont_size 14.0\nbackground_opacity 0.9\n")
                    f.write("remember_window_size no\ninitial_window_width 800\ninitial_window_height 500\n")

            kitty_cmd = ["kitty", "--config", kitty_conf, "--class", "emebot_popup", "--title", "EmeBotEme AI", "-e", "sh", "-c", script]
            subprocess.Popen(kitty_cmd, start_new_session=True, env=os.environ.copy())
        except Exception as e:
            print(f"[ERROR] Fallo al lanzar Kitty: {e}")

    def interrupt_command(self) -> None:
        """Cierra la ventana actual."""
        address = self._get_popup_address()
        if address:
            subprocess.run(["hyprctl", "dispatch", "closewindow", f"address:{address}"], check=False)

    def detach_session(self) -> None:
        self.interrupt_command()

    def stop(self) -> None:
        self.is_running = False
        self.interrupt_command()
