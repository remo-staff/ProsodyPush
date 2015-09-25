-- 9/24/2015
-- Modified mod_offline_push to use luasec instead.

--A fork of mod_offline_mail except calls a URL 
--Which will foward the message to our mobile client.
--:)
--NOTE: Be sure to replace http://localhost/send/... to your URL
local jid_bare = require "util.jid".bare;
local https = require "ssl.https";
local ltn12 = require "ltn12"
local json_encode = require "util.json";
local mime = require("mime")

local send_message_as_push;

module:hook("message/offline/handle", function(event)
	local stanza = event.stanza;
	local text = stanza:get_child_text("body");
	if text then
		return send_message_as_push(jid_bare(stanza.attr.to), jid_bare(stanza.attr.from), text);
	end
end, 1);

function send_message_as_push(address, from_address, message_text, subject)
	module:log("info", "Forwarding offline message to %s via push", address);

	local host = "https://localhost/send/";
	local req_body = "message=&to=".. urlencode(address) .. "&from=" .. urlencode(jid_bare(from_address)) .. "&body=" .. urlencode(message_text); 

	local ok, code, headers, status = https.request {
		method = "POST";
		url = host;
		source = ltn12.source.string(req_body)
		headers = {
			["Accept"] = "*/*",
			["Content-Type"] = "application/x-www-form-urlencoded",
			["content-length"] = string.len(req_body), 
		}; 
	}

	if not ok then
		module:log("error", "Failed to deliver to %s: %s", tostring(address), tostring(err));
		return;
	end
	return true;
end

function urlencode(str)
if (str) then
str = string.gsub (str, "\n", "\r\n")
str = string.gsub (str, "([^%w ])",
function (c) return string.format ("%%%02X", string.byte(c)) end)
str = string.gsub (str, " ", "+")
end
return str
end
