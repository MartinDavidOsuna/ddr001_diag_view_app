import argparse
import pathlib
import re
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parent
HEADER = ROOT / "include" / "device_config.h"
NAME_PATTERN = re.compile(r"^ESP32-[A-Z0-9][A-Z0-9_-]*-V\d+\.\d+(?:\.\d+)?$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Configura nombre, compila y opcionalmente flashea DDR001."
    )
    parser.add_argument(
        "--nombre",
        required=True,
        help="Ejemplo: ESP32-NS1001-V1.0",
    )
    parser.add_argument("--puerto", help="Puerto serie para flashear, por ejemplo COM15")
    parser.add_argument(
        "--solo-compilar",
        action="store_true",
        help="Genera el firmware sin cargarlo al ESP32.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    name = args.nombre.strip().upper()
    if not NAME_PATTERN.fullmatch(name):
        raise SystemExit(
            "Nombre inválido. Use ESP32-<SERIE>-V<VERSION>, por ejemplo "
            "ESP32-NS1001-V1.0."
        )
    advertised_name = "DDR001-PULSE-" + name.removeprefix("ESP32-")
    if len(advertised_name.encode("utf-8")) > 26:
        raise SystemExit("El nombre BLE no puede exceder 26 bytes.")
    if not args.solo_compilar and not args.puerto:
        raise SystemExit("Indique --puerto o use --solo-compilar.")

    HEADER.parent.mkdir(parents=True, exist_ok=True)
    HEADER.write_text(
        '#pragma once\n\n#define DDR001_DEVICE_NAME "' + advertised_name + '"\n',
        encoding="utf-8",
    )
    command = [sys.executable, "-m", "platformio", "run"]
    if not args.solo_compilar:
        command.extend(["--target", "upload", "--upload-port", args.puerto])
    print(f"Identidad solicitada: {name}")
    print(f"Nombre BLE compatible DDR001: {advertised_name}")
    return subprocess.call(command, cwd=ROOT)


if __name__ == "__main__":
    raise SystemExit(main())
