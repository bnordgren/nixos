{ pkgs, options
# revision can have multiple values: local, HEAD or any revision number.
, revision ? "HEAD"
}:

let

  # To prevent infinite recursion, remove system.path from the
  # options.  Not sure why this happens.
  options_ =
    options //
    { system = removeAttrs options.system ["path"]; };

  optionsXML = builtins.toFile "options.xml" (builtins.unsafeDiscardStringContext
    (builtins.toXML (pkgs.lib.optionAttrSetToDocList "" options_)));

  optionsDocBook = pkgs.runCommand "options-db.xml" {} ''
    ${pkgs.libxslt}/bin/xsltproc \
      --stringparam revision '${revision}' \
      -o $out ${./options-to-docbook.xsl} ${optionsXML}
  '';

in rec {

  # Generate the NixOS manual.
  manual = pkgs.stdenv.mkDerivation {
    name = "nixos-manual";

    sources = pkgs.lib.sourceFilesBySuffices ./. [".xml"];

    buildInputs = [ pkgs.libxml2 pkgs.libxslt ];

    xsltFlags = ''
      --param section.autolabel 1
      --param section.label.includes.component.label 1
      --param html.stylesheet 'style.css'
      --param xref.with.number.and.title 1
      --param toc.section.depth 3
      --param admon.style '''
      --param callout.graphics.extension '.gif'
    '';

    buildCommand = ''
      ln -s $sources/*.xml . # */
      ln -s ${optionsDocBook} options-db.xml

      # Check the validity of the manual sources.
      xmllint --noout --nonet --xinclude --noxincludenode \
        --relaxng ${pkgs.docbook5}/xml/rng/docbook/docbook.rng \
        manual.xml

      # Generate the HTML manual.
      dst=$out/share/doc/nixos
      ensureDir $dst
      xsltproc $xsltFlags --nonet --xinclude \
        --output $dst/manual.html \
        ${pkgs.docbook5_xsl}/xml/xsl/docbook/xhtml/docbook.xsl \
        ./manual.xml

      ln -s ${pkgs.docbook5_xsl}/xml/xsl/docbook/images $dst/
      cp ${./style.css} $dst/style.css

      ensureDir $out/nix-support
      echo "doc manual $dst manual.html" >> $out/nix-support/hydra-build-products
    '';
  };

  # Generate the NixOS manpages.
  manpages = pkgs.stdenv.mkDerivation {
    name = "nixos-manpages";

    sources = pkgs.lib.sourceFilesBySuffices ./. [".xml"];

    buildInputs = [ pkgs.libxml2 pkgs.libxslt ];

    buildCommand = ''
      ln -s $sources/*.xml . # */
      ln -s ${optionsDocBook} options-db.xml

      # Check the validity of the manual sources.
      xmllint --noout --nonet --xinclude --noxincludenode \
        --relaxng ${pkgs.docbook5}/xml/rng/docbook/docbook.rng \
        ./man-pages.xml

      # Generate manpages.
      ensureDir $out/share/man
      xsltproc --nonet --xinclude \
        --param man.output.in.separate.dir 1 \
        --param man.output.base.dir "'$out/share/man/'" \
        --param man.endnotes.are.numbered 0 \
        ${pkgs.docbook5_xsl}/xml/xsl/docbook/manpages/docbook.xsl \
        ./man-pages.xml
    '';
  };

}
