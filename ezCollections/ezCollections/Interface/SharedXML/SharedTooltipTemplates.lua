function GameTooltip_AddBlankLinesToTooltip(tooltip, numLines)
	if numLines ~= nil then
		for i = 1, numLines do
			tooltip:AddLine(" ");
		end
	end
end

function GameTooltip_AddBlankLineToTooltip(tooltip)
	GameTooltip_AddBlankLinesToTooltip(tooltip, 1);
end

function GameTooltip_SetTitle(tooltip, text, overrideColor, wrap)
	tooltip:ClearLines();
	GameTooltip_AddColoredLine(tooltip, text, overrideColor or HIGHLIGHT_FONT_COLOR, wrap)
end

function GameTooltip_AddNormalLine(tooltip, text, wrap)
	GameTooltip_AddColoredLine(tooltip, text, NORMAL_FONT_COLOR, wrap);
end

function GameTooltip_AddHighlightLine(tooltip, text, wrap)
	GameTooltip_AddColoredLine(tooltip, text, HIGHLIGHT_FONT_COLOR, wrap);
end

function GameTooltip_AddInstructionLine(tooltip, text, wrap)
	GameTooltip_AddColoredLine(tooltip, text, GREEN_FONT_COLOR, wrap);
end

function GameTooltip_AddErrorLine(tooltip, text, wrap)
	GameTooltip_AddColoredLine(tooltip, text, RED_FONT_COLOR, wrap);
end

local DISABLED_FONT_COLOR = { r = 0.498, g = 0.498, b = 0.498 };
function GameTooltip_AddDisabledLine(tooltip, text, wrap)
	GameTooltip_AddColoredLine(tooltip, text, DISABLED_FONT_COLOR, wrap);
end

function GameTooltip_AddColoredLine(tooltip, text, color, wrap)
	local r, g, b = color.r, color.g, color.b;
	if wrap == nil then
		wrap = true;
	end
	tooltip:AddLine(text, r, g, b, wrap);
end

function GameTooltip_AddColoredDoubleLine(tooltip, leftText, rightText, leftColor, rightColor, wrap)
	local leftR, leftG, leftB = leftColor.r, leftColor.g, leftColor.b;
	local rightR, rightG, rightB = rightColor.r, rightColor.g, rightColor.b;
	if wrap == nil then
		wrap = true;
	end
	tooltip:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB, wrap);
end
