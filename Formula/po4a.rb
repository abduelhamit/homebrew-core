require "language/perl"

class Po4a < Formula
  include Language::Perl::Shebang

  desc "Documentation translation maintenance tool"
  homepage "https://po4a.org"
  url "https://github.com/mquinson/po4a/releases/download/v0.67/po4a-0.67.tar.gz"
  sha256 "4a4166a480d9b5bcc80b688604501b5545f1c9f67067e8f5494846de167a18a7"
  license "GPL-2.0-or-later"
  head "https://github.com/mquinson/po4a.git", branch: "master"

  bottle do
    sha256 cellar: :any,                 arm64_monterey: "b7dfd568f731a09e3da3ac0032e87fbbc591d67382156fc84a48ef5932504e78"
    sha256 cellar: :any,                 arm64_big_sur:  "5b9b2e358d4d5fe41c553a1f4643f412c9ba7dad56c49df234be1d7d6c6aa8d6"
    sha256 cellar: :any,                 monterey:       "fe7df5df2385cb52c14b3976c061af33a030d6e28c5b6d5df0b94642d45f8c50"
    sha256 cellar: :any,                 big_sur:        "5b07035f584ee757311fd08f82bef27efe4511627e36d14535ebe46846382fa4"
    sha256 cellar: :any,                 catalina:       "3dfc1f4cde97217205752346004841e0f7c95af44ef3d56806c061c059ba6dad"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "b9d248005fdc21a472cc730b4af982078a2e2d0164c579153b3841df1e7e860b"
  end

  depends_on "docbook-xsl" => :build
  depends_on "gettext"
  depends_on "perl"

  uses_from_macos "libxslt"

  resource "Locale::gettext" do
    url "https://cpan.metacpan.org/authors/id/P/PV/PVANDRY/gettext-1.07.tar.gz"
    sha256 "909d47954697e7c04218f972915b787bd1244d75e3bd01620bc167d5bbc49c15"
  end

  resource "Module::Build" do
    url "https://cpan.metacpan.org/authors/id/L/LE/LEONT/Module-Build-0.4231.tar.gz"
    sha256 "7e0f4c692c1740c1ac84ea14d7ea3d8bc798b2fb26c09877229e04f430b2b717"
  end

  resource "Pod::Parser" do
    url "https://cpan.metacpan.org/authors/id/M/MA/MAREKR/Pod-Parser-1.65.tar.gz"
    sha256 "3ba7bdec659416a51fe2a7e59f0883e9c6a3b21bc9d001042c1d6a32d401b28a"
  end

  resource "SGMLS" do
    url "https://cpan.metacpan.org/authors/id/R/RA/RAAB/SGMLSpm-1.1.tar.gz"
    sha256 "550c9245291c8df2242f7e88f7921a0f636c7eec92c644418e7d89cfea70b2bd"
  end

  resource "TermReadKey" do
    url "https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.38.tar.gz"
    sha256 "5a645878dc570ac33661581fbb090ff24ebce17d43ea53fd22e105a856a47290"
  end

  resource "Text::WrapI18N" do
    url "https://cpan.metacpan.org/authors/id/K/KU/KUBOTA/Text-WrapI18N-0.06.tar.gz"
    sha256 "4bd29a17f0c2c792d12c1005b3c276f2ab0fae39c00859ae1741d7941846a488"
  end

  resource "Unicode::GCString" do
    url "https://cpan.metacpan.org/authors/id/N/NE/NEZUMI/Unicode-LineBreak-2019.001.tar.gz"
    sha256 "486762e4cacddcc77b13989f979a029f84630b8175e7fef17989e157d4b6318a"
  end

  resource "YAML::Tiny" do
    url "https://cpan.metacpan.org/authors/id/E/ET/ETHER/YAML-Tiny-1.73.tar.gz"
    sha256 "bc315fa12e8f1e3ee5e2f430d90b708a5dc7e47c867dba8dce3a6b8fbe257744"
  end

  def install
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"
    ENV.prepend_path "PERL5LIB", libexec/"lib"

    resources.each do |r|
      r.stage do
        system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}", "NO_MYMETA=1"
        system "make", "install"
      end
    end

    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "perl", "Build.PL", "--install_base", libexec
    system "./Build"
    system "./Build", "install"

    shell_scripts = %w[po4a-display-man po4a-display-pod]

    %w[msguntypot po4a po4a-display-man po4a-display-pod
       po4a-gettextize po4a-translate po4a-normalize po4a-updatepo].each do |cmd|
      rewrite_shebang detected_perl_shebang, libexec/"bin"/cmd unless shell_scripts.include? cmd

      (bin/cmd).write_env_script(libexec/"bin"/cmd, PERL5LIB: ENV["PERL5LIB"])
    end

    man1.install Dir[libexec/"man/man1/{msguntypot.1p.gz,po4a*}"]
    man3.install Dir[libexec/"man/man3/Locale::Po4a::*"]
    man7.install Dir[libexec/"man/man7/*"]
  end

  test do
    (testpath/"en.tex").write <<~EOS
      \\documentclass[a4paper]{article}
      \\begin{document}
      Hello from Homebrew!
      \\end{document}
    EOS

    system bin/"po4a-gettextize", "-f", "asciidoc", "-m", "en.tex", "-p", "out.pot"
    assert_match "Hello from Homebrew!", (testpath/"out.pot").read
  end
end
