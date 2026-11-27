# Noctalia's foot template writes the palette to
# ~/.config/foot/themes/noctalia at runtime. The include has to be
# declarative because home-manager owns foot.ini as a read-only store
# symlink, which Noctalia's apply.sh cannot append to.

{ ... }:

{
  xdg.configFile."foot/foot.ini".text = ''
    [main]
    include=~/.config/foot/themes/noctalia
    font=JetBrainsMono Nerd Font:size=11
    font-bold=JetBrainsMono Nerd Font:style=Bold:size=11
    font-italic=JetBrainsMono Nerd Font:style=Italic:size=11
    font-bold-italic=JetBrainsMono Nerd Font:style=Bold Italic:size=11
    pad=10x8
  '';
}
