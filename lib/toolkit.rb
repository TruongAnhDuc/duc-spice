def Object.subclasses_of(*superclasses)  
	subclasses = []
	ObjectSpace.each_object(Class) do |k|
		next if (k.ancestors & superclasses).empty? || superclasses.include?(k) || subclasses.include?(k)  
		subclasses << k
	end  
	subclasses
end

def Object.find_class(class_name)
	ObjectSpace.each_object(Class) { |k| k }.select { |k| k.to_s == class_name }.first
end