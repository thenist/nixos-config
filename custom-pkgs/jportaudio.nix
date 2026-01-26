{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "jportaudio";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "philburk";
    repo = "portaudio-java";
    rev = "ed2d3bc78b42f9c877863618b0ec4dac216102cc";
    sha256 = "tpJ4JqNFcuDmW70fLa0mW4fytjlU7h77IgMwS3msUX8=";
  };

  nativeBuildInputs = with pkgs; [
    cmake
    clang
  ];

  buildInputs = with pkgs; [
    portaudio
    jdk17
  ];

  buildPhase = "make -j $NIX_BUILD_CORES";

  installPhase = ''
    mkdir -p $out/lib
    mv $TMP/source/build/libjportaudio_0_1_0.so $out/lib/libjportaudio.so
  '';
}
