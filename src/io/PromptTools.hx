package io;

import tink.cli.Prompt;

class PromptTools {
	/** Print success line **/
	public static function printsln(p:Prompt, v:String):Promise<Noise> {
		return p.println('\033[32m$v\033[39m');
	}

	/** Print warning line **/
	public static function printwln(p:Prompt, v:String):Promise<Noise> {
		return p.println('\033[33m$v\033[39m');
	}

	/** Print error line **/
	public static function printeln(p:Prompt, v:String):Promise<Noise> {
		return p.println('\033[31m$v\033[39m');
	}
}