package compiler.cs;
import haxe.io.Output;
import haxe.Resource;
import haxe.Template;

using Lambda;

class CsProjWriter
{
	var stream:Output;
	public function new(stream:Output)
	{
		this.stream = stream;
	}

	public function write(compiler:CSharpCompiler):Void
	{
		var versionStr : String;
		var clientStr : String = compiler.version >= 45 ? "" : "Client";
		if (compiler.version == null)
			versionStr = "3.5";
		else if (compiler.version == 461)
			versionStr = "4.6.1";
		else
			versionStr = Std.string(compiler.version / 10);
		
		if (versionStr.indexOf(".") < 0)
			versionStr += ".0";
		
		var templateFile:String =
		switch(compiler.platform)
		{
			case "android":
				"android-csproj-template.mtt";
			case "desktop":
				"csproj-template.mtt";
			case _:
				"csproj-template.mtt";
		}
		
		var abiList:String = "";
		var first:Bool = true;
		for (abi in compiler.data.androidABIs)
		{
			if (first)
				first = false;
			else
				abiList += ", ";
			
			abiList += abi; 
		}
		
		var template = new Template( Resource.getString(templateFile) );
		stream.writeString(template.execute( {
			outputType : (compiler.dll ? "Library" : "Exe"),
			name : compiler.name,
			targetFramework : versionStr,
			client: clientStr,
			unsafe : compiler.unsafe,
			refs : compiler.libs,
			native_libs : compiler.data.nativeLibs,
			srcs : compiler.data.modules.map(function(m) return "src\\" + m.path.split(".").join("\\") + ".cs"),
			res : compiler.data.resources.map(function(res) return "src\\Resources\\" + haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(res))),
			android_abis : abiList,
			android_resources : compiler.data.androidResources,
			android_assets : compiler.data.androidAssets,
			guid: compiler.data.guid
		} ));
	}

}