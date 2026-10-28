{
  fetchurl,
  writeShellScriptBin,
  jdk21,
  jdk ? jdk21,
}:

let
  jar = fetchurl {
    url = "https://keymaerax.org/keymaerax.jar";
    # The URL is unversioned; update this hash when upstream publishes a new release.
    sha256 = "0i6dp0c8vwqhyrfk0fcys9i2wp3diby6nhaq8l9jsplwj6ijyhkf";
  };
in
writeShellScriptBin "keymaerax" ''
  exec ${jdk}/bin/java -jar ${jar} "$@"
''
