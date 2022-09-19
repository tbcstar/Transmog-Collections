function HybridScrollFrameScrollUp_OnLoad (self)
	self:GetParent():GetParent().scrollUp = self;
	self:Disable();
	self:RegisterForClicks("LeftButtonUp", "LeftButtonDown");
	self.direction = 1;
end

function HybridScrollFrameScrollDown_OnLoad (self)
	self:GetParent():GetParent().scrollDown = self;
	self:Disable();
	self:RegisterForClicks("LeftButtonUp", "LeftButtonDown");
	self.direction = -1;
end
