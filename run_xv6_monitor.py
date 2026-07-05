import os
import time
import sys
import pexpect

def main():
    project_dir = "/mnt/c/Users/rubaa/Desktop/xv6-educational-main"
    log_file_path = os.path.join(project_dir, "qemu.log")
    
    try:
        os.chdir(project_dir)
        print(style_text(f"[+] Changed directory to: {project_dir}", "green"))
    except FileNotFoundError:
        print(style_text(f"[-] Error: Directory {project_dir} not found.", "red"))
        return

    command = "make qemu"
    
    print(style_text("[+] Starting xv6 via QEMU...", "green"))
    
    log_file = open(log_file_path, "w", encoding="utf-8")
    
    try:
        child = pexpect.spawn(command, encoding='utf-8', timeout=None)
        
        child.logfile = sys.stdout
        child.logfile_read = log_file

        child.expect(r'\$ ')
        
        print(style_text("\n[+] xv6 booted successfully. Starting cpuinfo loop...", "blue"))
        
        seconds_passed = 0
        
        while True:
            child.sendline("cpuinfo")
            
            if seconds_passed > 0 and seconds_passed % 20 == 0:
                print(style_text("\n[!] Activating 2 CPUs: Launching two stressfs instances...", "yellow"))
                child.sendline("infinite &")  
            
            try:
                child.expect(r'\$ ', timeout=5)
            except pexpect.exceptions.TIMEOUT:
                pass
            
            time.sleep(1)
            seconds_passed += 1
            
    except pexpect.exceptions.EOF:
        print(style_text("\n[-] QEMU process finished (EOF).", "yellow"))
    except KeyboardInterrupt:
        print(style_text("\n[+] Monitoring stopped by user (Ctrl+C). Exiting QEMU...", "green"))
        if child.isalive():
            child.close(force=True)
    finally:
        log_file.close()
        print(style_text(f"[+] Log saved to {log_file_path}", "green"))

def style_text(text, color):
    colors = {
        "green": "\033[92m",
        "red": "\033[91m",
        "blue": "\033[94m",
        "yellow": "\033[93m",
        "reset": "\033[0m"
    }
    return f"{colors.get(color, '')}{text}{colors['reset']}"

if __name__ == "__main__":
    main()
