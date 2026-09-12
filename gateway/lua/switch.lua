local override = ngx.shared.override
local args = ngx.req.get_uri_args()
local target = args.origin

if target == "a" or target == "b" then
    override:set("forced", target)
    ngx.say("Manual override set to origin ", target)
    return ngx.exit(ngx.HTTP_OK)
elseif target == "clear" then
    override:delete("forced")
    ngx.say("Manual override cleared - automatic detection resumed")
    return ngx.exit(ngx.HTTP_OK)
else
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("Invalid 'origin' parameter - use a, b or clear")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
