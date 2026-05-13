import subprocess
import os
import json
import time

class AgentBridge:
    """
    Gestiona la persistencia de la conversación y la interfaz de usuario.
    Utiliza TMUX como backend de sesión para mantener el estado del agente de IA
    incluso si la ventana visual (Kitty) se cierra.
    """
    
    def __init__(self, command: str, system_prompt: str):
        self.session_name = "emebot_session"
        self.raw_command = command
        self.system_prompt = system_prompt
        self.is_running = True

    def start(self) -> None:
        """
        Inicializa una sesión de TMUX 'detached' si no existe.
        Prepara el entorno del shell para una visualización limpia eliminando eco y prompts.
        """
        if not self._session_exists():
            # Crear sesión con un shell minimalista
            subprocess.run(["tmux", "new-session", "-d", "-s", self.session_name, "sh"], check=True)
            
            # Tuning de la sesión TMUX para integración con el popup
            time.sleep(0.1) # Breve pausa para asegurar la creación del socket de tmux
            subprocess.run(["tmux", "set-option", "-t", self.session_name, "status", "off"], check=True)
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "stty -echo", "C-m"])
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "export PS1=\"\"", "C-m"])
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "clear", "C-m"])
            
            # Reset del estado de sesión activa
            session_flag = f"/tmp/emebot_active_{self.session_name}"
            if os.path.exists(session_flag):
                os.remove(session_flag)

    def _session_exists(self):
        """Verifica la existencia de la sesión persistente en el servidor TMUX."""
        res = subprocess.run(["tmux", "has-session", "-t", self.session_name], capture_output=True)
        return res.returncode == 0

    def _get_popup_address(self):
        """
        Interactúa con Hyprland para localizar la ventana del asistente.
        Retorna la dirección hexadecimal de la ventana si está presente.
        """
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
        """
        Envía la entrada del usuario al agente de IA dentro de la sesión TMUX.
        Gestiona el flujo de 'nuevo comando' vs 'continuación de conversación'.
        """
        if not self.is_running or not text:
            return

        if not self._session_exists():
            self.start()

        # Sanitización básica para inyección de comandos en el shell de tmux
        safe_text = text.replace("'", "'\\''")
        
        session_flag = f"/tmp/emebot_active_{self.session_name}"
        base = f"{self.raw_command} run --dangerously-skip-permissions -m opencode/big-pickle"

        # Determinación del modo de ejecución del agente
        if not os.path.exists(session_flag):
            full_cmd = f"{base} \"{self.system_prompt}\" '{safe_text}'"
            with open(session_flag, "w") as f: f.write("active")
        else:
            full_cmd = f"{base} --continue '{safe_text}'"

        # Construcción de la pipeline de visualización con filtrado en tiempo real
        user_display = f"echo -e '\\033[1;32m󰔊 Tú:\\033[0m {safe_text}\\n'"
        thinking_msg = "echo -e '\\033[1;35m󰚩 Pensando...\\033[0m'"
        # Uso de stdbuf para evitar el buffering en el pipe de grep, asegurando respuesta inmediata
        filter_cmd = "stdbuf -i0 -o0 -e0 grep -v '^> ' --line-buffered"
        full_cmd_with_ui = f"clear; {user_display}; {thinking_msg}; {full_cmd} 2>&1 | {filter_cmd}; echo -e '\\n\\033[1;37m(Pulsa cualquier tecla para salir...)\\033[0m'; read -n 1 -s; tmux detach"

        # C-u limpia el buffer del shell de tmux antes de enviar el comando para evitar colisiones
        subprocess.run(["tmux", "send-keys", "-t", self.session_name, "C-u", full_cmd_with_ui, "C-m"])

        # Gestión de la ventana visual
        address = self._get_popup_address()
        if not address:
            self._launch_kitty()
        else:
            # Si ya existe, simplemente le damos foco
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"])

    def _launch_kitty(self):
        """Despliega una nueva instancia de Kitty vinculada a la sesión TMUX."""
        try:
            attach_cmd = f"tmux attach-session -t {self.session_name}"
            kitty_conf = "/tmp/emebot_kitty.conf"
            
            # Generación dinámica de configuración para Kitty (Floating Popup)
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
            
            # Lanzamiento desacoplado para no bloquear el hilo de control
            subprocess.Popen(kitty_cmd, start_new_session=True, env=os.environ.copy())
            
        except Exception as e:
            print(f"[ERROR] Fallo crítico al instanciar la interfaz Kitty: {e}")

    def interrupt_command(self) -> None:
        """Envía una señal de interrupción (SIGINT) al proceso en ejecución dentro de TMUX."""
        if self._session_exists():
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "C-c"])

    def detach_session(self) -> None:
        """Fuerza el desenganche de TMUX, lo que cierra la ventana cliente de Kitty."""
        if self._session_exists():
            subprocess.run(["tmux", "send-keys", "-t", self.session_name, "tmux detach", "C-m"])

    def stop(self) -> None:
        """Cleanup total de la sesión y recursos asociados antes de la terminación del servicio."""
        self.is_running = False
        if self._session_exists():
            subprocess.run(["tmux", "kill-session", "-t", self.session_name])
            session_flag = f"/tmp/emebot_active_{self.session_name}"
            if os.path.exists(session_flag):
                os.remove(session_flag)
