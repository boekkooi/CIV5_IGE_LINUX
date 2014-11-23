-- Released under GPL v3
--------------------------------------------------------------
print("IGE_ConfirmPopup");

local yesCallback = nil;

function IGEOnYes()
	ContextPtr:SetHide(true);
	UIManager:DequeuePopup(ContextPtr);
	yesCallback();
end
Controls.Yes:RegisterCallback(Mouse.eLClick, IGEOnYes);

function IGEOnNo()
	ContextPtr:SetHide(true);
	UIManager:DequeuePopup(ContextPtr);
end
Controls.No:RegisterCallback(Mouse.eLClick, IGEOnNo);

function IGEOnPopup(text, _yesCallback)
	yesCallback = _yesCallback;
	Controls.Message:SetText(text);
	UIManager:QueuePopup(ContextPtr, PopupPriority.eUtmost);
	ContextPtr:SetHide(false);
end
LuaEvents.IGE_ConfirmPopup.Add(IGEOnPopup);

function IGEOnInput(uiMsg, wParam, lParam)
	if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
			IGEOnNo();
            return true;
        end
    end
end
ContextPtr:SetInputHandler(IGEOnInput);

