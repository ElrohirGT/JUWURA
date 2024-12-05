{
  pkgs,
  lib,
  pgConfig,
  ...
}:
with lib; let
  # Recursively constructs an attrset of a given folder, recursing on directories, value of attrs is the filetype
  getDir = dir:
    mapAttrs
    (
      file: type:
        if type == "directory"
        then getDir "${dir}/${file}"
        else type
    )
    (builtins.readDir dir);

  # Collects all files of a directory as a list of strings of paths
  files = dir: collect isString (mapAttrsRecursive (path: _type: concatStringsSep "/" path) (getDir dir));

  # Filters out directories that don't end with .nix or are this file, also makes the strings absolute
  getFilesWithExtension = dir: extension:
    map
    (file: "${dir}/${file}")
    (
      filter
      (file: let
        fileIsNixFile = hasSuffix extension file;
      in
        fileIsNixFile)
      (files dir)
    );

  dbInitFile = strings.concatStringsSep "\n" (map builtins.readFile (getFilesWithExtension ./. ".sql"));
  PGDATA = ''"$PWD/.pgData"'';
  startPostgres = ''
    set -euo pipefail
    echo PWD = "$PWD"
    echo PGDATA = ${PGDATA}
    rm -rf "${PGDATA}"
    mkdir -p "${PGDATA}"
    export PATH=${pkgs.postgresql}/bin:${pkgs.coreutils}/bin

    export PGDATA=${PGDATA}
    export PGHOST=${PGDATA}
    echo "The PGDATA variable is" $PGDATA
    echo "The PGHOST variable is" $PGHOST

    initdb --locale=C --encoding=UTF8
    POSTGRES_RUN_INITIAL_SCRIPT="true"
    echo
    echo "PostgreSQL initdb process complete."
    echo

    # Setup pg_hba.conf
    echo "Setting up pg_hba"
    cp ${./pg_hba.conf} "${PGDATA}/pg_hba.conf"
    echo "HBA setup complete!"

    echo
    echo "PostgreSQL is setting up the initial database."
    echo

    echo "Listing files"
    ls ${PGDATA}
    echo "Who am I? $(whoami)"
    echo Starting server with command: pg_ctl -w start -o "-c unix_socket_directories=${PGDATA} -c listen_addresses=* -p ${builtins.toString pgConfig.port}"
    pg_ctl -w start -o "-c unix_socket_directories=${PGDATA} -c listen_addresses=* -p ${builtins.toString pgConfig.port}"

    echo "Initializing DB"
    echo "${dbInitFile}" | psql --dbname postgres -p ${builtins.toString pgConfig.port}
    echo "JUWURA postgres is now running!"
  '';
  stopPostgres = ''
    set -euo pipefail
    export PGDATA=${PGDATA}
    export PGHOST=${PGDATA}
    echo "The PGDATA variable is" $PGDATA
    echo "The PGHOST variable is" $PGHOST

    pg_ctl -m fast -w stop
  '';
in {
  command = startPostgres;
  ready_log_line = "postgres is now running";
	# readiness_probe = {
	# 	exec = ''${pkgs.postgresql}/bin/pg_isready \
	# 	-d juwura -h '${pgConfig.host}' \
	# 	-p '${builtins.toString pgConfig.port}' -U postgres
	# 	'';
	# };
  is_daemon = true;
  shutdown.command = stopPostgres;
}
