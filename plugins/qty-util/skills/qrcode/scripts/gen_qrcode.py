#!/usr/bin/env python3
import sys
import qrcode

def main():
    if len(sys.argv) < 2:
        print("Usage: qrcode.py <string>", file=sys.stderr)
        sys.exit(1)
    data = " ".join(sys.argv[1:])
    qr = qrcode.QRCode()
    qr.add_data(data)
    qr.make()
    qr.print_ascii(invert=True)

if __name__ == "__main__":
    main()
