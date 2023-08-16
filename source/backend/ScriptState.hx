package backend;

import tea.SScript;

class ScriptState extends backend.MusicBeatState {
    var overridden:Bool = false;

    var script:SScript;
    var scriptName:String;
    var scriptParams:Array<Dynamic>;

    public function new(?scriptName:String, ?scriptParams:Array<Dynamic>) {
        super();

        this.scriptName = scriptName;
        this.scriptParams = scriptParams;

        if (scriptName == null) {
            var classPath = Type.getClassName(Type.getClass(this));
			this.scriptName = classPath.substr(classPath.lastIndexOf(".") + 1, classPath.length);
        }
    }

    override public function create() {
        tryScript();
        scriptCall("onCreate", scriptParams);

        if (!overridden)
            normCreate();

        scriptCall("onCreatePost");

        super.create(); //To put debug text on front.
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        scriptCall("onUpdate", [elapsed]);

        if (!overridden)
            normUpdate(elapsed);

        scriptCall("onUpdatePost", [elapsed]);
    }

    override public function stepHit() {
        super.stepHit();

        if (!overridden)
            normStepHit();

        scriptCall("onStepHit");
    }

    override public function beatHit() {
        super.beatHit();

        if (!overridden)
            normBeatHit();

        scriptCall("onBeatHit");
    }

    override public function sectionHit() {
        super.sectionHit();

        if (!overridden)
            normSectionHit();

        scriptCall("onSectionHit");
    }

    //SCRIPT STUFF

    function scriptGet(name:String) {
        return (script != null) ? script.get(name) : null;
    }

    function scriptSet(name:String, value:Dynamic) {
        if (script != null)
            script.set(name, value);
    }

    function scriptCall(name:String, ?params:Array<Dynamic>) {
        return (script != null) ? script.call(name, params) : null;
    }

    function cancelableCall(name:String, ?params:Array<Dynamic>):Bool {
        var returned = scriptCall(name, params);
        return (returned != null && returned.returnValue == psychlua.FunkinLua.Function_Stop);
    }

    function tryScript() {
        var scriptPath = Paths.getPath("states/" + scriptName + ".hx", TEXT, null, true);

        if (sys.FileSystem.exists(scriptPath)) {
            script = new SScript(scriptPath, true, false);

            script.set('FlxG', flixel.FlxG);
            script.set('FlxSprite', flixel.FlxSprite);
            script.set('FlxCamera', flixel.FlxCamera);
            script.set('FlxTimer', flixel.util.FlxTimer);
            script.set('FlxTween', flixel.tweens.FlxTween);
            script.set('FlxEase', flixel.tweens.FlxEase);
            script.set('FlxColor', psychlua.HScript.CustomFlxColor);
            script.set('PlayState', PlayState);
            script.set('Paths', Paths);
            script.set('Conductor', Conductor);
            script.set('ClientPrefs', ClientPrefs);
            script.set('Alphabet', Alphabet);
            script.set('CustomSubstate', psychlua.CustomSubstate);
            script.set('Countdown', backend.BaseStage.Countdown);
            #if (!flash && sys)
            script.set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
            #end
            script.set('ShaderFilter', openfl.filters.ShaderFilter);
            script.set('StringTools', StringTools);
    
            script.set('debugPrint', addTextToDebug);
    
            script.set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
                try {
                    var str:String = '';
                    if(libPackage.length > 0)
                        str = libPackage + '.';
    
                    script.set(libName, Type.resolveClass(str + libName));
                }
                catch (e:Dynamic) {
                    var msg:String = scriptName + " - " + e.message.substr(0, e.message.indexOf('\n'));
                    addTextToDebug(msg, FlxColor.RED);
                }
            });
            script.set('this', this);
            script.set('buildTarget', psychlua.FunkinLua.getBuildTarget());
            
            script.set('Function_Stop', psychlua.FunkinLua.Function_Stop);

            script.set('add', add);
            script.set('insert', insert);
            script.set('remove', remove);

            script.execute();
        }
    }




    //BASE FUNCTIONS

    public function normCreate() {}
    public function normUpdate(elapsed:Float) {}
    public function normStepHit() {}
    public function normBeatHit() {}
    public function normSectionHit() {}
}