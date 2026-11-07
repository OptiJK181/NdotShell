hl.layer_rule({ name = "ndotshell-region-no-anim", match = { namespace = "^ndotshell-region$" }, no_anim = true }) -- ndotshell:region-no-anim
hl.layer_rule({ name = "ndotshell-region-preview-no-anim", match = { namespace = "^ndotshell-region-preview$" }, no_anim = true }) -- ndotshell:region-preview-no-anim
hl.config({ ["general"] = { ["gaps_out"] = 14 } }) -- ndotshell:hypr:general.gaps_out
hl.config({ ["general"] = { ["gaps_in"] = 6 } }) -- ndotshell:hypr:general.gaps_in
hl.config({ ["decoration"] = { ["inactive_opacity"] = 1.00 } }) -- ndotshell:hypr:decoration.inactive_opacity
hl.config({ ["general"] = { ["border_size"] = 2 } }) -- ndotshell:hypr:general.border_size
hl.config({ ["misc"] = { ["animate_manual_resizes"] = true } }) -- ndotshell:hypr:misc.animate_manual_resizes
hl.animation({ leaf = "workspaces", enabled = true, speed = 7.00, bezier = "menu_decel", style = "slidefadevert" }) -- ndotshell:hypr:animation.workspaces
pcall(hl.config, { ["general"] = { ["col"] = { ["active_border"] = "rgba(00feeeee)", ["inactive_border"] = "rgba(00757bcc)" } } }) -- ndotshell:apptheme:hyprland
