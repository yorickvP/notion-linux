with import <nixpkgs> {};
mkShell {
  buildInputs = [ nodejs-15_x p7zip electron_11 python2 imagemagick ];
  PYTHON = "python2";
  JOBS = "max";
}
