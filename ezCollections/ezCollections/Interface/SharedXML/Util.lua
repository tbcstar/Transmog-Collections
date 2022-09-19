function SetClampedTextureRotation(texture, rotationDegrees)
	if (rotationDegrees ~= 0 and rotationDegrees ~= 90 and rotationDegrees ~= 180 and rotationDegrees ~= 270) then
		error("SetRotation: rotationDegrees must be 0, 90, 180, or 270");
		return;
	end

	if not (texture.rotationDegrees) then
		texture.origTexCoords = {texture:GetTexCoord()};
		texture.origWidth = texture:GetWidth();
		texture.origHeight = texture:GetHeight();
	end

	if (texture.rotationDegrees == rotationDegrees) then
		return;
	end

	texture.rotationDegrees = rotationDegrees;

	if (rotationDegrees == 0 or rotationDegrees == 180) then
		texture:SetWidth(texture.origWidth);
		texture:SetHeight(texture.origHeight);
	else
		texture:SetWidth(texture.origHeight);
		texture:SetHeight(texture.origWidth);
	end

	if (rotationDegrees == 0) then
		texture:SetTexCoord( texture.origTexCoords[1], texture.origTexCoords[2],
											texture.origTexCoords[3], texture.origTexCoords[4],
											texture.origTexCoords[5], texture.origTexCoords[6],
											texture.origTexCoords[7], texture.origTexCoords[8] );
	elseif (rotationDegrees == 90) then
		texture:SetTexCoord( texture.origTexCoords[3], texture.origTexCoords[4],
											texture.origTexCoords[7], texture.origTexCoords[8],
											texture.origTexCoords[1], texture.origTexCoords[2],
											texture.origTexCoords[5], texture.origTexCoords[6] );
	elseif (rotationDegrees == 180) then
		texture:SetTexCoord( texture.origTexCoords[7], texture.origTexCoords[8],
											texture.origTexCoords[5], texture.origTexCoords[6],
											texture.origTexCoords[3], texture.origTexCoords[4],
											texture.origTexCoords[1], texture.origTexCoords[2] );
	elseif (rotationDegrees == 270) then
		texture:SetTexCoord( texture.origTexCoords[5], texture.origTexCoords[6],
											texture.origTexCoords[1], texture.origTexCoords[2],
											texture.origTexCoords[7], texture.origTexCoords[8],
											texture.origTexCoords[3], texture.origTexCoords[4] );
	end
end

function ClearClampedTextureRotation(texture)
	if (texture.rotationDegrees) then
		SetClampedTextureRotation(texture, 0);
		texture.origTexCoords = nil;
		texture.origWidth = nil;
		texture.origHeight = nil;
	end
end

-- where ... are the mixins to mixin
function Mixin(object, ...)
	for i = 1, select("#", ...) do
		local mixin = select(i, ...);
		for k, v in pairs(mixin) do
			object[k] = v;
		end
	end

	return object;
end

-- where ... are the mixins to mixin
function CreateFromMixins(...)
	return Mixin({}, ...)
end

function Clamp(value, min, max)
	if value > max then
		return max;
	elseif value < min then
		return min;
	end
	return value;
end

function Round(value)
	if value < 0.0 then
		return math.ceil(value - .5);
	end
	return math.floor(value + .5);
end

ColorMixin = {};

function CreateColor(r, g, b, a)
	local color = CreateFromMixins(ColorMixin);
	color:OnLoad(r, g, b, a);
	return color;
end

function AreColorsEqual(left, right)
	if left and right then
		return left:IsEqualTo(right);
	end
	return left == right;
end

function ColorMixin:OnLoad(r, g, b, a)
	self:SetRGBA(r, g, b, a);
end

function ColorMixin:IsEqualTo(otherColor)
	return self.r == otherColor.r
		and self.g == otherColor.g
		and self.b == otherColor.b
		and self.a == otherColor.a;
end

function ColorMixin:GetRGB()
	return self.r, self.g, self.b;
end

function ColorMixin:GetRGBAsBytes()
	return self.r * 255, self.g * 255, self.b * 255;
end

function ColorMixin:GetRGBA()
	return self.r, self.g, self.b, self.a;
end

function ColorMixin:GetRGBAAsBytes()
	return self.r * 255, self.g * 255, self.b * 255, (self.a or 1) * 255;
end

function ColorMixin:SetRGBA(r, g, b, a)
	self.r = r;
	self.g = g;
	self.b = b;
	self.a = a;
end

function ColorMixin:SetRGB(r, g, b)
	self:SetRGBA(r, g, b, nil);
end

function ColorMixin:GenerateHexColor()
	return ("ff%.2x%.2x%.2x"):format(self:GetRGBAsBytes());
end

function ColorMixin:WrapTextInColorCode(text)
	return WrapTextInColorCode(text, self:GenerateHexColor());
end

-- Mix this into a FontString to have it resize until it stops truncating, or gets too small
ShrinkUntilTruncateFontStringMixin = {};

-- From largest to smallest
function ShrinkUntilTruncateFontStringMixin:SetFontObjectsToTry(...)
	self.fontObjectsToTry = { ... };
	if self:GetText() then
		self:ApplyFontObjects();
	end
end

function ShrinkUntilTruncateFontStringMixin:ApplyFontObjects()
	if not self.fontObjectsToTry then
		error("No fonts applied to ShrinkUntilTruncateFontStringMixin, call SetFontObjectsToTry first");
	end

	for i, fontObject in ipairs(self.fontObjectsToTry) do
		self:SetFontObject(fontObject);
		if not self.IsTruncated then Mixin(self, IsTruncatedMixin); end
		if not self:IsTruncated() then
			break;
		end
	end
end

function ShrinkUntilTruncateFontStringMixin:SetText(text)
	if not self:GetFont() then
		if not self.fontObjectsToTry then
			error("No fonts applied to ShrinkUntilTruncateFontStringMixin, call SetFontObjectsToTry first");
		end
		self:SetFontObject(self.fontObjectsToTry[1]);
	end

	getmetatable(self).__index.SetText(self, text);
	self:ApplyFontObjects();
end

function ShrinkUntilTruncateFontStringMixin:SetFormattedText(format, ...)
	if not self:GetFont() then
		if not self.fontObjectsToTry then
			error("No fonts applied to ShrinkUntilTruncateFontStringMixin, call SetFontObjectsToTry first");
		end
		self:SetFontObject(self.fontObjectsToTry[1]);
	end

	getmetatable(self).__index.SetFormattedText(self, format, ...);
	self:ApplyFontObjects();
end
