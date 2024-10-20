var lights:Int = 5;
var lightShader:RuntimeShader;
var colorShader:RuntimeShader;
var trainSound:FlxSound;
var lightColors:Array =[
	0xffb66f43,
	0xff329a6d,
	0xff932c28,
	0xff2663ac,
	0xff502d64
];

var trainMoving:Bool = false;
var trainFinishing:Bool = false;
var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainCooldown:Int = 0;

function createPost() {
	Paths.sound('train_passes', 'week3');

	lightShader = new RuntimeShader('building');
	lightShader.setFloat('alphaShit', 0.0);

	colorShader = new RuntimeShader('adjustColor');
	colorShader.setFloat('hue', -26.0);
	colorShader.setFloat('saturation', -16.0);
	colorShader.setFloat('contrast', 0.0);
	colorShader.setFloat('brightness', -5.0);

	var light:Funkinsprite = getNamedProp('lights');
	light.shader = lightShader;
	light.visible = false;

	getNamedProp('train').shader = colorShader;
	state.player1.shader = colorShader;
	state.player2.shader = colorShader;
	state.player3.shader = colorShader;
}

function update(elapsed:Float, paused:Bool){
	if (paused) return;
	var shaderInput:Float = (Conductor.crochet / 1000) * elapsed * 1.5;
	lightShader.setFloat('alphaShit', lightShader.getFloat('alphaShit') + shaderInput);

	if (trainMoving)
	{
		trainFrameTiming += elapsed;

		if (trainFrameTiming >= 1 / 24)
		{
			updateTrainPos();
			trainFrameTiming = 0;
		}
	}
}

function beatHit(beat:Int){
	if (!trainMoving) trainCooldown += 1;

	if (beat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8){
		trainCooldown = FlxG.random.int(-4, 0);
		trainStart();
	}

	if (beat % 4 == 0){
		lightShader.setFloat('alphaShit', 0.0);

		curLight = FlxG.random.int(0, 4);
		getNamedProp('lights').color = lightColors[curLight];
	}
}

function trainStart(){
	trainMoving = true;
	FlxG.sound.play(Paths.sound('train_passes', 'week3'));
}

var startedMoving:Bool = false;

function updateTrainPos(){
	if (trainSound.time >= 4700){
		startedMoving = true;
		game.player3.playAnimation('hairBlow');
	}

	if (startedMoving){
		var train:FlxSprite = getNamedProp('train');
		train.x -= 400;

		if (train.x < -2000 && !trainFinishing)
		{
			train.x = -1150;
			trainCars -= 1;

			if (trainCars <= 0)
				trainFinishing = true;
		}

		if (train.x < -4000 && trainFinishing)
			trainReset();
	}
}

function trainReset(){
	game.player3.playAnimation('hairFall');
	getNamedProp('train').x = FlxG.width + 200;

	trainMoving = false;
	trainCars = 8;
	trainFinishing = false;
	startedMoving = false;
}

function getNamedProp(name:String){
	var prop = stage.getProp(name);
	return prop;
}