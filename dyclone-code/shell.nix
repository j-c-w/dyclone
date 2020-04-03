{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
	inherit (stdenv.lib) optionals optionalString;
	useX11 = ! stdenv.isAarch32 && ! stdenv.isMips;
	useNativeCompilers = ! stdenv.isMips;
in
let
	ocaml_308 = ocaml.overrideAttrs (old: {
		pname = "ocaml";
		version = "3.12.1";

		src = fetchurl {
			url = "https://caml.inria.fr/pub/distrib/ocaml-3.12/ocaml-3.12.1.tar.bz2";
			sha256 = "13cmhkh7s6srnlvhg3s9qzh3a5dbk2m9qr35jzq922sylwymdkzd";
		};

		prefixKey = "-prefix ";
		configureFlags = ["-no-tk"] ++ optionals useX11 [ "-x11lib" xlibsWrapper ];
		buildFlags = [ "world" ] ++ optionals useNativeCompilers [ "bootstrap" "world.opt" ];
		buildInputs = [ncurses] ++ optionals useX11 [ xlibsWrapper ];
		installTargets = "install" + optionalString useNativeCompilers " installopt";
		patches = optionals stdenv.isDarwin [ ./3.12.1-darwin-fix-configure.patch ];
		preConfigure = ''
			CAT=$(type -tp cat)
			sed -e "s@/bin/cat@$CAT@" -i config/auto-aux/sharpbang
		'';
		postBuild = ''
			mkdir -p $out/include
			ln -sv $out/lib/ocaml/caml $out/include/caml
		'';
		postInstall = ''
			ln -sv $out/lib/ocaml/str.a $out/lib/ocaml/libstr.a
		'';

		passthru = {
			nativeCompilers = useNativeCompilers;
		};

		meta = with stdenv.lib; {
			homepage = http://caml.inria.fr/ocaml;
			branch = "3.12";
			license = with licenses; [
				qpl /* compiler */
				lgpl2 /* library */
			];
			description = "Most popular variant of the Caml language";
			};

			platforms = with platforms; linux;
	});
in
mkShell {
	buildInputs = [ ocaml_308 perl autoconf automake gnumake ncurses  ];
}
