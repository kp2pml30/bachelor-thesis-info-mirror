def findClass(mode, name)
	if mode == 'ark'
		return "Interop.findClass(\"L#{name};\")"
	elsif mode == 'nashorn'
		return "Java.type(\"Nashorn$#{name}\")"
	elsif mode == 'graal'
		return "Java.type(\"Graal$#{name}\")"
	end
	return '/* todo */ undefined'
end
