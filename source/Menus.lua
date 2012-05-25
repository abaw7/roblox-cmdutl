AddMenu("Move",{
	Variables = {
		Increment = 1;
	};
	VariableList = {
		{"Increment","Move Increment"};
	};
	Color = Color3.new(0.854902, 0.521569, 0.254902);
})

AddMenu("Rotate",{
	Variables = {
		Increment = 45;
	};
	VariableList = {
		{"Increment","Rotation Increment"};
	};
	Color = Color3.new(0.643137, 0.741176, 0.278431);
})

AddMenu("Resize",{
	Variables = {
		Increment = 1;
	};
	VariableList = {
		{"Increment","Resize Increment"};
	};
	Color = Color3.new(0.0156863, 0.686275, 0.92549);
})

AddMenu("Clipboard",{
	Color = Color3.new(1,1,1);
})

AddMenu("SelectEdge",{
	Variables = {
		EdgeSnap = 0.5;
		RotIncrement = 45;
	};
	VariableList = {
		{"RotIncrement","Rotation Increment"};
		{"EdgeSnap","Edge Snap"};
	};
	Color = Color3.new(0.960784, 0.803922, 0.188235);
})
