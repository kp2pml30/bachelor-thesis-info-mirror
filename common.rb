require 'stringio'
def init(mode, interop, array)
	$mode = mode
	$interop = interop == 'true'
	$array = array == 'true'
	out = StringIO.new
	if mode == 'node'
	elsif mode == 'ark'
	else
		out << "const JavaSystem = #{findClassGlobal('java.lang.System')}\n"
		out << "const StartTime = JavaSystem.nanoTime()\n"
	end
	return out.string
end

def findClassGlobal(name)
	if $mode == 'ark'
		"Interop.findClass(\"#{name}\")"
	elsif $mode == 'nashorn'
		"Java.type(\"#{name}\")"
	elsif $mode == 'graal'
		"Java.type(\"#{name}\")"
	else
		'/* todo */ undefined'
	end
end

def findArray(name)
	return findClass('[]' + name) if $mode == 'ark'
	return findClass(name + '[]')
end

def findClass(name)
	if $mode == 'ark'
		"Interop.findClass(\"#{name}\")"
	elsif $mode == 'nashorn'
		"Java.type(\"Nashorn$#{name}\")"
	elsif $mode == 'graal'
		"Java.type(\"Graal$#{name}\")"
	else
		'/* todo */ undefined'
	end
end

$class = nil

def ARRAY(name, elems)
	count = elems.size
	return "Array(#{elems.join(',')})" if not $interop or not $array
	return "new #{name}Array(#{count}#{elems.map { |e| ", #{e}"}.join('')})" if $mode == 'ark'
	out = StringIO.new
	out << "(() => { const __c = new #{name}Array(#{count});"
	elems.each_with_index{ |e, i| out << "__c[#{i}] = #{e};" }
	out << "return __c;})()"
	return out.string
end

def CLASS_BEGIN(name)
	raise unless $class == nil
	$class = {'name' => name, 'funcs' => []}
	if $mode == 'nashorn'
		"function #{name}"
	else
		"class #{name} { constructor"
	end
end

def CLASS_METHOD(name)
	raise unless $class != nil
	$class['funcs'].push(name)
	if $mode == 'nashorn' then "function #{$class['name']}_#{name}" else "#{name}" end
end

def CLASS_END()
	raise unless $class != nil
	klass = $class
	$class = nil
	return '}' if $mode != 'nashorn'
	r = klass['funcs'].map { |n| "#{klass['name']}.prototype.#{n} = #{klass['name']}_#{n}" }.join(';')
	return r
end

def TIME
	return 'Interop.performanceNow()' if $mode == 'ark'
	return 'performance.now()' if $mode == 'node'
	return '(JavaSystem.nanoTime() - StartTime) / 1000000'
end
