function GameTooltip_AddBlankLinesToTooltip(tooltip, numLines)
	if numLines ~= nil then
		for i = 1, numLines do
			tooltip:AddLine(" ");
		end
	end
end

function GameTooltip_AddNormalLine(tooltip, text, wrap)
	GameTooltip_AddColoredLine(tooltip, text, NORMAL_FONT_COLOR, wrap);
end

function GameTooltip_AddInstructionLine(tooltip, text, wrap)
	GameTooltip_AddColoredLine(tooltip, text, GREEN_FONT_COLOR, wrap);
end

function GameTooltip_AddColoredLine(tooltip, text, color, wrap)
	local r, g, b = color.r, color.g, color.b;
	tooltip:AddLine(text, r, g, b, wrap);
end
