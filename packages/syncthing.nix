{ syncthing, fetchFromGitHub }:

# Keep the database/concurrency fixes newer than our main nixpkgs pin.
# Remove this override once that pin provides Syncthing >= 2.1.5.
syncthing.overrideAttrs (
  finalAttrs: _: {
    version = "2.1.5";
    src = fetchFromGitHub {
      owner = "syncthing";
      repo = "syncthing";
      tag = "v${finalAttrs.version}";
      hash = "sha256-8rrOfX6C96YEbvUh1IZP1V8x4RB99O0mC+y5h8579Vo=";
    };
    vendorHash = "sha256-YXzTGtALTC9HQTAeZtweS+GONdgyqrHOJdLZt0QhnJM=";
  }
)
