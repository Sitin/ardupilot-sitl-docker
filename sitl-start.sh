#!/usr/bin/env bash
set -e

function debug {
  if [ ! "${SILENT_START}" = "true" ]; then
    echo "$@"
  fi
}

#------------------------------------------------------------------------------
# Proxy UDP
#------------------------------------------------------------------------------

debug "Proxying UDP 5503 to host.docker.internal:5503..."

docker_host=$(python3 -c 'import socket; print(socket.gethostbyname("host.docker.internal"))')
proxy_port=5503

socat udp-listen:${proxy_port},reuseaddr,fork udp:"${docker_host}":${proxy_port} &
#echo "Docker to /dev/udp/0.0.0.0/${proxy_port}" | ncat -C --udp 0.0.0.0 ${proxy_port}

#------------------------------------------------------------------------------
# Execution config
#------------------------------------------------------------------------------

executable=/ardupilot/Tools/autotest/sim_vehicle.py
declare -a default_params=("--no-mavproxy" "--no-extra-ports")
cmd_params=("${@}")

#------------------------------------------------------------------------------
# Build configuration
#------------------------------------------------------------------------------

if [ ! "${ALLOW_REBUILD}" = 1 ]; then
  debug "Force skipping rebuilds."
  default_params[${#default_params[@]}]="--no-rebuild"
fi

#------------------------------------------------------------------------------
# State configuration
#------------------------------------------------------------------------------

# Create state directory if `USE_DIR` is set
if [ -n "${USE_DIR}" ]; then
  debug "STTL state will be stored in ${USE_DIR}"
  mkdir -p "${USE_DIR}"
fi

# Wipe vehicle memory unless `NO_WIPE_EEPROM=1` is provided
if [ ! "${NO_WIPE_EEPROM}" = "1" ]; then
    default_params[${#default_params[@]}]="--wipe-eeprom"
fi

#------------------------------------------------------------------------------
# Loop over environment variables and, if set, add corresponding parameter
#------------------------------------------------------------------------------
declare -a params_from_env=()
declare -a arg_names=("vehicle" "frame" "speedup" "instance" "location" "use-dir")
declare -a env_vars=("VEHICLE" "FRAME" "SPEEDUP" "INSTANCE" "LOCATION" "USE_DIR")
for i in "${!arg_names[@]}"; do
  arg_name="${arg_names[$i]}"
  var_name="${env_vars[$i]}"
  if [ -n "${!var_name}" ]; then
    var_value="${!var_name}"
    arg="--${arg_name}=$var_value"
    params_from_env[${#params_from_env[@]}]="${arg}"
  fi
done

#------------------------------------------------------------------------------
# Set custom location if specified
#------------------------------------------------------------------------------
custom_location_arg=""
declare -a custom_location_vars=("LATITUDE" "LONGITUDE" "ALTITUDE" "DIRECTION")
# Loop over custom location variables.
for var_name in "${custom_location_vars[@]}"
do
  # Set custom location if at least one variable is not empty
  if [ -n "${!var_name}" ]; then
    custom_location_arg="--custom-location=${LATITUDE},${LONGITUDE},${ALTITUDE},${DIRECTION}"
  fi
done
# Append custom location to params if available
if [ -n "${custom_location_arg}" ]; then
  params_from_env[${#params_from_env[@]}]="${custom_location_arg}"
fi

#------------------------------------------------------------------------------
# Run SITL
#------------------------------------------------------------------------------

# Combine all parameters into one array
params=("${default_params[@]}" "${params_from_env[@]}" "${cmd_params[@]}")

debug "Running SITL with parameters: ${params[*]} ..."
${executable} "${params[@]}"
