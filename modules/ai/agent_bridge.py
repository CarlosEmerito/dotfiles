import subprocess
import os
import json
import time

class AgentBridge:
    """Maneja la comunicación persistente con el agente CLI usando TMUX."""
    
    def __init__(self, command: str, system_prompt: str):
        self.session_name = "emebot_session"
        self.raw_command = command
        self.system_prompt = system_prompt
        self.is_running = True

    def start(self) -> None:
        """Inicia la sesión de tmux si no existe."""
        if not self._session_exists():
            print(f"[BRIDGE] Iniciando sesión persistente tmux: {self.session_name}")
            # Crear sesión detached con un shell limpio
            subprocess.run(["tmux", "new-session", "-d", "-s", self.session_name, "sh"], check=True)
            # Desactivamos el eco del shell y la barra de estado de tmux para una UI limpia
            time.sleep(0.1)
            subprocess.run(["tmux", "set-option", "-t", self.session_name, "status", "off"], check=True)
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "stty -echo", "C-m"])
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "export PS1=\"\"", "C-m"])
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "clear", "C-m"])
            # Limpiamos el flag de sesión al iniciar
            session_flag = f"/tmp/emebot_active_{self.session_name}"
            if os.path.exists(session_flag):
                os.remove(session_flag)

    def _session_exists(self):
        res = subprocess.run(["tmux", "has-session", "-t", self.session_name], capture_output=True)
        return res.returncode == 0

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
        """Envía el comando completo a tmux para mantener la persistencia."""
        if not self.is_running or not text:
            return

        print(f"[BRIDGE] Preparando comando para tmux: '{text}'")
        
        if not self._session_exists():
            self.start()

        # Escapado para shell dentro de tmux
        safe_text = text.replace("'", "'\\''")
        
        # Verificamos si es la primera vez en esta sesión de tmux
        session_flag = f"/tmp/emebot_active_{self.session_name}"
        
        # Comando base común
        base = f"{self.raw_command} run --dangerously-skip-permissions -m opencode/big-pickle"

        if not os.path.exists(session_flag):
            # Primera vez: Command + System Prompt + Text
            full_cmd = f"{base} \"{self.system_prompt}\" '{safe_text}'"
            with open(session_flag, "w") as f: f.write("active")
        else:
            # Continuación: Command + --continue + Text
            full_cmd = f"{base} --continue '{safe_text}'"

        # Añadimos 'clear', mostramos el input del usuario visualmente, ejecutamos y permitimos cerrar.
        user_display = f"echo -e '\\033[1;32m󰔊 Tú:\\033[0m {safe_text}\\n'"
        thinking_msg = "echo -e '\\033[1;35m󰚩 Pensando...\\033[0m'"
        # Filtramos las líneas que empiezan por '>' (llamadas a herramientas internas)
        filter_cmd = "stdbuf -i0 -o0 -e0 grep -v '^> ' --line-buffered"
        full_cmd_with_ui = f"clear; {user_display}; {thinking_msg}; {full_cmd} 2>&1 | {filter_cmd}; echo -e '\\n\\033[1;37m(Pulsa cualquier tecla para salir...)\\033[0m'; read -n 1 -s; tmux detach"

        # Enviamos C-u para limpiar cualquier 'z' accidental, luego el comando completo
        subprocess.run(["tmux", "send-keys", "-t", self.session_name, "C-u", full_cmd_with_ui, "C-m"])

        # Gestionar la ventana visual (Kitty)
        address = self._get_popup_address()
        if not address:
            self._launch_kitty()
        else:
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"])

    def _launch_kitty(self):
        try:
            # Comando para que kitty se atache a la sesión existente
            attach_cmd = f"tmux attach-session -t {self.session_name}"

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
                "--title", "EmeBotEme AI (Persistent)",
                "-e", "sh", "-c", attach_cmd
            ]
            
            subprocess.Popen(kitty_cmd, start_new_session=True, env=os.environ.copy())
            
        except Exception as e:
            print(f"[ERROR] No se pudo lanzar kitty: {e}")

    def interrupt_command(self) -> None:
        """Envía un Ctrl+C a la sesión de tmux para detener el proceso actual."""
        if self._session_exists():
            print("[BRIDGE] Interrumpiendo comando actual...")
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "C-c"])

    def detach_session(self) -> None:
        """Envía el comando detach a tmux para cerrar la ventana de kitty."""
        if self._session_exists():
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "tmux detach", "C-m"])

    def stop(self) -> None:
        """Cierra la sesión de tmux al salir."""
        self.is_running = False
        if self._session_exists():
            print(f"[BRIDGE] Cerrando sesión tmux: {self.session_name}")
            subprocess.run(["tmux", "kill-session", "-t", self.session_name])
            session_flag = f"/tmp/emebot_active_{self.session_name}"
            if os.path.exists(session_flag):
                os.remove(session_flag)
