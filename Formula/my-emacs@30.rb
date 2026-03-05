class MyEmacsAT30 < Formula
  desc "GNU Emacs (X11/Lucid, native-comp, tree-sitter)"
  homepage "https://www.gnu.org/software/emacs/"
  version "30.2"
  url "https://github.com/emacs-mirror/emacs.git", :branch => "emacs-30"
  license "GPL-3.0-or-later"

  option "with-imagemagick", "Build with ImageMagick support"
  option "with-dbus", "Build with D-Bus support"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "make" => :build
  depends_on "pkgconf" => :build
  depends_on "texinfo" => :build

  depends_on "gnutls"
  depends_on "sqlite"
  depends_on "tree-sitter@0.25"

  depends_on "xz"
  depends_on "zlib"

  # Native compilation
  depends_on "gcc"
  depends_on "libgccjit"

  # X11/Lucid GUI stack
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "libx11"
  depends_on "libxaw"
  depends_on "libxext"
  depends_on "libxft"
  depends_on "libxmu"
  depends_on "libxpm"
  depends_on "libxt"

  # Rendering / images (common useful set)
  depends_on "cairo"
  depends_on "harfbuzz"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  # depends_on "librsvg"
  depends_on "little-cms2"
  depends_on "webp"

  depends_on "imagemagick" => :optional
  depends_on "dbus" => :optional

  depends_on "ripgrep" => :optional
  depends_on "aspell" => :optional
  depends_on "giflib" => :optional
  depends_on "libtiff" => :optional
  depends_on "libxml2" => :optional

  def install
    system "./autogen.sh"

    args = %W[
      --prefix=#{prefix}
      --disable-silent-rules
      --infodir=#{info}/emacs
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp

      --with-x
      --with-x-toolkit=lucid

      --with-native-compilation=aot
      --with-modules
      --with-tree-sitter

      --with-gnutls
      --with-json
      --with-sqlite3

      --with-cairo
      --with-harfbuzz
      --with-xml2
    ]

    # args << --with-rsvg
    # Optional feature toggles (match options above)
    args << "--with-imagemagick" if build.with? "imagemagick"
    args << "--with-dbus"        if build.with? "dbus"

    ENV.prepend_path "PKG_CONFIG_PATH", "#{HOMEBREW_PREFIX}/lib/pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", "#{HOMEBREW_PREFIX}/share/pkgconfig"

    ENV.append "CPPFLAGS", "-I#{Formula["sqlite"].opt_include}"
    ENV.append "LDFLAGS",  "-L#{Formula["sqlite"].opt_lib}"

    ENV.append "CPPFLAGS", "-I#{Formula["libgccjit"].opt_include}"
    ENV.append "LDFLAGS",  "-L#{Formula["libgccjit"].opt_lib}"

    ENV.append "CFLAGS", "-O3"
    ENV.append "CXXFLAGS", "-O3"
    ENV.append "LDFLAGS", "-Wl,-O1"

    system "./configure", *args
    system "make", "-j#{ENV.make_jobs}"
    system "make", "install"
  end

  def post_install
    emacs_info_dir = info/"emacs"
    Dir.glob(emacs_info_dir/"*.info") do |info_filename|
      system "install-info", "--info-dir=#{emacs_info_dir}", info_filename
    end
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval='(princ (+ 2 2))'").strip
  end
end
