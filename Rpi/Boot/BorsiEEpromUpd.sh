#!/bin/bash

TMP_DIR=/tmp

    cat << EOF | sed 's/^.\{4\}//' | ${SUDO} tee ${TMP_DIR}/boot.conf
        [all]
        BOOT_UART=0
        WAKE_ON_GPIO=1
        POWER_OFF_ON_HALT=0

        # Try  Network -> SD- > Loop
        BOOT_ORDER=0xf12

        # Set to 0 to prevent bootloader updates from USB/Network boot
        # For remote units EEPROM hardware write protection should be used.
        ENABLE_SELF_UPDATE=1

        # default=0 silent=1
        DISABLE_HDMI=0
EOF

CM4_ENABLE_RPI_EEPROM_UPDATE=1 sudo -E rpi-eeprom-config --apply ${TMP_DIR}/boot.conf