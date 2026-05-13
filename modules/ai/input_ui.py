import sys
import os
import traceback

try:
    from prompt_toolkit import prompt
    from prompt_toolkit.key_binding import KeyBindings
except ImportError:
    print("Error: prompt_toolkit no está instalado.")
    sys.exit(1)

def main():
    # Colores EmeDotEme
    PURPLE = "\033[1;35m"
    YELLOW = "\033[1;33m"
    CYAN = "\033[1;36m"
    NC = "\033[0m"

    print(f"{PURPLE}󰚩 EmeBotEme{NC}")
    
    kb = KeyBindings()

    # Importamos los comandos estándar
    from prompt_toolkit.key_binding.bindings.named_commands import backward_kill_word, backward_delete_char

    # Mapeamos los atajos según tu preferencia
    # c-h borrará la palabra completa
    kb.add('c-h')(backward_kill_word)
    kb.add('escape', 'backspace')(backward_kill_word)

    # Forzamos que la tecla física Backspace solo borre un carácter
    # Esto evita que, en terminales que confunden c-h con backspace, 
    # el retroceso normal borre palabras enteras.
    kb.add('backspace')(backward_delete_char)

    @kb.add('escape')
    def _(event):
        """Salir sin guardar al pulsar Escape."""
        event.app.exit()

    try:
        # Usamos prompt_toolkit con los bindings
        text = prompt("> ", key_bindings=kb)
        
        if text and text.strip():
            with open("/tmp/emebot_input.txt", "w") as f:
                f.write(text.strip())
    except (EOFError, KeyboardInterrupt):
        sys.exit(0)
    except Exception as e:
        print(f"\n{PURPLE}Error crítico en el input:{NC}")
        traceback.print_exc()
        input("\nPresiona Intro para cerrar...")

if __name__ == "__main__":
    main()
