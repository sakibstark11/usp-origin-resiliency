local override = ngx.shared.override
local forced = override:get("forced")

if forced == "b" then
    ngx.var.backend = "origin_cluster_b"
else
    ngx.var.backend = "origin_cluster_a"
end
