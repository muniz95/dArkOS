#!/bin/bash
#
# Maps UNIT (device name) to CHIPSET, mirroring the "export CHIPSET=..."
# line at the top of each build_<device>.sh. Sourced by build_step.sh.
#
# Keep in sync with build_<device>.sh if a new device is added or a
# device's chipset changes.

case "$UNIT" in
  a10mini|g350|rgb10|rg351mp|rg351p)
    CHIPSET=rk3326
    ;;
  miniloong|rgb20pro|rgb30|rg353m|rg353v|rg503|rk2023)
    CHIPSET=rk3566
    ;;
  *)
    echo "Unknown UNIT '${UNIT}' - add it to chipset_for_unit.sh" >&2
    exit 1
    ;;
esac
