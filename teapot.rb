# Teapot v2.2.0 configuration generated at 2018-01-07 14:26:31 +1300

required_version "2.0"

# Project Metadata

define_project "kog" do |project|
	project.title = "Kog"
	project.license = 'MIT License'
	
	project.add_author 'Samuel Williams', email: 'samuel.williams@oriontransfer.co.nz'
	
	project.version = '0.1.0'
end

# Build Targets

define_target 'kog-library' do |target|
	target.build do
		source_root = target.package.path + 'source'
		copy headers: source_root.glob('Kog/**/*.{h,hpp}')
		
		cache_prefix = environment[:build_prefix] / environment.checksum
		parsers = source_root.glob('Kog/**/*Parser.rl')
		
		implementation_files = parsers.collect do |file|
			implementation_file = cache_prefix / (file.relative_path + '.cpp')
			convert source_file: file, destination_path: implementation_file
		end
		
		build static_library: 'Kog', source_files: source_root.glob('Kog/**/*.cpp') + implementation_files
	end
	
	target.depends 'Build/Files'
	target.depends 'Build/Clang'
	
	target.depends 'Convert/Ragel'
	
	target.depends :platform
	target.depends 'Language/C++14', private: true
	
	target.provides 'Library/Kog' do
		append linkflags [
			->{install_prefix + 'lib/libKog.a'},
		]
	end
end

define_target 'kog-test' do |target|
	target.build do |*arguments|
		test_root = target.package.path + 'test'
		
		run tests: 'Kog', source_files: test_root.glob('Kog/**/*.cpp'), arguments: arguments
	end
	
	target.depends 'Library/UnitTest'
	target.depends 'Library/Kog'
	
	target.depends 'Language/C++14', private: true
	
	target.provides 'Test/Kog'
end

define_target 'kog-executable' do |target|
	target.build do
		source_root = target.package.path + 'source'
		
		build executable: 'Kog', source_files: source_root.glob('Kog.cpp')
	end
	
	target.depends 'Build/Files'
	target.depends 'Build/Clang'
	
	target.depends :platform
	target.depends 'Language/C++14', private: true
	
	target.depends 'Library/Kog'
	target.provides 'Executable/Kog'
end

define_target 'kog-run' do |target|
	target.build do |*arguments|
		run executable: 'Kog', arguments: arguments
	end
	
	target.depends 'Executable/Kog'
	target.provides 'Run/Kog'
end

# Configurations

define_configuration 'development' do |configuration|
	configuration[:source] = "https://github.com/kurocha"
	configuration.import "kog"
	
	# Provides all the build related infrastructure:
	configuration.require 'platforms'
	
	# Provides unit testing infrastructure and generators:
	configuration.require 'unit-test'
	
	# Provides some useful C++ generators:
	configuration.require 'generate-cpp-class'
	
	configuration.require "generate-project"
end

define_configuration "kog" do |configuration|
	configuration.public!
	
	configuration.require "ragel"
end
