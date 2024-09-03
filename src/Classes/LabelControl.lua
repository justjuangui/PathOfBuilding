-- Path of Building
--
-- Class: Label Control
-- Simple text label.
--
local LabelClass = newClass("LabelControl", "Control", "TooltipHost", function(self, anchor, x, y, width, height, label)
	self.Control(anchor, x, y, width, height)
	self.TooltipHost()
	self.label = label
	self.width = function()
		return DrawStringWidth(self:GetProperty("height"), "VAR", self:GetProperty("label"))
	end
end)

function LabelClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	return self:IsMouseInBounds()
end

function LabelClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	DrawString(x, y, "LEFT", self:GetProperty("height"), "VAR", self:GetProperty("label"))

	local mOver = self:IsMouseOver()
	if mOver then
		if not noTooltip or self.forceTooltip then
			SetDrawLayer(nil, 100)
			self:DrawTooltip(x, y, width, height, viewPort)
			SetDrawLayer(nil, 0)
		end
	end
end